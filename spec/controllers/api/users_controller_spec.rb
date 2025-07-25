require 'rails_helper'

RSpec.describe Api::UsersController, type: :controller do
  let(:librarian) { create(:user, :librarian) }
  let(:member) { create(:user, :member) }

  before do
    # Mock Pundit authorization to allow by default for librarians
    allow(controller).to receive(:authorize).and_return(true)
    allow(controller).to receive(:policy_scope).and_return(User.all)
  end

  describe 'GET #index' do
    let!(:users) { create_list(:user, 3) }

    context 'when user is librarian' do
      before { sign_in librarian }

      it 'returns a success response' do
        get :index

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)

        expect(json_response).to have_key('users')
        expect(json_response).to have_key('pagination')
      end

      it 'returns all users' do
        get :index

        json_response = JSON.parse(response.body)
        expect(json_response['users']).to be_an(Array)
        expect(json_response['users'].length).to be >= 2 # librarian + member + created users
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

      it 'orders users by email' do
        get :index

        json_response = JSON.parse(response.body)
        emails = json_response['users'].map { |user| user['email'] }
        expect(emails).to eq(emails.sort)
      end

      it 'filters users by role when specified' do
        get :index, params: { role: 'librarian' }

        json_response = JSON.parse(response.body)
        roles = json_response['users'].map { |user| user['role'] }.uniq
        expect(roles).to eq([ 'librarian' ])
      end

      it 'searches users by email when search parameter is provided' do
        create(:user, email: 'searchme@example.com')
        get :index, params: { search: 'searchme' }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)

        expect(json_response['users'].any? { |u| u['email'] == 'searchme@example.com' }).to be true
      end
    end

    context 'when user is not authorized (member)' do
      before do
        sign_in member
        allow(controller).to receive(:authorize).and_raise(Pundit::NotAuthorizedError)
      end

      it 'returns forbidden status' do
        get :index

        expect(response).to have_http_status(:forbidden)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Access forbidden')
      end
    end

    context 'when user is not authenticated' do
      it 'requires authentication' do
        get :index

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET #show' do
    context 'when user is authenticated' do
      before { sign_in librarian }

      it 'returns success with detailed user info' do
        get :show, params: { id: member.id }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)

        expect(json_response).to have_key('user')
        expect(json_response['user']['id']).to eq(member.id)
        expect(json_response['user']['email']).to eq(member.email)
      end

      it 'includes all user fields' do
        get :show, params: { id: member.id }

        json_response = JSON.parse(response.body)
        user_data = json_response['user']

        expect(user_data).to have_key('id')
        expect(user_data).to have_key('email')
        expect(user_data).to have_key('role')
        expect(user_data).to have_key('librarian?')
        expect(user_data).to have_key('member?')
      end

      it 'works for librarian users' do
        get :show, params: { id: librarian.id }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)

        expect(json_response['user']['role']).to eq('librarian')
        expect(json_response['user']['librarian?']).to be true
      end

      it 'does not expose sensitive information' do
        get :show, params: { id: member.id }

        json_response = JSON.parse(response.body)
        user_data = json_response['user']

        expect(user_data).not_to have_key('encrypted_password')
        expect(user_data).not_to have_key('password')
        expect(user_data).not_to have_key('password_digest')
      end

      it 'returns 404 for non-existent user' do
        get :show, params: { id: 'nonexistent' }

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Resource not found')
      end
    end

    context 'when user is not authorized' do
      before do
        sign_in member
        # Allow access to own profile but not others
        allow(controller).to receive(:authorize) do |user|
          if user == member
            true
          else
            raise Pundit::NotAuthorizedError
          end
        end
      end

      it 'allows members to view their own profile' do
        get :show, params: { id: member.id }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['user']['id']).to eq(member.id)
      end

      it 'prevents members from viewing other users' do
        other_user = create(:user, :member)

        get :show, params: { id: other_user.id }

        expect(response).to have_http_status(:forbidden)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Access forbidden')
      end
    end

    context 'when user is not authenticated' do
      it 'requires authentication' do
        get :show, params: { id: member.id }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST #create' do
    let(:valid_attributes) do
      {
        email: 'test@example.com',
        password: 'password123',
        role: 'member'
      }
    end

    let(:invalid_attributes) do
      {
        email: 'invalid-email',
        password: '123',
        role: 'invalid_role'
      }
    end

    context 'when user is librarian' do
      before { sign_in librarian }

      it 'creates a new user' do
        expect {
          post :create, params: { user: valid_attributes }
        }.to change(User, :count).by(1)
      end

      it 'returns the created user' do
        post :create, params: { user: valid_attributes }

        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response['user']['email']).to eq('test@example.com')
      end

      context 'with invalid parameters' do
        it 'returns validation errors' do
          post :create, params: { user: invalid_attributes }

          expect(response).to have_http_status(:bad_request)
          json_response = JSON.parse(response.body)
          expect(json_response['error']).to eq('Missing required parameter')
        end
      end
    end
  end
end
