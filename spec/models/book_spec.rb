require 'rails_helper'

RSpec.describe Book, type: :model do
  describe 'associations' do
    it { should have_many(:borrowings).dependent(:destroy) }
    it { should have_many(:borrowers).through(:borrowings).source(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:author) }
    it { should validate_presence_of(:genre) }
    it { should validate_presence_of(:isbn) }
    it { should validate_presence_of(:total_copies) }
    it { should validate_length_of(:title).is_at_least(1).is_at_most(255) }
    it { should validate_length_of(:author).is_at_least(1).is_at_most(255) }
    it { should validate_length_of(:genre).is_at_least(1).is_at_most(100) }
    it { should validate_length_of(:isbn).is_equal_to(13) }
    it { should validate_numericality_of(:total_copies).is_greater_than(0) }
    it { should validate_numericality_of(:available_copies).is_greater_than_or_equal_to(0) }
  end

  describe 'scopes' do
    let!(:available_book) { create(:book, total_copies: 5, available_copies: 3) }
    let!(:unavailable_book) { create(:book, total_copies: 3, available_copies: 0) }

    describe '.available' do
      it 'returns only available books' do
        expect(Book.available).to include(available_book)
        expect(Book.available).not_to include(unavailable_book)
      end
    end

    describe '.search' do
      let!(:ruby_book) { create(:book, title: 'Ruby Programming', author: 'John Doe', genre: 'Programming') }
      let!(:python_book) { create(:book, title: 'Python Basics', author: 'Jane Smith', genre: 'Programming') }
      let!(:js_book) { create(:book, title: 'JavaScript Guide', author: 'Bob Johnson', genre: 'Web Development') }

      it 'searches by title' do
        results = Book.search('Ruby')
        expect(results).to include(ruby_book)
        expect(results).not_to include(python_book, js_book)
      end

      it 'searches by author' do
        results = Book.search('John')
        expect(results).to include(ruby_book)
        expect(results).not_to include(python_book, js_book)
      end

      it 'searches by genre' do
        results = Book.search('Programming')
        expect(results).to include(ruby_book, python_book)
        expect(results).not_to include(js_book)
      end

      it 'returns empty when query is blank' do
        expect(Book.search('')).to be_empty
        expect(Book.search(nil)).to be_empty
      end

      it 'orders results by relevance' do
        results = Book.search('Programming')
        expect(results.first).to eq(python_book) # Alphabetical order by title
      end
    end

    describe '.advanced_search' do
      let!(:ruby_book) { create(:book, title: 'Ruby Programming', author: 'John Doe', genre: 'Programming', total_copies: 5, available_copies: 3) }
      let!(:python_book) { create(:book, title: 'Python Basics', author: 'Jane Smith', genre: 'Programming', total_copies: 3, available_copies: 0) }
      let!(:js_book) { create(:book, title: 'JavaScript Guide', author: 'Bob Johnson', genre: 'Web Development', total_copies: 2, available_copies: 2) }

      it 'filters by available books only' do
        results = Book.advanced_search('Programming', { available_only: true })
        expect(results).to include(ruby_book)
        expect(results).not_to include(python_book, js_book)
      end

      it 'filters by genre' do
        results = Book.advanced_search('Programming', { genre: 'Programming' })
        expect(results).to include(ruby_book, python_book)
        expect(results).not_to include(js_book)
      end

      it 'filters by minimum copies' do
        results = Book.advanced_search('', { min_copies: 3 })
        expect(results).to include(ruby_book, python_book)
        expect(results).not_to include(js_book)
      end

      it 'combines multiple filters' do
        results = Book.advanced_search('Programming', { available_only: true, min_copies: 3 })
        expect(results).to include(ruby_book)
        expect(results).not_to include(python_book, js_book)
      end
    end

    describe '.search_suggestions' do
      let!(:ruby_book) { create(:book, title: 'Ruby Programming') }
      let!(:python_book) { create(:book, title: 'Python Basics') }
      let!(:js_book) { create(:book, title: 'JavaScript Guide') }

      it 'returns title suggestions' do
        suggestions = Book.search_suggestions('Ruby')
        expect(suggestions).to include('Ruby Programming')
      end

      it 'limits suggestions' do
        create(:book, title: 'Ruby on Rails')
        suggestions = Book.search_suggestions('Ruby', 2)
        expect(suggestions.length).to eq(2)
      end

      it 'returns empty array for blank query' do
        expect(Book.search_suggestions('')).to eq([])
        expect(Book.search_suggestions(nil)).to eq([])
      end
    end
  end

  describe 'instance methods' do
    let(:book) { create(:book, total_copies: 5, available_copies: 3) }

    describe '#available?' do
      it 'returns true when copies are available' do
        expect(book.available?).to be true
      end

      it 'returns false when no copies are available' do
        book.update!(available_copies: 0)
        expect(book.available?).to be false
      end
    end

    describe '#borrowed_copies' do
      it 'returns the number of borrowed copies' do
        expect(book.borrowed_copies).to eq(2) # 5 total - 3 available
      end
    end

    describe '#borrow!' do
      it 'decrements available copies' do
        expect { book.borrow! }.to change { book.reload.available_copies }.by(-1)
      end

      it 'returns true when successful' do
        expect(book.borrow!).to be true
      end

      it 'returns false when no copies available' do
        book.update!(available_copies: 0)
        expect(book.borrow!).to be false
      end

      it 'handles transaction rollback on error' do
        # Simular un error en la transacción
        allow(book).to receive(:decrement!).and_raise(ActiveRecord::RecordInvalid.new(book))
        expect(book.borrow!).to be false
      end
    end

    describe '#return!' do
      it 'increments available copies' do
        expect { book.return! }.to change { book.reload.available_copies }.by(1)
      end

      it 'returns true when successful' do
        expect(book.return!).to be true
      end

      it 'returns false when all copies are available' do
        book.update!(available_copies: 5)
        expect(book.return!).to be false
      end

      it 'handles transaction rollback on error' do
        # Simular un error en la transacción
        allow(book).to receive(:increment!).and_raise(ActiveRecord::RecordInvalid.new(book))
        expect(book.return!).to be false
      end
    end

    describe '.search_with_highlight' do
      let!(:ruby_book) { create(:book, title: 'Ruby Programming', author: 'John Doe', genre: 'Programming') }
      let!(:python_book) { create(:book, title: 'Python Basics', author: 'Jane Smith', genre: 'Programming') }

      it 'returns books with highlighted titles' do
        results = Book.search_with_highlight('Ruby')
        expect(results).to include(ruby_book)
        expect(results).not_to include(python_book)
      end

      it 'returns empty when query is blank' do
        expect(Book.search_with_highlight('')).to be_empty
        expect(Book.search_with_highlight(nil)).to be_empty
      end

      it 'orders results by title' do
        results = Book.search_with_highlight('Programming')
        expect(results.first).to eq(python_book) # Alphabetical order
      end

      it 'includes title_highlight attribute' do
        results = Book.search_with_highlight('Ruby')
        expect(results.first.attributes).to have_key('title_highlight')
      end
    end
  end

  describe 'validations' do
    describe 'available_copies_cannot_exceed_total_copies' do
      it 'validates available_copies does not exceed total_copies' do
        book = build(:book, total_copies: 3, available_copies: 5)
        expect(book).not_to be_valid
        expect(book.errors[:available_copies]).to include('cannot exceed total copies')
      end

      it 'allows available_copies equal to total_copies' do
        book = build(:book, total_copies: 3, available_copies: 3)
        expect(book).to be_valid
      end

      it 'allows available_copies less than total_copies' do
        book = build(:book, total_copies: 5, available_copies: 3)
        expect(book).to be_valid
      end

      it 'handles nil values gracefully' do
        book = build(:book, total_copies: nil, available_copies: nil)
        expect(book).not_to be_valid # Due to presence validations
      end
    end
  end

  describe 'callbacks' do
    describe 'before_validation' do
      it 'sets available_copies to total_copies on create' do
        book = Book.create!(
          title: 'New Book',
          author: 'New Author',
          genre: 'Fiction',
          isbn: sprintf("%013d", Time.current.to_i % 10000000000000),
          total_copies: 5,
          available_copies: nil
        )
        expect(book.available_copies).to eq(5)
      end

      it 'does not override existing available_copies' do
        book = Book.create!(
          title: 'New Book',
          author: 'New Author',
          genre: 'Fiction',
          isbn: sprintf("%013d", Time.current.to_i % 10000000000001),
          total_copies: 5,
          available_copies: 3
        )
        expect(book.available_copies).to eq(3)
      end
    end

    describe 'before_save' do
      it 'updates search_vector when title changes' do
        book = create(:book, title: 'Original Title')
        original_vector = book.search_vector
        
        book.update!(title: 'Updated Title')
        expect(book.search_vector).not_to eq(original_vector)
      end

      it 'updates search_vector when author changes' do
        book = create(:book, author: 'Original Author')
        original_vector = book.search_vector
        
        book.update!(author: 'Updated Author')
        expect(book.search_vector).not_to eq(original_vector)
      end

      it 'updates search_vector when genre changes' do
        book = create(:book, genre: 'Original Genre')
        original_vector = book.search_vector
        
        book.update!(genre: 'Updated Genre')
        expect(book.search_vector).not_to eq(original_vector)
      end

      it 'updates search_vector when isbn changes' do
        book = create(:book)
        original_vector = book.search_vector
        
        new_isbn = sprintf("%013d", (Time.current.to_i % 10000000000000) + 999)
        book.update!(isbn: new_isbn)
        expect(book.search_vector).not_to eq(original_vector)
      end

      it 'does not update search_vector when other fields change' do
        book = create(:book, total_copies: 5)
        original_vector = book.search_vector
        
        book.update!(total_copies: 10)
        expect(book.search_vector).to eq(original_vector)
      end

      it 'creates search_vector when nil' do
        book = create(:book)
        book.update_column(:search_vector, nil)
        
        book.update!(title: book.title) # Force update
        expect(book.search_vector).not_to be_nil
      end

      it 'handles SQL execution errors gracefully' do
        book = create(:book)
        
        # Mock ActiveRecord::Base.connection to raise an error
        allow(ActiveRecord::Base.connection).to receive(:execute).and_raise(StandardError.new('SQL Error'))
        
        # Should not raise error, just log warning
        expect { book.update!(title: 'New Title') }.not_to raise_error
      end
    end
  end

  describe 'private methods' do
    let(:book) { build(:book, total_copies: 5, available_copies: 3) }

    describe '#set_available_copies' do
      it 'is called on create when available_copies is nil' do
        new_book = build(:book, available_copies: nil)
        expect(new_book).to receive(:set_available_copies).and_call_original
        new_book.save!
      end

      it 'sets available_copies to total_copies when nil' do
        book.available_copies = nil
        book.send(:set_available_copies)
        expect(book.available_copies).to eq(book.total_copies)
      end

      it 'does not change available_copies when present' do
        original_available = book.available_copies
        book.send(:set_available_copies)
        expect(book.available_copies).to eq(original_available)
      end
    end

    describe '#update_search_vector' do
      it 'updates search_vector when relevant fields change' do
        book.title = 'New Title'
        expect(book).to receive(:title_changed?).and_return(true)
        
        book.send(:update_search_vector)
        expect(book.search_vector).to include('new', 'titl')
      end

      it 'does not update when no relevant fields changed' do
        allow(book).to receive(:title_changed?).and_return(false)
        allow(book).to receive(:author_changed?).and_return(false)
        allow(book).to receive(:genre_changed?).and_return(false)
        allow(book).to receive(:isbn_changed?).and_return(false)
        book.search_vector = 'existing_vector'
        
        original_vector = book.search_vector
        book.send(:update_search_vector)
        expect(book.search_vector).to eq(original_vector)
      end
    end

    describe '#available_copies_cannot_exceed_total_copies' do
      it 'adds error when available_copies exceed total_copies' do
        book.available_copies = 10
        book.total_copies = 5
        
        book.send(:available_copies_cannot_exceed_total_copies)
        expect(book.errors[:available_copies]).to include('cannot exceed total copies')
      end

      it 'does not add error when available_copies are valid' do
        book.available_copies = 3
        book.total_copies = 5
        
        book.send(:available_copies_cannot_exceed_total_copies)
        expect(book.errors[:available_copies]).to be_empty
      end

      it 'handles nil values' do
        book.available_copies = nil
        book.total_copies = nil
        
        expect { book.send(:available_copies_cannot_exceed_total_copies) }.not_to raise_error
      end
    end
  end

  describe 'custom validations' do
    describe 'available_copies_cannot_exceed_total_copies' do
      it 'adds error when available copies exceed total copies' do
        book = build(:book, total_copies: 3, available_copies: 5)
        expect(book).not_to be_valid
        expect(book.errors[:available_copies]).to include('cannot exceed total copies')
      end
    end
  end

  describe 'class methods' do
    describe '.search_with_highlight' do
      let!(:ruby_book) { create(:book, title: 'Ruby Programming') }

      it 'returns books with highlighted titles' do
        results = Book.search_with_highlight('Ruby')
        expect(results).to include(ruby_book)
        expect(results.first).to respond_to(:title_highlight)
      end

      it 'returns empty for blank query' do
        expect(Book.search_with_highlight('')).to be_empty
        expect(Book.search_with_highlight(nil)).to be_empty
      end
    end
  end

  describe 'search vector functionality' do
    let(:book) { create(:book, title: 'Test Book', author: 'Test Author', genre: 'Test Genre', isbn: sprintf("%013d", Time.current.to_i % 10000000000000)) }

    it 'updates search vector on save' do
      expect(book.search_vector).to be_present
    end

    it 'updates search vector when title changes' do
      original_vector = book.search_vector
      book.update!(title: 'Updated Title')
      expect(book.search_vector).not_to eq(original_vector)
    end

    it 'handles search vector update errors gracefully' do
      # Simular un error en la actualización del vector
      allow(ActiveRecord::Base.connection).to receive(:execute).and_raise(StandardError.new('Database error'))
      expect { book.update!(title: 'New Title') }.not_to raise_error
    end
  end
end
