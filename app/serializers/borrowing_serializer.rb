class BorrowingSerializer < ActiveModel::Serializer
  include BorrowingMethods
  
  attributes :id, :user_id, :book_id, :borrowed_at, :due_date, :returned_at, :active?, :overdue?, :days_overdue
end 