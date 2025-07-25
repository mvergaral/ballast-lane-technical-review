module UserMethods
  extend ActiveSupport::Concern

  def librarian?
    object.librarian?
  end

  def member?
    object.member?
  end
end 