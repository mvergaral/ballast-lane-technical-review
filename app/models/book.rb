class Book < ApplicationRecord
  # Associations
  has_many :borrowings, dependent: :destroy
  has_many :borrowers, through: :borrowings, source: :user

  # Validations
  validates :title, presence: true, length: { minimum: 1, maximum: 255 }
  validates :author, presence: true, length: { minimum: 1, maximum: 255 }
  validates :genre, presence: true, length: { minimum: 1, maximum: 100 }
  validates :isbn, presence: true, uniqueness: true
  validate :isbn_format
  validates :total_copies, presence: true, numericality: { greater_than: 0 }
  validates :available_copies, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validate :available_copies_cannot_exceed_total_copies

  # Scopes
  scope :available, -> { where("available_copies > 0") }

  # Full-text search scopes
  scope :search_by_title, ->(query) {
    where("search_vector @@ plainto_tsquery('english', ?)", query)
      .order(:title)
  }

  scope :search_by_author, ->(query) {
    where("search_vector @@ plainto_tsquery('english', ?)", query)
      .order(:author)
  }

  scope :search_by_genre, ->(query) {
    where("search_vector @@ plainto_tsquery('english', ?)", query)
      .order(:genre)
  }

  scope :search_by_title_author_isbn, ->(query) {
    return none if query.blank?

    where("search_vector @@ plainto_tsquery('english', ?) OR title ILIKE ? OR author ILIKE ? OR isbn ILIKE ?",
          query, "%#{query}%", "%#{query}%", "%#{query}%")
      .order(:title)
  }

  scope :search, ->(query) {
    return none if query.blank?

    where("search_vector @@ plainto_tsquery('english', ?)", query)
      .order(:title)
  }

  scope :advanced_search, ->(query, filters = {}) {
    scope = all

    if query.present?
      if filters[:title_only]
        scope = scope.search_by_title(query)
      elsif filters[:author]
        scope = scope.search_by_author(query)
      else
        scope = scope.search(query)
      end
    end

    scope = scope.available if filters[:available_only]
    scope = scope.where(genre: filters[:genre]) if filters[:genre].present?
    scope = scope.where("total_copies >= ?", filters[:min_copies]) if filters[:min_copies].present?
    scope = scope.where(author: filters[:author]) if filters[:author].present?

    scope
  }

  # Callbacks
  before_validation :normalize_isbn
  before_validation :set_available_copies, on: :create, if: :new_record?
  before_save :update_search_vector

  # Instance methods
  def available?
    available_copies > 0
  end

  def borrowed_copies
    total_copies - available_copies
  end

  def self.search_with_highlight(query)
    return none if query.blank?

    select(Arel.sql("books.*, ts_headline('english', title, plainto_tsquery('english', #{ActiveRecord::Base.connection.quote(query)}), 'StartSel=<mark>,StopSel=</mark>') as title_highlight"))
      .where("search_vector @@ plainto_tsquery('english', ?)", query)
      .order(:title)
  end

  def self.search_suggestions(query, limit = 5)
    return [] if query.blank?

    where("title ILIKE ?", "#{query}%")
      .limit(limit)
      .pluck(:title)
  end

  def borrow!
    return false unless available?

    transaction do
      decrement!(:available_copies)
    end
    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  def return!
    return false if available_copies >= total_copies

    transaction do
      increment!(:available_copies)
    end
    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  private

  def available_copies_cannot_exceed_total_copies
    return unless available_copies && total_copies

    if available_copies > total_copies
      errors.add(:available_copies, "cannot exceed total copies")
    end
  end

  def set_available_copies
    self.available_copies = total_copies if available_copies.nil?
  end

  def update_search_vector
    return unless title_changed? || author_changed? || genre_changed? || isbn_changed? || search_vector.nil?

    title_vector = "setweight(to_tsvector('english', COALESCE(#{ActiveRecord::Base.connection.quote(title)}, '')), 'A')"
    author_vector = "setweight(to_tsvector('english', COALESCE(#{ActiveRecord::Base.connection.quote(author)}, '')), 'B')"
    genre_vector = "setweight(to_tsvector('english', COALESCE(#{ActiveRecord::Base.connection.quote(genre)}, '')), 'C')"
    isbn_vector = "setweight(to_tsvector('english', COALESCE(#{ActiveRecord::Base.connection.quote(isbn)}, '')), 'D')"

    vector_sql = "#{title_vector} || #{author_vector} || #{genre_vector} || #{isbn_vector}"

    begin
      result = ActiveRecord::Base.connection.execute("SELECT #{vector_sql} as search_vector")
      self.search_vector = result.first["search_vector"]
    rescue => e
      Rails.logger.warn "Failed to update search_vector: #{e.message}"
    end
  end

  def normalize_isbn
    return if isbn.blank?

    # Remove hyphens, spaces, and any other non-digit characters
    self.isbn = isbn.gsub(/\D/, "")
  end

  def isbn_format
    return if isbn.blank?

    # After normalization, check if it's exactly 13 digits
    unless isbn.match?(/^\d{13}$/)
      errors.add(:isbn, "must be exactly 13 digits")
    end
  end
end
