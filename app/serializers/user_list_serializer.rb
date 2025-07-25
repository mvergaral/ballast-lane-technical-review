class UserListSerializer < ActiveModel::Serializer
  include UserMethods
  
  attributes :id, :email, :role, :created_at, :librarian?, :member?,
             :active_borrowings_count, :overdue_books_count, :total_borrowings_count

  def active_borrowings_count
    object.active_borrowings.count
  end

  def total_borrowings_count
    object.borrowings.count
  end
end 