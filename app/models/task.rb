class Task < ApplicationRecord
  belongs_to :user

  enum :status, { pending: 0, in_progress: 1, done: 2 }, default: :pending

  validates :title, presence: true
  validates :status, presence: true
  validates :due_date, presence: true
  validate :due_date_cannot_be_in_the_past

  private

  def due_date_cannot_be_in_the_past
    if due_date.present? && due_date < Date.current
      errors.add(:due_date, "can't be in the past")
    end
  end
end
