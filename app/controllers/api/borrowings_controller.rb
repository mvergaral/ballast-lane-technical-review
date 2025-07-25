class Api::BorrowingsController < Api::ApplicationController
  before_action :set_borrowing, only: [ :show, :update, :destroy, :return_book ]

  # GET /api/borrowings
  def index
    @borrowings = policy_scope(Borrowing)
                   .includes(:user, :book)
                   .order(created_at: :desc)
                   .page(params[:page])
                   .per(params[:per_page] || 20)

    render json: {
      borrowings: @borrowings.as_json(include: {
        user: { only: [ :id, :email, :role ] },
        book: { only: [ :id, :title, :author, :isbn ] }
      }),
      pagination: {
        current_page: @borrowings.current_page,
        total_pages: @borrowings.total_pages,
        total_count: @borrowings.total_count,
        per_page: @borrowings.limit_value
      }
    }
  end

  # GET /api/borrowings/:id
  def show
    render json: @borrowing.as_json(include: {
      user: { only: [ :id, :email, :role ] },
      book: { only: [ :id, :title, :author, :isbn, :total_copies, :available_copies ] }
    })
  end

  # POST /api/borrowings
  def create
    # Validate required parameters first
    validate_create_params!

    @book = Book.find(borrowing_create_params[:book_id])
    authorize Borrowing

    @borrowing = current_user.borrowings.build(
      book: @book,
      due_date: borrowing_create_params[:due_date] || default_due_date
    )

    if @borrowing.save
      render json: @borrowing.as_json(include: {
        book: { only: [ :id, :title, :author, :isbn ] }
      }), status: :created
    else
      render json: {
        error: "Cannot borrow book",
        details: @borrowing.errors.full_messages
      }, status: :unprocessable_entity
    end
  rescue ActionController::ParameterMissing => e
    render json: {
      error: "Missing required parameter",
      message: e.message
    }, status: :bad_request
  rescue ActiveRecord::RecordNotFound
    render json: {
      error: "Book not found",
      message: "The requested book does not exist"
    }, status: :not_found
  end

  # PUT /api/borrowings/:id
  def update
    begin
      if @borrowing.update(borrowing_update_params)
        render json: @borrowing.as_json(include: {
          book: { only: [ :id, :title, :author, :isbn ] }
        })
      else
        render json: {
          error: "Validation failed",
          details: @borrowing.errors.full_messages
        }, status: :unprocessable_entity
      end
    rescue ActionController::ParameterMissing => e
      render json: {
        error: "Missing required parameter",
        message: e.message
      }, status: :bad_request
    end
  end

  # DELETE /api/borrowings/:id
  def destroy
    if @borrowing.destroy
      render json: { message: "Borrowing deleted successfully" }
    else
      render json: {
        error: "Cannot delete borrowing",
        details: @borrowing.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # POST /api/borrowings/:id/return_book
  def return_book
    authorize @borrowing, :return_book?

    if @borrowing.return!
      render json: {
        message: "Book returned successfully",
        borrowing: @borrowing.as_json(include: {
          book: { only: [ :id, :title, :author, :isbn ] }
        })
      }
    else
      render json: {
        error: "Cannot return book",
        details: @borrowing.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def set_borrowing
    @borrowing = Borrowing.find(params[:id])
    authorize @borrowing
  rescue ActiveRecord::RecordNotFound
    render json: {
      error: "Resource not found",
      message: "Borrowing not found",
      status: "not_found",
      timestamp: Time.current.iso8601
    }, status: :not_found
  end

  # Para compatibilidad con tests existentes
  def borrowing_params
    if action_name == "create"
      borrowing_create_params
    else
      borrowing_update_params
    end
  end

  def borrowing_create_params
    params.require(:borrowing).permit(:book_id, :due_date)
  end

  # Strong Parameters for updating borrowings
  def borrowing_update_params
    params.require(:borrowing).permit(:due_date, :returned_at)
  end

  # Validate required parameters for create action
  def validate_create_params!
    # This will raise ActionController::ParameterMissing if borrowing param is missing
    params.require(:borrowing)

    # Validate book_id is present
    unless borrowing_create_params[:book_id].present?
      raise ActionController::ParameterMissing.new(:book_id, [ :borrowing, :book_id ])
    end
  end

  # Default due date (2 weeks from now)
  def default_due_date
    2.weeks.from_now
  end
end
