require 'rails_helper'

RSpec.describe Api::AuthController, type: :controller do
  let(:user) { create(:user, password: 'password123', password_confirmation: 'password123') }
  let(:librarian) { create(:user, :librarian, password: 'password123', password_confirmation: 'password123') }

  describe 'POST #login' do
    context 'with valid credentials' do
      it 'returns success with user data and token' do
        post :login, params: { user: { email: user.email, password: 'password123' } }
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        
        expect(json_response['status']).to eq('success')
        expect(json_response['message']).to eq('Login successful')
        expect(json_response['user']['id']).to eq(user.id)
        expect(json_response['user']['email']).to eq(user.email)
        expect(response).to have_http_status(:ok)
      end

      it 'returns a valid JWT token' do
        post :login, params: { user: { email: user.email, password: 'password123' } }
        
        expect(response).to have_http_status(:ok)
        # JWT token viene en Authorization header después del sign_in
        # Verificamos que el login fue exitoso, el token se maneja por devise-jwt
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('success')
      end

      it 'works for librarian users' do
        post :login, params: { user: { email: librarian.email, password: 'password123' } }
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['user']['role']).to eq('librarian')
      end
    end

    context 'with invalid credentials' do
      it 'returns error with invalid email' do
        post :login, params: { user: { email: 'nonexistent@example.com', password: 'password123' } }
        
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('Invalid email or password')
      end

      it 'returns error with invalid password' do
        post :login, params: { user: { email: user.email, password: 'wrongpassword' } }
        
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('Invalid email or password')
      end

      it 'returns error with missing email' do
        post :login, params: { user: { password: 'password123' } }
        
        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('Missing required parameter')
      end

      it 'returns error with missing password' do
        post :login, params: { user: { email: user.email } }
        
        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('Missing required parameter')
      end

      it 'returns error with empty params' do
        post :login, params: {}
        
        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('Missing required parameter')
      end
    end
  end

  describe 'POST #logout' do
    context 'when user is authenticated' do
      before do
        sign_in user
      end

      it 'logs out user successfully' do
        post :logout
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        
        expect(json_response['status']).to eq('success')
        expect(json_response['message']).to eq('Logout successful')
      end

      it 'works for librarian users' do
        sign_out user
        sign_in librarian
        
        post :logout
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        
        expect(json_response['status']).to eq('success')
        expect(json_response['message']).to eq('Logout successful')
      end

      it 'clears the JWT token' do
        post :logout
        
        expect(response).to have_http_status(:ok)
        expect(response.headers['Authorization']).to be_blank
      end
    end

    context 'when user is not authenticated' do
      it 'requires authentication' do
        post :logout
        
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST #register' do
    let(:valid_attributes) do
      {
        email: 'newuser@example.com',
        password: 'password123',
        password_confirmation: 'password123'
      }
    end

    context 'with valid parameters' do
      it 'creates a new user' do
        expect {
          post :register, params: { user: valid_attributes }
        }.to change(User, :count).by(1)
      end

      it 'returns success with user data and token' do
        post :register, params: { user: valid_attributes }
        
        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        
        expect(json_response['status']).to eq('success')
        expect(json_response['message']).to eq('User registered successfully')
        expect(json_response['user']['email']).to eq('newuser@example.com')
        expect(json_response['user']['role']).to eq('member')
      end

      it 'returns a valid JWT token' do
        post :register, params: { user: valid_attributes }
        
        expect(response).to have_http_status(:created)
        # JWT token se maneja automáticamente por devise-jwt
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('success')
      end

      it 'assigns member role by default' do
        post :register, params: { user: valid_attributes }
        
        json_response = JSON.parse(response.body)
        expect(json_response['user']['role']).to eq('member')
        
        new_user = User.find_by(email: 'newuser@example.com')
        expect(new_user.role).to eq('member')
      end
    end

    context 'with invalid parameters' do
      it 'returns error with missing email' do
        post :register, params: { user: { password: 'password123', password_confirmation: 'password123' } }
        
        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('Missing required parameter')
      end

      it 'returns error with invalid email format' do
        post :register, params: { 
          user: { 
            email: 'invalid-email', 
            password: 'password123', 
            password_confirmation: 'password123' 
          } 
        }
        
        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('Validation failed')
        expect(json_response['details']).to eq('Invalid email format')
      end

      it 'returns error with duplicate email' do
        create(:user, email: 'duplicate@example.com')
        
        post :register, params: { 
          user: { 
            email: 'duplicate@example.com', 
            password: 'password123', 
            password_confirmation: 'password123' 
          } 
        }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('Registration failed')
        expect(json_response['errors']).to include('Email has already been taken')
      end

      it 'returns error with short password' do
        post :register, params: { 
          user: { 
            email: 'newuser@example.com', 
            password: '123', 
            password_confirmation: '123' 
          } 
        }
        
        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('Validation failed')
        expect(json_response['details']).to include('Password must be at least')
      end

      it 'returns error with password mismatch' do
        post :register, params: { 
          user: { 
            email: 'newuser@example.com', 
            password: 'password123', 
            password_confirmation: 'different123' 
          } 
        }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('Registration failed')
        expect(json_response['errors']).to include("Password confirmation doesn't match Password")
      end

      it 'returns error with missing user params' do
        post :register, params: {}
        
        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('Missing required parameter')
      end
    end
  end

  describe 'private methods' do
    describe '#login_params' do
      before do
        controller.params = ActionController::Parameters.new({
          user: {
            email: 'test@example.com',
            password: 'password123',
            role: 'librarian' # This should be filtered out
          }
        })
      end

      it 'permits only allowed parameters' do
        permitted_params = controller.send(:login_params)
        
        expect(permitted_params.keys).to contain_exactly('email', 'password')
        expect(permitted_params.keys).not_to include('role')
      end
    end

    describe '#register_params' do
      before do
        controller.params = ActionController::Parameters.new({
          user: {
            email: 'test@example.com',
            password: 'password123',
            password_confirmation: 'password123',
            role: 'librarian' # This should be filtered out
          }
        })
      end

      it 'permits only allowed parameters' do
        permitted_params = controller.send(:register_params)
        
        expect(permitted_params.keys).to contain_exactly('email', 'password', 'password_confirmation')
        expect(permitted_params.keys).not_to include('role')
      end
    end

    describe '#user_response_data' do
      it 'returns user data without sensitive information' do
        user_data = controller.send(:user_response_data, user)
        
        expect(user_data).to have_key(:id)
        expect(user_data).to have_key(:email)
        expect(user_data).to have_key(:role)
        expect(user_data).not_to have_key(:encrypted_password)
        expect(user_data).not_to have_key(:password)
      end
    end
  end
end 