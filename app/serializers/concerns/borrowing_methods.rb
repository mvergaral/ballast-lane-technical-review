module BorrowingMethods
  extend ActiveSupport::Concern

  def active?
    object.active?
  end

  def overdue?
    object.overdue?
  end

  def days_overdue
    object.days_overdue
  end
end 