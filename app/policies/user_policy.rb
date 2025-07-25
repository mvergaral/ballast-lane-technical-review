class UserPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.librarian?
        scope.all
      else
        scope.none # Members cannot see other users
      end
    end
  end

  def index?
    user.librarian?
  end

  def show?
    user.librarian? || record == user
  end

  def create?
    user.librarian?
  end

  def update?
    user.librarian? || record == user
  end

  def destroy?
    user.librarian? && record != user # Can't delete themselves
  end
end 