require 'rails_helper'

RSpec.describe Api::BooksController, type: :controller do
  let(:librarian) { create(:user, :librarian) }
  let(:member) { create(:user, :member) }
  let(:book) { create(:book) }

  let(:valid_attributes) do
    {
      title: 'Test Book',
      author: 'Test Author',
      genre: 'Test Genre',
      isbn: '1234567890123',
      total_copies: 5,
      available_copies: 5
    }
  end

  let(:invalid_attributes) do
    {
      title: '',
      author: '',
      genre: '',
      isbn: 'invalid',
      total_copies: -1,
      available_copies: -1
    }
  end

  before do
    sign_in librarian # Default to librarian for most tests
    # Mock Pundit authorization to allow by default
    allow(controller).to receive(:authorize).and_return(true)
    allow(controller).to receive(:policy_scope).and_return(Book.all)
  end

  describe 'GET #index' do
    before do
      create_list(:book, 3)
    end

    it 'returns a list of books' do
      get :index
      
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      
      expect(json_response).to have_key('books')
      expect(json_response).to have_key('pagination')
      expect(json_response['books']).to be_an(Array)
    end

    it 'includes pagination information' do
      get :index
      
      json_response = JSON.parse(response.body)
      expect(json_response['pagination']['current_page']).to eq(1)
      expect(json_response['pagination']).to have_key('total_pages')
      expect(json_response['pagination']).to have_key('total_count')
    end

    it 'respects per_page parameter' do
      get :index, params: { per_page: 2 }
      
      json_response = JSON.parse(response.body)
      expect(json_response['pagination']['per_page']).to eq(2)
    end

    it 'orders books by title' do
      get :index
      
      json_response = JSON.parse(response.body)
      titles = json_response['books'].map { |book| book['title'] }
      expect(titles).to eq(titles.sort)
    end
  end

  describe 'GET #show' do
    it 'returns the requested book' do
      get :show, params: { id: book.id }
      
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      
      expect(json_response['id']).to eq(book.id)
      expect(json_response['title']).to eq(book.title)
    end

    it 'returns 404 for non-existent book' do
      get :show, params: { id: 'nonexistent' }
      
      expect(response).to have_http_status(:not_found)
      json_response = JSON.parse(response.body)
      expect(json_response['error']).to eq('Resource not found')
    end
  end

  describe 'POST #create' do
    context 'with valid parameters' do
      it 'creates a new book' do
        expect {
          post :create, params: { book: valid_attributes }
        }.to change(Book, :count).by(1)
      end

      it 'returns the created book' do
        post :create, params: { book: valid_attributes }
        
        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response['title']).to eq('Test Book')
      end
    end

    context 'with invalid parameters' do
      it 'does not create a new book' do
        expect {
          post :create, params: { book: invalid_attributes }
        }.to change(Book, :count).by(0)
      end

      it 'returns validation errors' do
        post :create, params: { book: invalid_attributes }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Cannot create book')
      end
    end

    context 'when user is not authorized' do
      before do
        allow(controller).to receive(:authorize).and_raise(Pundit::NotAuthorizedError)
      end

      it 'returns forbidden status' do
        post :create, params: { book: valid_attributes }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'PUT #update' do
    context 'with valid parameters' do
      let(:new_attributes) { { title: 'Updated Title' } }

      it 'updates the requested book' do
        put :update, params: { id: book.id, book: new_attributes }
        book.reload
        expect(book.title).to eq('Updated Title')
      end

      it 'returns the updated book' do
        put :update, params: { id: book.id, book: new_attributes }
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['title']).to eq('Updated Title')
      end
    end

    context 'with invalid parameters' do
      it 'returns validation errors' do
        put :update, params: { id: book.id, book: invalid_attributes }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Cannot update book')
      end
    end

    context 'when user is not authorized' do
      before do
        allow(controller).to receive(:authorize).and_raise(Pundit::NotAuthorizedError)
      end

      it 'returns forbidden status' do
        put :update, params: { id: book.id, book: { title: 'New Title' } }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:book_to_delete) { create(:book) }

    context 'when user is authorized' do
      it 'destroys the requested book' do
        expect {
          delete :destroy, params: { id: book_to_delete.id }
        }.to change(Book, :count).by(-1)
      end

      it 'returns success message' do
        delete :destroy, params: { id: book_to_delete.id }
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('Book deleted successfully')
      end
    end

    context 'when user is not authorized' do
      before do
        allow(controller).to receive(:authorize).and_raise(Pundit::NotAuthorizedError)
      end

      it 'returns forbidden status' do
        delete :destroy, params: { id: book_to_delete.id }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when book has active borrowings' do
      let!(:book_with_borrowings) do
        book = create(:book)
        create(:borrowing, book: book, returned_at: nil)
        book
      end

      it 'returns conflict status' do
        delete :destroy, params: { id: book_with_borrowings.id }
        
        expect(response).to have_http_status(:conflict)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Cannot delete book')
      end
    end
  end

  describe 'GET #search' do
    before do
      create(:book, title: 'Programming Ruby', author: 'Dave Thomas')
      create(:book, title: 'Ruby on Rails', author: 'DHH')
      create(:book, title: 'JavaScript Guide', author: 'Mozilla')
    end

    context 'with valid query' do
      it 'returns matching books' do
        get :search, params: { q: 'Programming' }
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('books')
        expect(json_response).to have_key('pagination')
      end

      it 'includes search information' do
        get :search, params: { q: 'Programming' }
        
        json_response = JSON.parse(response.body)
        expect(json_response['query']).to eq('Programming')
      end

      it 'respects pagination parameters' do
        get :search, params: { q: 'Ruby', per_page: 5 }
        
        json_response = JSON.parse(response.body)
        expect(json_response['pagination']['per_page']).to eq(5)
      end
    end

    context 'with blank query' do
      it 'returns bad request' do
        get :search, params: { q: '' }
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe 'GET #search_suggestions' do
    before do
      create(:book, title: 'Programming Ruby', author: 'Dave Thomas')
      create(:book, title: 'Programming Elixir', author: 'Dave Thomas')
    end

    context 'with valid query' do
      it 'returns suggestions' do
        get :search_suggestions, params: { q: 'Programming' }
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('suggestions')
        expect(json_response['suggestions']).to be_an(Array)
      end

      it 'respects limit parameter' do
        get :search_suggestions, params: { q: 'Programming', limit: 1 }
        
        json_response = JSON.parse(response.body)
        expect(json_response['suggestions'].length).to be <= 1
      end
    end

    context 'with blank query' do
      it 'returns empty suggestions' do
        get :search_suggestions, params: { q: '' }
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe 'GET #advanced_search' do
    before do
      create(:book, title: 'Ruby Programming', author: 'Test', genre: 'Programming', available_copies: 1)
      create(:book, title: 'JavaScript Guide', author: 'Test', genre: 'Programming', available_copies: 0)
    end

    it 'returns filtered books' do
      get :advanced_search, params: { author: 'Test', genre: 'Programming', available_only: 'true' }
      
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response).to have_key('books')
      expect(json_response).to have_key('filters')
    end

    it 'includes filter information' do
      get :advanced_search, params: { author: 'Test', genre: 'Programming', available_only: 'true' }
      
      json_response = JSON.parse(response.body)
      filters = json_response['filters']
      expect(filters['author']).to eq('Test')
      expect(filters['genre']).to eq('Programming')
      expect(filters['available_only']).to eq('true')
    end

    it 'handles blank query' do
      get :advanced_search, params: {}
      
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response).to have_key('books')
    end
  end

  describe 'private methods' do
    describe '#set_book' do
      it 'sets the book instance variable' do
        allow(Book).to receive(:find).with(book.id.to_s).and_return(book)
        allow(controller).to receive(:authorize).with(book).and_return(true)
        controller.params = ActionController::Parameters.new({ id: book.id.to_s })
        controller.send(:set_book)
        expect(assigns(:book)).to eq(book)
      end
    end

    describe '#book_params' do
      before do
        controller.params = ActionController::Parameters.new({
          book: {
            title: 'Test Book',
            author: 'Test Author',
            genre: 'Test Genre',
            isbn: '1234567890123',
            total_copies: 3,
            unauthorized_param: 'should be filtered'
          }
        })
      end

      it 'permits the correct parameters' do
        permitted_params = controller.send(:book_params)
        
        expect(permitted_params.keys).to contain_exactly(
          'title', 'author', 'genre', 'isbn', 'total_copies'
        )
        expect(permitted_params.keys).not_to include('unauthorized_param')
        expect(permitted_params['total_copies']).to eq(3)
      end
    end
  end
end 