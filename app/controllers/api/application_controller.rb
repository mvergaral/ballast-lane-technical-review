class Api::ApplicationController < ApplicationController
  before_action :ensure_json_request
  before_action :authenticate_user!

  # Global exception handling - order matters: most specific first
  rescue_from Pundit::NotAuthorizedError, with: :forbidden
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
  rescue_from ActionController::ParameterMissing, with: :bad_request_missing_param
  rescue_from ActionController::RoutingError, with: :not_found
  rescue_from NoMethodError, with: :internal_server_error
  rescue_from ArgumentError, with: :bad_request_missing_param

  private

  def ensure_json_request
    return if request.format.json?

    render json: {
      error: "Only JSON requests are supported",
      message: "Please set Content-Type: application/json and Accept: application/json headers",
      timestamp: Time.current.iso8601
    }, status: :not_acceptable
  end

  def not_found(exception)
    message = exception.respond_to?(:message) ? exception.message : exception.to_s
    Rails.logger.warn "Record not found: #{message}"

    render json: {
      error: "Resource not found",
      message: message,
      status: "not_found",
      timestamp: Time.current.iso8601
    }, status: :not_found
  end

  def unprocessable_entity(exception)
    Rails.logger.warn "Validation failed: #{exception.record.errors.full_messages}"

    render json: {
      error: "Validation failed",
      details: exception.record.errors.full_messages,
      status: "unprocessable_entity",
      timestamp: Time.current.iso8601
    }, status: :unprocessable_entity
  end

  def bad_request_missing_param(exception)
    Rails.logger.warn "Missing parameter: #{exception.message}"

    render json: {
      error: "Missing required parameter",
      message: exception.message,
      status: "bad_request",
      timestamp: Time.current.iso8601
    }, status: :bad_request
  end

  def forbidden(exception = nil)
    Rails.logger.warn "Authorization failed for user #{current_user&.id}: #{exception&.class} - #{exception&.message}"

    render json: {
      error: "Access forbidden",
      message: "You are not authorized to perform this action",
      status: "forbidden",
      timestamp: Time.current.iso8601
    }, status: :forbidden
  end

  def internal_server_error(exception)
    Rails.logger.error "Internal server error: #{exception.class} - #{exception.message}"
    Rails.logger.error exception.backtrace.join("\n") if Rails.env.development?

    render json: {
      error: "Internal server error",
      message: Rails.env.production? ? "An unexpected error occurred" : exception.message,
      status: "internal_server_error",
      timestamp: Time.current.iso8601
    }, status: :internal_server_error
  end

  def current_user
    super
  end

  # Helper method for pagination parameters with validation
  def pagination_params
    params.permit(:page, :per_page).tap do |p|
      p[:page] = [ p[:page]&.to_i || 1, 1 ].max
      p[:per_page] = [ [ p[:per_page]&.to_i || 20, 1 ].max, 100 ].min # Between 1 and 100
    end
  end

  # Helper method for standard success response
  def success_response(data = {}, message = "Success", status = :ok)
    render json: {
      status: "success",
      message: message,
      data: data,
      timestamp: Time.current.iso8601
    }, status: status
  end

  # Helper method for standard error response
  def error_response(message, details = nil, status = :bad_request)
    response_data = {
      status: "error",
      message: message,
      timestamp: Time.current.iso8601
    }
    response_data[:details] = details if details.present?

    render json: response_data, status: status
  end
end
