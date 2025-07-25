class BorrowingBookSerializer < ActiveModel::Serializer
  include BookMethods
  
  attributes :id, :title, :author, :genre, :isbn, :total_copies, :available_copies, :borrowed_copies, :available?
end 