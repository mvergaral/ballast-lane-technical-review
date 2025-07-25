require 'rails_helper'

RSpec.describe Api::HealthController, type: :controller do
  describe 'GET #index' do
    it 'returns health check information' do
      get :index
      
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      
      expect(json_response['status']).to eq('ok')
      expect(json_response['message']).to eq('Rails API is running successfully!')
      expect(json_response['version']).to eq('1.0.0')
      expect(json_response['timestamp']).to be_present
    end

    it 'returns current timestamp' do
      freeze_time = Time.current
      allow(Time).to receive(:current).and_return(freeze_time)
      
      get :index
      
      json_response = JSON.parse(response.body)
      returned_time = Time.parse(json_response['timestamp'])
      
      expect(returned_time).to be_within(1.second).of(freeze_time)
    end

    it 'returns JSON content type' do
      get :index
      
      expect(response.content_type).to include('application/json')
    end

    it 'does not require authentication' do
      # No authentication setup - should still work
      get :index
      
      expect(response).to have_http_status(:ok)
    end

    it 'always returns the same version' do
      get :index
      json_response1 = JSON.parse(response.body)
      
      get :index
      json_response2 = JSON.parse(response.body)
      
      expect(json_response1['version']).to eq(json_response2['version'])
      expect(json_response1['status']).to eq(json_response2['status'])
      expect(json_response1['message']).to eq(json_response2['message'])
    end

    it 'includes all required fields' do
      get :index
      
      json_response = JSON.parse(response.body)
      
      expect(json_response).to have_key('status')
      expect(json_response).to have_key('message')
      expect(json_response).to have_key('timestamp')
      expect(json_response).to have_key('version')
    end

    it 'responds quickly' do
      start_time = Time.current
      get :index
      end_time = Time.current
      
      expect(end_time - start_time).to be < 1.second
      expect(response).to have_http_status(:ok)
    end
  end
end 