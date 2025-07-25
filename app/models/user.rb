class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist
  # Enums
  enum :role, { member: 0, librarian: 1 }
  # Associations
  has_many :borrowings, dependent: :destroy
  has_many :borrowed_books, through: :borrowings, source: :book
  # Validations
  validates :role, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  # Scopes
  scope :librarians, -> { where(role: :librarian) }
  scope :members, -> { where(role: :member) }
  # Instance methods
  def librarian?
    role == 'librarian'
  end
  def member?
    role == 'member'
  end
  def active_borrowings
    borrowings.where(returned_at: nil)
  end
  def overdue_borrowings
    active_borrowings.where('due_date < ?', Time.current)
  end
  def overdue_books_count
    overdue_borrowings.count
  end
end
