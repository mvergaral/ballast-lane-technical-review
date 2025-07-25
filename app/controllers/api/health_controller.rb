class Api::HealthController < Api::ApplicationController
  # Health check endpoint should be public
  skip_before_action :authenticate_user!
  
  def index
    render json: {
      status: 'ok',
      message: 'Rails API is running successfully!',
      timestamp: Time.current.iso8601,
      version: '1.0.0'
    }
  rescue => error
    Rails.logger.error "Health check error: #{error.class} - #{error.message}"
    
    render json: {
      status: 'error',
      message: 'Health check failed',
      timestamp: Time.current.iso8601
    }, status: :internal_server_error
  end
end
