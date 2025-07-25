class Borrowing < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :book

  # Validations
  validates :borrowed_at, presence: true
  validates :due_date, presence: true
  validate :due_date_after_borrowed_at
  validate :user_cannot_borrow_same_book_twice, on: :create
  validate :book_must_be_available, on: :create

  # Scopes
  scope :active, -> { where(returned_at: nil) }
  scope :returned, -> { where.not(returned_at: nil) }
  scope :overdue, -> { active.where("due_date < ?", Time.current) }
  scope :due_today, -> { active.where("due_date::date = ?", Date.current) }
  scope :due_this_week, -> { active.where("due_date BETWEEN ? AND ?", Time.current, 1.week.from_now) }

  # Callbacks
  before_validation :set_borrowed_at_and_due_date, if: -> { new_record? && (borrowed_at.nil? || due_date.nil?) }
  before_validation :set_borrowed_at_on_update, if: -> { !new_record? && borrowed_at.nil? }
  after_create :update_book_availability_on_create
  after_update :update_book_availability_after_return

  # Instance methods
  def active?
    returned_at.nil?
  end

  def overdue?
    active? && due_date < Time.current
  end

  def days_overdue
    return 0 unless overdue?
    ((Time.current - due_date) / 1.day).to_i
  end

  def return!
    return false if returned_at.present?
    update!(returned_at: Time.current)
    true
  end

  private

  def due_date_after_borrowed_at
    return unless borrowed_at && due_date

    if due_date <= borrowed_at
      errors.add(:due_date, "must be after borrowed date")
    end
  end

  def user_cannot_borrow_same_book_twice
    return unless user && book

    if user.borrowings.active.exists?(book: book)
      errors.add(:base, "User has already borrowed this book")
    end
  end

  def book_must_be_available
    return unless book

    unless book.available?
      errors.add(:base, "Book is not available for borrowing")
    end
  end

  def set_borrowed_at_and_due_date
    self.borrowed_at = Time.current if borrowed_at.nil?
    self.due_date = 2.weeks.from_now if due_date.nil?
  end

  def set_borrowed_at_on_update
    self.borrowed_at = Time.current if borrowed_at.nil?
  end

  def update_book_availability_after_return
    if returned_at.present? && saved_change_to_returned_at?
      book.return!
    end
  end

  def update_book_availability_on_create
    book.borrow!
  end
end
