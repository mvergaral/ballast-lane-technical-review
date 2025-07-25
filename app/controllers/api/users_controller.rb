class Api::UsersController < Api::ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [ :show ]

  def index
    authorize User

    users = policy_scope(User)
    users = apply_filters(users)
    users = users.page(pagination_params[:page])
                 .per(pagination_params[:per_page])

    render json: {
      users: ActiveModel::Serializer::CollectionSerializer.new(
        users,
        serializer: UserListSerializer
      ).as_json,
      pagination: {
        current_page: users.current_page,
        total_pages: users.total_pages,
        total_count: users.total_count,
        per_page: users.limit_value
      }
    }
  end

  def show
    render json: {
      user: UserSerializer.new(@user).as_json
    }
  end

  def create
    authorize User

    @user = User.new(user_params)


    if @user.save
      render json: {
        user: UserSerializer.new(@user).as_json
      }, status: :created
    else
      render json: {
        error: "Validation failed",
        details: @user.errors.full_messages
      }, status: :unprocessable_entity
    end
  rescue ActionController::ParameterMissing => e
    render json: {
      error: "Missing required parameter",
      message: e.message
    }, status: :bad_request
  end

  private

  def set_user
    @user = User.find(params[:id])
    authorize @user
  rescue ActiveRecord::RecordNotFound
    render json: {
      error: "Resource not found",
      message: "User not found",
      status: "not_found",
      timestamp: Time.current.iso8601
    }, status: :not_found
  end

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :role)
  end

  def apply_filters(users)
    # Filter by role
    if params[:role].present? && params[:role] != "all"
      case params[:role]
      when "librarian"
        users = users.librarians
      when "member"
        users = users.members
      end
    end

    # Filter by search query
    if params[:search].present?
      search_term = "%#{params[:search].strip}%"
      users = users.where("email ILIKE ?", search_term)
    end

    # Default ordering
    users.order(:role, :email)
  end
end
