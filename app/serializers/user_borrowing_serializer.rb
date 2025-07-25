class UserBorrowingSerializer < ActiveModel::Serializer
  include BorrowingMethods
  
  attributes :id, :book_id, :borrowed_at, :due_date, :returned_at, :active?, :overdue?, :days_overdue

  belongs_to :user, serializer: BorrowingUserSerializer
  belongs_to :book, serializer: BorrowingBookSerializer
end 