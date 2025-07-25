class Api::DashboardController < Api::ApplicationController
  # GET /api/dashboard
  def index
    if current_user.librarian?
      render_librarian_dashboard
    else
      render_member_dashboard
    end
  end

  private

  def render_librarian_dashboard
    total_books = Book.count
    total_borrowed = Borrowing.active.count
    books_due_today = Borrowing.due_today.count
    overdue_borrowings = Borrowing.overdue.includes(:user, :book)
    recent_borrowings = Borrowing.includes(:user, :book).order(created_at: :desc).limit(10)

    # Transform overdue borrowings to overdue members format
    overdue_members = overdue_borrowings.group_by(&:user).map do |user, borrowings|
      {
        id: user.id,
        email: user.email,
        overdue_count: borrowings.count
      }
    end

    # Transform recent borrowings to the expected format
    recent_borrowings_data = recent_borrowings.map do |borrowing|
      {
        id: borrowing.id,
        book_title: borrowing.book.title,
        user_email: borrowing.user.email,
        borrowed_at: borrowing.borrowed_at
      }
    end

    render json: {
      role: 'librarian',
      stats: {
        total_books: total_books,
        total_borrowed_books: total_borrowed,
        books_due_today: books_due_today,
        overdue_books_count: overdue_borrowings.count
      },
      overdue_members: overdue_members,
      recent_borrowings: recent_borrowings_data
    }
  end

  def render_member_dashboard
    active_borrowings = current_user.active_borrowings.includes(:book)
    overdue_borrowings = current_user.overdue_borrowings.includes(:book)
    borrowing_history = current_user.borrowings.where.not(returned_at: nil).includes(:book).order(returned_at: :desc).limit(10)
    
    # Check for due soon (within 3 days)
    due_soon_borrowings = active_borrowings.select { |b| b.due_date <= 3.days.from_now && b.due_date > Time.current }

    # Transform borrowings to the expected format
    my_borrowings = active_borrowings.map do |borrowing|
      {
        id: borrowing.id,
        book_title: borrowing.book.title,
        book_author: borrowing.book.author,
        due_date: borrowing.due_date,
        is_overdue: borrowing.due_date < Time.current,
        is_due_soon: borrowing.due_date <= 3.days.from_now && borrowing.due_date > Time.current
      }
    end

    my_borrowing_history = borrowing_history.map do |borrowing|
      {
        id: borrowing.id,
        book_title: borrowing.book.title,
        book_author: borrowing.book.author,
        returned_at: borrowing.returned_at
      }
    end

    render json: {
      role: 'member',
      stats: {
        my_borrowed_books: active_borrowings.count,
        my_books_due_soon: due_soon_borrowings.count,
        my_overdue_books: overdue_borrowings.count
      },
      my_borrowings: my_borrowings,
      my_borrowing_history: my_borrowing_history
    }
  end
end
