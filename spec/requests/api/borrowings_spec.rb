require 'rails_helper'

RSpec.describe "Api::Borrowings", type: :request do
  describe "Borrowing model functionality" do
    before(:each) do
      Borrowing.destroy_all
      Book.destroy_all
      User.destroy_all
    end

    let(:user1) { create(:user, :member) }
    let(:user2) { create(:user, :member) }
    let!(:book1) { create(:book, title: 'Ruby Programming', total_copies: 5, available_copies: 3) }
    let!(:book2) { create(:book, title: 'Python Basics', total_copies: 3, available_copies: 1) }
    let!(:book3) { create(:book, title: 'JavaScript Guide', total_copies: 2, available_copies: 2) }
    let!(:borrowing1) { create(:borrowing, user: user1, book: book1) }
    let!(:borrowing2) { create(:borrowing, user: user1, book: book2) }

    describe "Borrowing creation and validation" do
      it "creates borrowings with valid attributes" do
        expect(Borrowing.count).to eq(2)
        expect(borrowing1.user).to eq(user1)
        expect(borrowing1.book).to eq(book1)
        expect(borrowing1.borrowed_at).to be_present
        expect(borrowing1.due_date).to be_present
      end

      it "validates required attributes" do
        invalid_borrowing = Borrowing.new
        expect(invalid_borrowing).not_to be_valid
        expect(invalid_borrowing.errors[:user]).to include("must exist")
        expect(invalid_borrowing.errors[:book]).to include("must exist")
      end

      it "validates due date is after borrowed date" do
        borrowing = build(:borrowing, borrowed_at: 1.week.from_now, due_date: 1.day.ago)
        expect(borrowing).not_to be_valid
        expect(borrowing.errors[:due_date]).to include("must be after borrowed date")
      end

      it "prevents user from borrowing same book twice" do
        borrowing = build(:borrowing, user: user1, book: book1)
        expect(borrowing).not_to be_valid
        expect(borrowing.errors[:base]).to include("User has already borrowed this book")
      end

      it "prevents borrowing unavailable books" do
        unavailable_book = create(:book, total_copies: 3, available_copies: 0)
        borrowing = build(:borrowing, user: user2, book: unavailable_book)
        expect(borrowing).not_to be_valid
        expect(borrowing.errors[:base]).to include("Book is not available for borrowing")
      end
    end

    describe "Borrowing status" do
      it "checks if borrowing is active" do
        expect(borrowing1.active?).to be true
        expect(borrowing2.active?).to be true
      end

      it "checks if borrowing is overdue" do
        overdue_borrowing = create(:borrowing, 
          user: user2, 
          book: book3, 
          borrowed_at: 3.weeks.ago, 
          due_date: 1.week.ago
        )
        expect(overdue_borrowing.overdue?).to be true
        expect(borrowing1.overdue?).to be false
      end

      it "calculates days overdue" do
        overdue_borrowing = create(:borrowing, 
          user: user2, 
          book: book3, 
          borrowed_at: 3.weeks.ago, 
          due_date: 1.week.ago
        )
        expect(overdue_borrowing.days_overdue).to be >= 7
        expect(borrowing1.days_overdue).to eq(0)
      end
    end

    describe "Borrowing return functionality" do
      it "returns books successfully" do
        expect(borrowing1.return!).to be true
        expect(borrowing1.reload.returned_at).to be_present
        expect(borrowing1.active?).to be false
      end

      it "prevents returning already returned books" do
        borrowing1.return!
        expect(borrowing1.return!).to be false
      end
    end

    describe "Borrowing scopes" do
      it "filters active borrowings" do
        active_borrowings = Borrowing.active
        expect(active_borrowings).to include(borrowing1, borrowing2)
        
        borrowing1.return!
        expect(Borrowing.active).not_to include(borrowing1)
      end

      it "filters returned borrowings" do
        returned_borrowings = Borrowing.returned
        expect(returned_borrowings).to be_empty
        
        borrowing1.return!
        expect(Borrowing.returned).to include(borrowing1)
      end

      it "filters overdue borrowings" do
        overdue_borrowings = Borrowing.overdue
        expect(overdue_borrowings).to be_empty
        
        create(:borrowing, 
          user: user2, 
          book: book3, 
          borrowed_at: 3.weeks.ago, 
          due_date: 1.week.ago
        )
        expect(Borrowing.overdue.count).to eq(1)
      end

      it "filters borrowings due today" do
        today_borrowings = Borrowing.due_today
        expect(today_borrowings).to be_empty
        
        create(:borrowing, 
          user: user2, 
          book: book3, 
          borrowed_at: 2.weeks.ago, 
          due_date: Date.current
        )
        expect(Borrowing.due_today.count).to eq(1)
      end
    end

    describe "Borrowing callbacks" do
      it "sets borrowed_at and due_date on creation" do
        new_book = create(:book)
        borrowing = Borrowing.new(user: user2, book: new_book)
        borrowing.save!
        
        expect(borrowing.borrowed_at).to be_present
        expect(borrowing.due_date).to be_present
        expect(borrowing.due_date).to be_within(1.second).of(borrowing.borrowed_at + 2.weeks)
      end

      it "updates book availability when borrowing is created" do
        initial_copies = book3.available_copies
        new_book = create(:book, total_copies: 3, available_copies: 3)
        
        expect {
          borrowing = Borrowing.new(user: user2, book: new_book)
          borrowing.save!
        }.to change { new_book.reload.available_copies }.by(-1)
      end
    end

    describe "User borrowing associations" do
      it "tracks user's borrowings" do
        expect(user1.borrowings).to include(borrowing1, borrowing2)
        expect(user1.borrowed_books).to include(book1, book2)
      end

      it "tracks user's active borrowings" do
        expect(user1.active_borrowings).to include(borrowing1, borrowing2)
        
        borrowing1.return!
        expect(user1.active_borrowings).not_to include(borrowing1)
      end

      it "tracks user's overdue borrowings" do
        expect(user1.overdue_borrowings).to be_empty
        
        create(:borrowing, 
          user: user2, 
          book: book3, 
          borrowed_at: 3.weeks.ago, 
          due_date: 1.week.ago
        )
        expect(user2.overdue_borrowings.count).to eq(1)
      end
    end

    describe "Book borrowing associations" do
      it "tracks book's borrowings" do
        expect(book1.borrowings).to include(borrowing1)
        expect(book1.borrowers).to include(user1)
      end

      it "tracks book's active borrowings" do
        expect(book1.borrowings.active).to include(borrowing1)
        
        borrowing1.return!
        expect(book1.borrowings.active).not_to include(borrowing1)
      end
    end
  end
end

