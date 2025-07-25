class UserSerializer < ActiveModel::Serializer
  include UserMethods
  
  attributes :id, :email, :role, :librarian?, :member?
end 