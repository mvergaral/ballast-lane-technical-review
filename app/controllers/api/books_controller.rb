class Api::BooksController < Api::ApplicationController
  before_action :set_book, only: [ :show, :update, :destroy ]
  before_action :authorize_book_class, only: [ :create ]
  before_action :authorize_book_instance, only: [ :update, :destroy ]

  # GET /api/books
  def index
    @books = policy_scope(Book)

    # Apply filters if provided
    @books = apply_filters(@books)

    # Apply pagination
    @books = @books.page(pagination_params[:page])
                   .per(pagination_params[:per_page])

    render json: {
      books: @books.as_json(only: [ :id, :title, :author, :genre, :isbn, :total_copies, :available_copies ]),
      pagination: {
        current_page: @books.current_page,
        total_pages: @books.total_pages,
        total_count: @books.total_count,
        per_page: @books.limit_value
      }
    }
  end

  # GET /api/books/search
  def search
    begin
      validate_search_params!

      query = search_params[:q]
      @books = Book.search_by_title_author_isbn(query)
                  .page(pagination_params[:page])
                  .per(pagination_params[:per_page])

      render json: {
        books: @books.as_json(only: [ :id, :title, :author, :genre, :isbn, :total_copies, :available_copies ]),
        pagination: {
          current_page: @books.current_page,
          total_pages: @books.total_pages,
          total_count: @books.total_count,
          per_page: @books.limit_value
        },
        query: query
      }
    rescue ActionController::ParameterMissing => e
      render json: {
        error: "Missing required parameter",
        message: e.message
      }, status: :bad_request
    end
  end

  # GET /api/books/search/suggestions
  def search_suggestions
    begin
      validate_search_params!

      query = search_params[:q]
      limit_param = params[:limit]&.to_i || 5
      limit_param = [ limit_param, 50 ].min  # Max 50 suggestions

      suggestions = Book.search_by_title_author_isbn(query)
                       .limit(limit_param)
                       .pluck(:title, :author)
                       .map { |title, author| "#{title} by #{author}" }

      render json: { suggestions: suggestions, query: query }
    rescue ActionController::ParameterMissing => e
      render json: {
        error: "Missing required parameter",
        message: e.message
      }, status: :bad_request
    end
  end

  # GET /api/books/search/advanced
  def advanced_search
    begin
      @books = Book.all

      # Apply advanced search filters
      @books = apply_advanced_search_filters(@books)

      @books = @books.page(pagination_params[:page])
                     .per(pagination_params[:per_page])

      render json: {
        books: @books.as_json(only: [ :id, :title, :author, :genre, :isbn, :total_copies, :available_copies ]),
        pagination: {
          current_page: @books.current_page,
          total_pages: @books.total_pages,
          total_count: @books.total_count,
          per_page: @books.limit_value
        },
        filters: advanced_search_params.to_h
      }
    rescue => error
      Rails.logger.error "Advanced search error: #{error.class} - #{error.message}"
      render json: {
        error: "Search failed",
        message: "An error occurred while searching"
      }, status: :internal_server_error
    end
  end

  # GET /api/books/:id
  def show
    render json: @book.as_json(
      only: [ :id, :title, :author, :genre, :isbn, :total_copies, :available_copies ],
      include: {
        borrowings: {
          only: [ :id, :borrowed_at, :due_date, :returned_at ],
          include: {
            user: { only: [ :id, :email ] }
          }
        }
      }
    )
  end

  # POST /api/books
  def create
    begin
      @book = Book.new(book_create_params)

      if @book.save
        render json: @book.as_json(only: [ :id, :title, :author, :genre, :isbn, :total_copies, :available_copies ]),
               status: :created
      else
        render json: {
          error: "Cannot create book",
          details: @book.errors.full_messages
        }, status: :unprocessable_entity
      end
    rescue ActionController::ParameterMissing => e
      render json: {
        error: "Missing required parameter",
        message: e.message
      }, status: :bad_request
    end
  end

  # PUT /api/books/:id
  def update
    begin
      if @book.update(book_update_params)
        render json: @book.as_json(only: [ :id, :title, :author, :genre, :isbn, :total_copies, :available_copies ])
      else
        render json: {
          error: "Cannot update book",
          details: @book.errors.full_messages
        }, status: :unprocessable_entity
      end
    rescue ActionController::ParameterMissing => e
      render json: {
        error: "Missing required parameter",
        message: e.message
      }, status: :bad_request
    end
  end

  # DELETE /api/books/:id
  def destroy
    if @book.borrowings.where(returned_at: nil).exists?
      render json: {
        error: "Cannot delete book",
        message: "Book has active borrowings and cannot be deleted"
      }, status: :conflict
    elsif @book.destroy
      render json: { message: "Book deleted successfully" }
    else
      render json: {
        error: "Cannot delete book",
        details: @book.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def set_book
    @book = Book.find(params[:id])
    authorize @book
  rescue ActiveRecord::RecordNotFound
    not_found("Book not found")
  end

  def authorize_book_class
    authorize Book
  end

  def authorize_book_instance
    authorize @book
  end

  def authorize_book(record_or_class = Book)
    record_or_class = Book if record_or_class.nil?
    authorize(record_or_class)
  end

  # Para compatibilidad con tests existentes
  def book_params
    book_create_params
  end

  # Strong Parameters for creating books
  def book_create_params
    params.require(:book).permit(:title, :author, :genre, :isbn, :total_copies)
  end

  # Strong Parameters for updating books
  def book_update_params
    params.require(:book).permit(:title, :author, :genre, :isbn, :total_copies, :available_copies)
  end

  # Strong Parameters for search
  def search_params
    params.permit(:q)
  end

  # Strong Parameters for advanced search
  def advanced_search_params
    params.permit(:title, :author, :genre, :isbn, :available_only)
  end

  # Strong Parameters for pagination
  def pagination_params
    params.permit(:page, :per_page).tap do |p|
      p[:page] = p[:page]&.to_i || 1
      p[:per_page] = [ (p[:per_page]&.to_i || 20), 100 ].min # Max 100 per page
    end
  end

  # Validate search parameters
  def validate_search_params!
    if search_params[:q].blank?
      raise ActionController::ParameterMissing.new(:q, [ :q ])
    end
  end

  # Apply basic filters to books query
  def apply_filters(books)
    filter_params = params.permit(:title, :author, :genre, :available_only)

    books = books.where("title ILIKE ?", "%#{filter_params[:title]}%") if filter_params[:title].present?
    books = books.where("author ILIKE ?", "%#{filter_params[:author]}%") if filter_params[:author].present?
    books = books.where("genre ILIKE ?", "%#{filter_params[:genre]}%") if filter_params[:genre].present?
    books = books.where("available_copies > 0") if filter_params[:available_only] == "true"

    books
  end

  # Apply advanced search filters
  def apply_advanced_search_filters(books)
    filter_params = advanced_search_params

    books = books.where("title ILIKE ?", "%#{filter_params[:title]}%") if filter_params[:title].present?
    books = books.where("author ILIKE ?", "%#{filter_params[:author]}%") if filter_params[:author].present?
    books = books.where("genre ILIKE ?", "%#{filter_params[:genre]}%") if filter_params[:genre].present?
    books = books.where("isbn ILIKE ?", "%#{filter_params[:isbn]}%") if filter_params[:isbn].present?
    books = books.where("available_copies > 0") if filter_params[:available_only] == "true"

    books
  end
end
