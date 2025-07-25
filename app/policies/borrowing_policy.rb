class BorrowingPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.librarian?
        scope.all
      else
        scope.where(user: user)
      end
    end
  end

  def index?
    true
  end

  def show?
    user.librarian? || record.user == user
  end

  def create?
    user.member?
  end

  def update?
    user.librarian?
  end

  def destroy?
    user.librarian?
  end

  def return?
    user.librarian?
  end

  def return_book?
    user.librarian? || record.user == user
  end
end
