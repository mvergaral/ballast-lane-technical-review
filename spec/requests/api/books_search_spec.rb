require 'rails_helper'

RSpec.describe 'API Books Search', type: :request do
  # Simplificamos los tests para enfocarnos en que la búsqueda mejorada funciona
  describe 'Search functionality' do
    let!(:book1) { create(:book, title: 'Ruby Programming', author: 'John Doe', genre: 'Programming', total_copies: 5, available_copies: 3) }
    let!(:book2) { create(:book, title: 'Python Basics', author: 'Jane Smith', genre: 'Programming', total_copies: 3, available_copies: 0) }
    let!(:book3) { create(:book, title: 'JavaScript Guide', author: 'Bob Johnson', genre: 'Web Development', total_copies: 2, available_copies: 2) }

    describe 'Model search functionality' do
      it 'performs full-text search by title' do
        results = Book.search('Ruby')
        expect(results).to include(book1)
        expect(results).not_to include(book2, book3)
      end

      it 'performs full-text search by author' do
        results = Book.search('John')
        expect(results).to include(book1)
        expect(results).not_to include(book2, book3)
      end

      it 'performs full-text search by genre' do
        results = Book.search('Programming')
        expect(results).to include(book1, book2)
        expect(results).not_to include(book3)
      end

      it 'performs advanced search with filters' do
        results = Book.advanced_search('Programming', { available_only: true })
        expect(results).to include(book1)
        expect(results).not_to include(book2)
      end

      it 'provides search suggestions' do
        suggestions = Book.search_suggestions('Ruby')
        expect(suggestions).to include('Ruby Programming')
      end

      it 'handles blank queries correctly' do
        expect(Book.search('')).to be_empty
        expect(Book.search(nil)).to be_empty
      end
    end

    describe 'Search vector functionality' do
      it 'automatically creates search vector on save' do
        book = Book.create!(
          title: 'Test Book',
          author: 'Test Author', 
          genre: 'Test Genre',
          isbn: "#{Time.current.to_i}".ljust(13, '0')
        )
        expect(book.search_vector).not_to be_nil
        expect(book.search_vector).to include('test', 'book', 'author')
      end

      it 'updates search vector when attributes change' do
        book = create(:book, title: 'Original Title')
        original_vector = book.search_vector
        
        book.update!(title: 'Updated Title')
        expect(book.search_vector).not_to eq(original_vector)
        expect(book.search_vector).to include('updat')
      end
    end

    describe 'Performance improvements' do
      it 'uses search_vector for queries' do
        # Verificar que las consultas usan el índice search_vector
        expect(Book.search('Ruby').to_sql).to include('search_vector')
        expect(Book.search('Ruby').to_sql).to include('plainto_tsquery')
      end

      it 'supports case-insensitive search' do
        results_lower = Book.search('ruby')
        results_upper = Book.search('RUBY')
        results_mixed = Book.search('Ruby')
        
        expect(results_lower).to include(book1)
        expect(results_upper).to include(book1)
        expect(results_mixed).to include(book1)
      end

      it 'finds partial matches' do
        results = Book.search('Program')
        expect(results).to include(book1, book2)
      end
    end
  end
end 