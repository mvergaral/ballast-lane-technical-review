require 'rails_helper'

RSpec.describe "Api::Books", type: :request do
  describe "Book model functionality" do
    before(:each) do
      Book.destroy_all
    end

    let!(:book1) { create(:book, title: 'Ruby Programming', author: 'John Doe', genre: 'Programming', total_copies: 5, available_copies: 3) }
    let!(:book2) { create(:book, title: 'Python Basics', author: 'Jane Smith', genre: 'Programming', total_copies: 3, available_copies: 1) }
    let!(:book3) { create(:book, title: 'JavaScript Guide', author: 'Bob Johnson', genre: 'Web Development', total_copies: 2, available_copies: 2) }

    describe "Book creation and validation" do
      it "creates books with valid attributes" do
        expect(Book.count).to eq(3)
        expect(book1.title).to eq('Ruby Programming')
        expect(book1.author).to eq('John Doe')
        expect(book1.genre).to eq('Programming')
      end

      it "validates required attributes" do
        invalid_book = Book.new
        expect(invalid_book).not_to be_valid
        expect(invalid_book.errors[:title]).to include("can't be blank")
        expect(invalid_book.errors[:author]).to include("can't be blank")
        expect(invalid_book.errors[:genre]).to include("can't be blank")
        expect(invalid_book.errors[:isbn]).to include("can't be blank")
      end

      it "validates ISBN format" do
        book = build(:book, isbn: '123')
        expect(book).not_to be_valid
        expect(book.errors[:isbn]).to include("is the wrong length (should be 13 characters)")
      end

      it "validates total copies is positive" do
        book = build(:book, total_copies: 0)
        expect(book).not_to be_valid
        expect(book.errors[:total_copies]).to include("must be greater than 0")
      end

      it "validates available copies cannot exceed total copies" do
        book = build(:book, total_copies: 3, available_copies: 5)
        expect(book).not_to be_valid
        expect(book.errors[:available_copies]).to include("cannot exceed total copies")
      end
    end

    describe "Book availability" do
      it "checks if book is available" do
        expect(book1.available?).to be true
        expect(book2.available?).to be true
        expect(book3.available?).to be true
      end

      it "calculates borrowed copies correctly" do
        expect(book1.borrowed_copies).to eq(2) # 5 total - 3 available
        expect(book2.borrowed_copies).to eq(2) # 3 total - 1 available
        expect(book3.borrowed_copies).to eq(0) # 2 total - 2 available
      end
    end

    describe "Book borrowing and returning" do
      it "allows borrowing when copies are available" do
        expect(book1.borrow!).to be true
        expect(book1.reload.available_copies).to eq(2)
      end

      it "prevents borrowing when no copies available" do
        book = create(:book, total_copies: 1, available_copies: 0)
        expect(book.borrow!).to be false
        expect(book.available_copies).to eq(0)
      end

      it "allows returning books" do
        book = create(:book, total_copies: 3, available_copies: 1)
        expect(book.return!).to be true
        expect(book.reload.available_copies).to eq(2)
      end

      it "prevents returning when all copies are available" do
        book = create(:book, total_copies: 3, available_copies: 3)
        expect(book.return!).to be false
        expect(book.available_copies).to eq(3)
      end
    end

    describe "Book search functionality" do
      it "searches by title" do
        results = Book.search('Ruby')
        expect(results).to include(book1)
        expect(results).not_to include(book2, book3)
      end

      it "searches by author" do
        results = Book.search('John')
        expect(results).to include(book1)
        expect(results).not_to include(book2, book3)
      end

      it "searches by genre" do
        results = Book.search('Programming')
        expect(results).to include(book1, book2)
        expect(results).not_to include(book3)
      end

      it "returns empty for blank queries" do
        expect(Book.search('')).to be_empty
        expect(Book.search(nil)).to be_empty
      end

      it "provides search suggestions" do
        suggestions = Book.search_suggestions('Ruby')
        expect(suggestions).to include('Ruby Programming')
      end
    end

    describe "Book scopes" do
      it "filters available books" do
        available_books = Book.available
        expect(available_books).to include(book1, book2, book3)
        
        unavailable_book = create(:book, total_copies: 3, available_copies: 0)
        expect(Book.available).not_to include(unavailable_book)
      end

      it "performs advanced search with filters" do
        results = Book.advanced_search('Programming', { available_only: true })
        expect(results).to include(book1, book2)
        expect(results).not_to include(book3)
      end
    end

    describe "Book callbacks" do
      it "sets available copies on creation" do
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

      it "updates search vector on save" do
        book = create(:book, title: 'Original Title')
        original_vector = book.search_vector
        
        book.update!(title: 'Updated Title')
        expect(book.search_vector).not_to eq(original_vector)
        expect(book.search_vector).to include('updat')
      end
    end
  end
end
