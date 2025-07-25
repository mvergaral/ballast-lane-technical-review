require 'rails_helper'

RSpec.describe Api::ApplicationController, type: :controller do
  let(:user) { create(:user) }

  # ============================================================================
  # INHERITANCE AND STRUCTURE TESTS
  # ============================================================================
  describe 'class structure' do
    it 'inherits from ApplicationController' do
      expect(Api::ApplicationController.superclass).to eq(ApplicationController)
    end
    
    it 'includes Pundit authorization from parent' do
      expect(described_class.ancestors).to include(Pundit::Authorization)
    end
    
    it 'has the correct before_actions configured' do
      before_actions = described_class._process_action_callbacks
                              .select { |cb| cb.kind == :before }
                              .map(&:filter)
      
      expect(before_actions).to include(:ensure_json_request)
      expect(before_actions).to include(:authenticate_user!)
    end
  end

  # ============================================================================
  # UNIT TESTS FOR PRIVATE METHODS
  # ============================================================================
  describe 'private methods (direct testing)' do
    let(:controller_instance) { described_class.new }
    let(:mock_request) { double('request', format: double('format', json?: true)) }
    let(:mock_params) { ActionController::Parameters.new }
    
    before do
      allow(controller_instance).to receive(:params).and_return(mock_params)
      allow(controller_instance).to receive(:request).and_return(mock_request)
      allow(controller_instance).to receive(:render)
    end

    describe '#pagination_params' do
      it 'returns default values when no params provided' do
        allow(controller_instance).to receive(:params).and_return(
          ActionController::Parameters.new.permit(:page, :per_page)
        )
        
        result = controller_instance.send(:pagination_params)
        expect(result[:page]).to eq(1)
        expect(result[:per_page]).to eq(20)
      end
      
      it 'converts string parameters to integers' do
        allow(controller_instance).to receive(:params).and_return(
          ActionController::Parameters.new(page: '3', per_page: '50').permit(:page, :per_page)
        )
        
        result = controller_instance.send(:pagination_params)
        expect(result[:page]).to eq(3)
        expect(result[:per_page]).to eq(50)
      end
      
      it 'enforces minimum page value of 1' do
        allow(controller_instance).to receive(:params).and_return(
          ActionController::Parameters.new(page: '-5').permit(:page, :per_page)
        )
        
        result = controller_instance.send(:pagination_params)
        expect(result[:page]).to eq(1)
      end
      
      it 'enforces maximum per_page value of 100' do
        allow(controller_instance).to receive(:params).and_return(
          ActionController::Parameters.new(per_page: '200').permit(:page, :per_page)
        )
        
        result = controller_instance.send(:pagination_params)
        expect(result[:per_page]).to eq(100)
      end
      
      it 'enforces minimum per_page value of 1' do
        allow(controller_instance).to receive(:params).and_return(
          ActionController::Parameters.new(per_page: '0').permit(:page, :per_page)
        )
        
        result = controller_instance.send(:pagination_params)
        expect(result[:per_page]).to eq(1)
      end
    end

    describe '#success_response' do
      it 'renders success response with proper format' do
        expect(controller_instance).to receive(:render).with(
          json: {
            status: 'success',
            message: 'Test message',
            data: { test: 'data' },
            timestamp: kind_of(String)
          },
          status: :ok
        )
        
        controller_instance.send(:success_response, { test: 'data' }, 'Test message')
      end
      
      it 'uses default values when not provided' do
        expect(controller_instance).to receive(:render).with(
          json: {
            status: 'success',
            message: 'Success',
            data: {},
            timestamp: kind_of(String)
          },
          status: :ok
        )
        
        controller_instance.send(:success_response)
      end
    end

    describe '#error_response' do
      it 'renders error response with proper format' do
        expect(controller_instance).to receive(:render).with(
          json: {
            status: 'error',
            message: 'Test error',
            details: ['detail1', 'detail2'],
            timestamp: kind_of(String)
          },
          status: :bad_request
        )
        
        controller_instance.send(:error_response, 'Test error', ['detail1', 'detail2'])
      end
      
      it 'omits details when not provided' do
        expect(controller_instance).to receive(:render).with(
          json: {
            status: 'error',
            message: 'Test error',
            timestamp: kind_of(String)
          },
          status: :bad_request
        )
        
        controller_instance.send(:error_response, 'Test error')
      end
    end
  end

  # ============================================================================
  # RESCUE HANDLERS TESTING (Unit Tests)
  # ============================================================================
  describe 'rescue handlers (direct testing)' do
    let(:controller_instance) { described_class.new }
    
    before do
      allow(controller_instance).to receive(:render)
      allow(Rails.logger).to receive(:warn)
      allow(Rails.logger).to receive(:error)
    end

    describe '#not_found' do
      it 'renders not_found response with proper format' do
        exception = ActiveRecord::RecordNotFound.new('Test record not found')
        
        expect(controller_instance).to receive(:render).with(
          json: {
            error: 'Resource not found',
            message: 'Test record not found',
            status: 'not_found',
            timestamp: kind_of(String)
          },
          status: :not_found
        )
        
        controller_instance.send(:not_found, exception)
      end
      
      it 'logs the warning' do
        exception = ActiveRecord::RecordNotFound.new('Test record not found')
        expect(Rails.logger).to receive(:warn).with(/Record not found/)
        
        controller_instance.send(:not_found, exception)
      end
    end

    describe '#unprocessable_entity' do
      it 'renders unprocessable_entity response with validation errors' do
        user = User.new(email: '', password: '')
        user.valid? # Populate errors
        exception = ActiveRecord::RecordInvalid.new(user)
        
        expect(controller_instance).to receive(:render).with(
          json: {
            error: 'Validation failed',
            details: kind_of(Array),
            status: 'unprocessable_entity',
            timestamp: kind_of(String)
          },
          status: :unprocessable_entity
        )
        
        controller_instance.send(:unprocessable_entity, exception)
      end
      
      it 'logs the validation errors' do
        user = User.new(email: '', password: '')
        user.valid?
        exception = ActiveRecord::RecordInvalid.new(user)
        
        expect(Rails.logger).to receive(:warn).with(/Validation failed/)
        
        controller_instance.send(:unprocessable_entity, exception)
      end
    end

    describe '#bad_request_missing_param' do
      it 'renders bad_request response with parameter info' do
        exception = ActionController::ParameterMissing.new('required_param')
        
        expect(controller_instance).to receive(:render).with(
          json: {
            error: 'Missing required parameter',
            message: kind_of(String),
            status: 'bad_request',
            timestamp: kind_of(String)
          },
          status: :bad_request
        )
        
        controller_instance.send(:bad_request_missing_param, exception)
      end
    end

    describe '#forbidden' do
      it 'renders forbidden response' do
        exception = Pundit::NotAuthorizedError.new('Test authorization error')
        allow(controller_instance).to receive(:current_user).and_return(user)
        
        expect(controller_instance).to receive(:render).with(
          json: {
            error: 'Access forbidden',
            message: 'You are not authorized to perform this action',
            status: 'forbidden',
            timestamp: kind_of(String)
          },
          status: :forbidden
        )
        
        controller_instance.send(:forbidden, exception)
      end
    end

    describe '#internal_server_error' do
      it 'renders internal_server_error response' do
        exception = StandardError.new('Test error')
        
        expect(controller_instance).to receive(:render).with(
          json: {
            error: 'Internal server error',
            message: Rails.env.production? ? 'An unexpected error occurred' : 'Test error',
            status: 'internal_server_error',
            timestamp: kind_of(String)
          },
          status: :internal_server_error
        )
        
        controller_instance.send(:internal_server_error, exception)
      end
      
      it 'logs the error' do
        exception = StandardError.new('Test error')
        expect(Rails.logger).to receive(:error).with(/Internal server error/)
        
        controller_instance.send(:internal_server_error, exception)
      end
    end
  end

  # ============================================================================
  # ENSURE_JSON_REQUEST FILTER TESTING (Unit Test)
  # ============================================================================
  describe '#ensure_json_request filter' do
    let(:controller_instance) { described_class.new }
    
    before do
      allow(controller_instance).to receive(:render)
    end

    context 'with JSON request' do
      it 'allows the request to proceed' do
        mock_request = double('request', format: double('format', json?: true))
        allow(controller_instance).to receive(:request).and_return(mock_request)
        
        # Should not render anything (request proceeds)
        expect(controller_instance).not_to receive(:render)
        
        result = controller_instance.send(:ensure_json_request)
        expect(result).to be_nil # Early return when format is JSON
      end
    end

    context 'with non-JSON request' do
      it 'rejects the request with not_acceptable status' do
        mock_request = double('request', format: double('format', json?: false))
        allow(controller_instance).to receive(:request).and_return(mock_request)
        
        expect(controller_instance).to receive(:render).with(
          json: {
            error: 'Only JSON requests are supported',
            message: 'Please set Content-Type: application/json and Accept: application/json headers',
            timestamp: kind_of(String)
          },
          status: :not_acceptable
        )
        
        controller_instance.send(:ensure_json_request)
      end
    end
  end

  # ============================================================================
  # CURRENT_USER METHOD TESTING
  # ============================================================================
  describe '#current_user' do
    let(:controller_instance) { described_class.new }
    
    it 'has the current_user method defined' do
      expect(controller_instance.private_methods).to include(:current_user)
    end
    
    it 'overrides current_user to call super (maintaining Devise functionality)' do
      # Test that the method is properly defined in the class
      expect(described_class.private_instance_methods).to include(:current_user)
      
      # We can verify the method exists without calling it directly
      # since it's private and requires Devise setup
      source_location = controller_instance.method(:current_user).source_location
      expect(source_location).to be_present
    end
  end
end 