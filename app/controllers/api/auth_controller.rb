class Api::AuthController < ApplicationController
  before_action :authenticate_user!, only: [:logout]
  skip_before_action :authenticate_user!, only: [:login, :register]

  # Custom validation error class
  class ValidationError < StandardError; end

  def login
    begin
      # Validate required parameters
      validate_login_params!
      
      user = User.find_by(email: login_params[:email])
      
      if user&.valid_password?(login_params[:password])
        # Sign in the user for JWT authentication
        sign_in(user)
        
        render json: {
          status: 'success',
          message: 'Login successful',
          user: user_response_data(user),
          timestamp: Time.current.iso8601
        }, status: :ok
      else
        Rails.logger.warn "Failed login attempt for email: #{login_params[:email]}"
        
        render json: {
          status: 'error',
          message: 'Invalid email or password',
          timestamp: Time.current.iso8601
        }, status: :unauthorized
      end
    rescue ValidationError => e
      render json: {
        status: 'error',
        message: 'Validation failed',
        details: e.message,
        timestamp: Time.current.iso8601
      }, status: :bad_request
    rescue ActionController::ParameterMissing => e
      render json: {
        status: 'error',
        message: 'Missing required parameter',
        details: e.message,
        timestamp: Time.current.iso8601
      }, status: :bad_request
    rescue => error
      Rails.logger.error "Login error: #{error.class} - #{error.message}"
      
      render json: {
        status: 'error',
        message: 'An error occurred during login',
        timestamp: Time.current.iso8601
      }, status: :internal_server_error
    end
  end

  def logout
    begin
      # JWT logout is handled by devise-jwt automatically
      render json: {
        status: 'success',
        message: 'Logout successful',
        timestamp: Time.current.iso8601
      }
    rescue => error
      Rails.logger.error "Logout error: #{error.class} - #{error.message}"
      
      render json: {
        status: 'error',
        message: 'An error occurred during logout',
        timestamp: Time.current.iso8601
      }, status: :internal_server_error
    end
  end

  def register
    begin
      # Validate required parameters
      validate_register_params!
      
      user = User.new(register_params)
      user.role = :member # Default role for new registrations
      
      if user.save
        # Sign in the user for JWT authentication
        sign_in(user)
        
        render json: {
          status: 'success',
          message: 'User registered successfully',
          user: user_response_data(user),
          timestamp: Time.current.iso8601
        }, status: :created
      else
        Rails.logger.warn "Registration failed for email: #{user.email} - #{user.errors.full_messages}"
        
        render json: {
          status: 'error',
          message: 'Registration failed',
          errors: user.errors.full_messages,
          timestamp: Time.current.iso8601
        }, status: :unprocessable_entity
      end
    rescue ValidationError => e
      render json: {
        status: 'error',
        message: 'Validation failed',
        details: e.message,
        timestamp: Time.current.iso8601
      }, status: :bad_request
    rescue ActionController::ParameterMissing => e
      render json: {
        status: 'error',
        message: 'Missing required parameter',
        details: e.message,
        timestamp: Time.current.iso8601
      }, status: :bad_request
    rescue => error
      Rails.logger.error "Registration error: #{error.class} - #{error.message}"
      
      render json: {
        status: 'error',
        message: 'An error occurred during registration',
        timestamp: Time.current.iso8601
      }, status: :internal_server_error
    end
  end

  private

  # Strong Parameters for login
  def login_params
    params.require(:user).permit(:email, :password)
  end

  # Strong Parameters for registration
  def register_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end

  # Validate login parameters
  def validate_login_params!
    # This will raise ActionController::ParameterMissing if user param is missing
    params.require(:user)
    
    # Validate required fields
    unless login_params[:email].present?
      raise ActionController::ParameterMissing.new(:email, [:user, :email])
    end
    
    unless login_params[:password].present?
      raise ActionController::ParameterMissing.new(:password, [:user, :password])
    end

    # Validate email format
    unless valid_email_format?(login_params[:email])
      raise ValidationError, 'Invalid email format'
    end
  end

  # Validate registration parameters
  def validate_register_params!
    # This will raise ActionController::ParameterMissing if user param is missing
    params.require(:user)
    
    # Validate required fields
    unless register_params[:email].present?
      raise ActionController::ParameterMissing.new(:email, [:user, :email])
    end
    
    unless register_params[:password].present?
      raise ActionController::ParameterMissing.new(:password, [:user, :password])
    end

    unless register_params[:password_confirmation].present?
      raise ActionController::ParameterMissing.new(:password_confirmation, [:user, :password_confirmation])
    end

    # Validate email format
    unless valid_email_format?(register_params[:email])
      raise ValidationError, 'Invalid email format'
    end

    # Validate password length
    if register_params[:password].length < 8
      raise ValidationError, 'Password must be at least 8 characters long'
    end
  end

  # Validate email format
  def valid_email_format?(email)
    email.match?(URI::MailTo::EMAIL_REGEXP)
  end

  # Standardized user response data
  def user_response_data(user)
    {
      id: user.id,
      email: user.email,
      role: user.role
    }
  end
end
