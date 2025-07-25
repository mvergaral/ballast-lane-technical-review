require 'rails_helper'

RSpec.describe Api::BorrowingsController, type: :controller do
  let(:librarian) { create(:user, :librarian) }
  let(:member) { create(:user, :member) }
  let(:book) { create(:book) }
  let(:borrowing) { create(:borrowing, user: member, book: book) }

  before do
    sign_in librarian # Default to librarian for most tests
    # Mock Pundit authorization to allow by default
    allow(controller).to receive(:authorize).and_return(true)
    allow(controller).to receive(:policy_scope).and_return(Borrowing.all)
  end

  describe 'GET #index' do
    let!(:borrowings) { create_list(:borrowing, 3, user: member) }

    it 'returns a list of borrowings' do
      get :index
      
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      
      expect(json_response).to have_key('borrowings')
      expect(json_response).to have_key('pagination')
      expect(json_response['borrowings']).to be_an(Array)
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

    it 'orders borrowings by created_at desc' do
      get :index
      
      json_response = JSON.parse(response.body)
      created_ats = json_response['borrowings'].map { |b| b['created_at'] }
      expect(created_ats).to eq(created_ats.sort.reverse)
    end

    it 'includes user and book information' do
      get :index
      
      json_response = JSON.parse(response.body)
      first_borrowing = json_response['borrowings'].first
      
      expect(first_borrowing).to have_key('user')
      expect(first_borrowing).to have_key('book')
      expect(first_borrowing['user']).to have_key('email')
      expect(first_borrowing['book']).to have_key('title')
    end
  end

  describe 'GET #show' do
    it 'returns the requested borrowing' do
      get :show, params: { id: borrowing.id }
      
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      
      expect(json_response['id']).to eq(borrowing.id)
      expect(json_response['user']['id']).to eq(member.id)
      expect(json_response['book']['id']).to eq(book.id)
    end

    it 'returns 404 for non-existent borrowing' do
      get :show, params: { id: 'nonexistent' }
      
      expect(response).to have_http_status(:not_found)
      json_response = JSON.parse(response.body)
      expect(json_response['error']).to eq('Resource not found')
    end

    it 'includes detailed book information' do
      get :show, params: { id: borrowing.id }
      
      json_response = JSON.parse(response.body)
      book_info = json_response['book']
      
      expect(book_info['title']).to be_present
      expect(book_info['author']).to be_present
      expect(book_info['total_copies']).to be_present
      expect(book_info['available_copies']).to be_present
    end
  end

  describe 'POST #create' do
    before { sign_in member } # Members can create borrowings

    context 'with valid parameters' do
      let(:valid_attributes) { { book_id: book.id } }

      it 'creates a new borrowing' do
        expect {
          post :create, params: { borrowing: valid_attributes }
        }.to change(Borrowing, :count).by(1)
      end

      it 'returns the created borrowing' do
        post :create, params: { borrowing: valid_attributes }
        
        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response['book']['id']).to eq(book.id)
      end

      it 'sets the current user as the borrower' do
        post :create, params: { borrowing: valid_attributes }
        
        created_borrowing = Borrowing.last
        expect(created_borrowing.user).to eq(member)
      end

      it 'sets a default due date' do
        post :create, params: { borrowing: valid_attributes }
        
        created_borrowing = Borrowing.last
        expect(created_borrowing.due_date).to be_present
      end
    end

    context 'with custom due date' do
      let(:custom_due_date) { 1.month.from_now }
      let(:valid_attributes) { { book_id: book.id, due_date: custom_due_date } }

      it 'respects the custom due date' do
        post :create, params: { borrowing: valid_attributes }
        
        created_borrowing = Borrowing.last
        expect(created_borrowing.due_date).to be_within(1.second).of(custom_due_date)
      end
    end

    context 'when user is not authorized' do
      before do
        allow(controller).to receive(:authorize).and_raise(Pundit::NotAuthorizedError)
      end

      it 'returns forbidden status' do
        post :create, params: { borrowing: { book_id: book.id } }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'PUT #update' do
    context 'with valid parameters' do
      let(:new_due_date) { 1.month.from_now.beginning_of_day }
      let(:new_attributes) { { due_date: new_due_date } }

      it 'updates the requested borrowing' do
        put :update, params: { id: borrowing.id, borrowing: new_attributes }
        borrowing.reload
        expect(borrowing.due_date.to_date).to eq(new_due_date.to_date)
      end

      it 'returns the updated borrowing' do
        put :update, params: { id: borrowing.id, borrowing: new_attributes }
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['id']).to eq(borrowing.id)
      end
    end

    context 'with invalid parameters' do
      it 'returns validation errors' do
        put :update, params: { id: borrowing.id, borrowing: { due_date: nil } }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Validation failed')
      end
    end

    context 'when user is not authorized' do
      before do
        allow(controller).to receive(:authorize).and_raise(Pundit::NotAuthorizedError)
      end

      it 'returns forbidden status' do
        put :update, params: { id: borrowing.id, borrowing: { due_date: 1.month.from_now } }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'when user is authorized' do
      let!(:borrowing_to_delete) { create(:borrowing, user: member, book: book) }

      it 'destroys the requested borrowing' do
        expect {
          delete :destroy, params: { id: borrowing_to_delete.id }
        }.to change(Borrowing, :count).by(-1)
      end

      it 'returns success message' do
        delete :destroy, params: { id: borrowing_to_delete.id }
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('Borrowing deleted successfully')
      end
    end

    context 'when user is not authorized' do
      before do
        allow(controller).to receive(:authorize).and_raise(Pundit::NotAuthorizedError)
      end

      it 'returns forbidden status' do
        delete :destroy, params: { id: borrowing.id }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when borrowing can be deleted' do
      let!(:borrowing_with_returns) { create(:borrowing, user: member, book: book, returned_at: 1.day.ago) }

      it 'deletes borrowing successfully' do
        expect {
          delete :destroy, params: { id: borrowing_with_returns.id }
        }.to change(Borrowing, :count).by(-1)
      end
    end
  end

  describe 'POST #return_book' do
    let!(:active_borrowing) { create(:borrowing, user: member, book: book, returned_at: nil) }

    context 'when user is authorized' do
      it 'returns the book successfully' do
        post :return_book, params: { id: active_borrowing.id }
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('Book returned successfully')
      end

      it 'updates the borrowing returned_at timestamp' do
        expect {
          post :return_book, params: { id: active_borrowing.id }
        }.to change { active_borrowing.reload.returned_at }.from(nil)
      end

      it 'includes book information in response' do
        post :return_book, params: { id: active_borrowing.id }
        
        json_response = JSON.parse(response.body)
        expect(json_response['borrowing']['book']).to be_present
      end
    end

    context 'when book is already returned' do
      let!(:returned_borrowing) do
        borrowing = create(:borrowing, user: member, book: create(:book), returned_at: nil)
        borrowing.update!(returned_at: 1.day.ago)
        borrowing
      end

      it 'returns error message' do
        post :return_book, params: { id: returned_borrowing.id }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Cannot return book')
      end
    end

    context 'when user is not authorized' do
      before do
        allow(controller).to receive(:authorize).and_raise(Pundit::NotAuthorizedError)
      end

      it 'returns forbidden status' do
        post :return_book, params: { id: active_borrowing.id }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'private methods' do
    describe '#set_borrowing' do
      it 'sets the borrowing instance variable' do
        allow(Borrowing).to receive(:find).with(borrowing.id.to_s).and_return(borrowing)
        allow(controller).to receive(:authorize).with(borrowing).and_return(true)
        controller.params = ActionController::Parameters.new({ id: borrowing.id.to_s })
        controller.send(:set_borrowing)
        expect(assigns(:borrowing)).to eq(borrowing)
      end
    end

    describe '#borrowing_params' do
      context 'for create action' do
        before do
          controller.params = ActionController::Parameters.new({
            borrowing: {
              book_id: book.id,
              due_date: 1.week.from_now,
              unauthorized_param: 'should be filtered'
            }
          })
          allow(controller).to receive(:action_name).and_return('create')
        end

        it 'permits the correct parameters' do
          permitted_params = controller.send(:borrowing_params)
          
          expect(permitted_params['book_id']).to eq(book.id)
          expect(permitted_params.keys).not_to include('unauthorized_param')
        end
      end
    end
  end
end 