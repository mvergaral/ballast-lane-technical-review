require 'rails_helper'

RSpec.describe "Api::Dashboards", type: :request do
  describe "Dashboard functionality" do
    before(:each) do
      Borrowing.destroy_all
      Book.destroy_all
      User.destroy_all
    end

    let!(:librarian) { create(:user, :librarian) }
    let!(:member1) { create(:user, :member) }
    let!(:member2) { create(:user, :member) }
    let!(:book1) { create(:book, title: 'Ruby Programming', total_copies: 5, available_copies: 3) }
    let!(:book2) { create(:book, title: 'Python Basics', total_copies: 3, available_copies: 1) }
    let!(:book3) { create(:book, title: 'JavaScript Guide', total_copies: 2, available_copies: 2) }
    let!(:borrowing1) { create(:borrowing, user: member1, book: book1) }
    let!(:borrowing2) { create(:borrowing, user: member1, book: book2) }
    let!(:returned_borrowing) { create(:borrowing, user: member1, book: book3, returned_at: Time.current) }

    describe "System statistics" do
      it "calculates total books correctly" do
        expect(Book.count).to eq(3)
      end

      it "calculates total users correctly" do
        expect(User.count).to eq(3) # librarian + member1 + member2
      end

      it "calculates total borrowings correctly" do
        expect(Borrowing.count).to eq(3)
      end

      it "calculates active borrowings correctly" do
        expect(Borrowing.active.count).to eq(2)
      end

      it "calculates returned borrowings correctly" do
        expect(Borrowing.returned.count).to eq(1)
      end
    end

    describe "Book statistics" do
      it "calculates total copies correctly" do
        total_copies = Book.sum(:total_copies)
        expect(total_copies).to eq(10) # 5 + 3 + 2
      end

      it "calculates available copies correctly" do
        available_copies = Book.sum(:available_copies)
        # Los préstamos creados reducen la disponibilidad: 2 + 0 + 1 = 3
        expect(available_copies).to eq(3)
      end

      it "calculates borrowed copies correctly" do
        borrowed_copies = Book.sum(:total_copies) - Book.sum(:available_copies)
        # 10 total - 3 available = 7 borrowed
        expect(borrowed_copies).to eq(7)
      end
    end

    describe "User statistics" do
      it "counts librarians correctly" do
        librarians_count = User.librarians.count
        expect(librarians_count).to eq(1)
      end

      it "counts members correctly" do
        members_count = User.members.count
        expect(members_count).to eq(2)
      end
    end

    describe "Borrowing statistics" do
      it "tracks overdue borrowings" do
        expect(Borrowing.overdue.count).to eq(0)
        
        create(:borrowing, 
          user: member2, 
          book: book1, 
          borrowed_at: 3.weeks.ago, 
          due_date: 1.week.ago
        )
        expect(Borrowing.overdue.count).to eq(1)
      end

      it "tracks borrowings due today" do
        expect(Borrowing.due_today.count).to eq(0)
        
        create(:borrowing, 
          user: member2, 
          book: book1, 
          borrowed_at: 2.weeks.ago, 
          due_date: Date.current
        )
        expect(Borrowing.due_today.count).to eq(1)
      end

      it "tracks borrowings due this week" do
        expect(Borrowing.due_this_week.count).to be >= 0
        
        create(:borrowing, 
          user: member2, 
          book: book1, 
          borrowed_at: 1.week.ago, 
          due_date: 3.days.from_now
        )
        expect(Borrowing.due_this_week.count).to be >= 1
      end
    end

    describe "User-specific statistics" do
      it "tracks user's total borrowings" do
        expect(member1.borrowings.count).to eq(3)
      end

      it "tracks user's active borrowings" do
        expect(member1.active_borrowings.count).to eq(2)
      end

      it "tracks user's returned borrowings" do
        expect(member1.borrowings.returned.count).to eq(1)
      end

      it "tracks user's overdue borrowings" do
        expect(member1.overdue_borrowings.count).to eq(0)
        
        create(:borrowing, 
          user: member2, 
          book: book1, 
          borrowed_at: 3.weeks.ago, 
          due_date: 1.week.ago
        )
        expect(member2.overdue_borrowings.count).to eq(1)
      end

      it "calculates user's overdue books count" do
        expect(member1.overdue_books_count).to eq(0)
        
        create(:borrowing, 
          user: member2, 
          book: book1, 
          borrowed_at: 3.weeks.ago, 
          due_date: 1.week.ago
        )
        expect(member2.overdue_books_count).to eq(1)
      end
    end

    describe "Recent activity tracking" do
      it "tracks recent borrowings" do
        recent_borrowings = Borrowing.order(created_at: :desc).limit(5)
        expect(recent_borrowings.count).to eq(3)
      end

      it "tracks recent returns" do
        recent_returns = Borrowing.returned.order(updated_at: :desc).limit(5)
        expect(recent_returns.count).to eq(1)
      end

      it "tracks recent overdue notifications" do
        overdue_borrowings = Borrowing.overdue
        expect(overdue_borrowings.count).to eq(0)
      end
    end

    describe "Popular books analytics" do
      it "identifies most borrowed books" do
        create(:borrowing, user: member2, book: book1)
        create(:borrowing, user: librarian, book: book1)
        
        popular_books = Book.joins(:borrowings).group('books.id').order('COUNT(borrowings.id) DESC')
        expect(popular_books.first).to eq(book1)
      end

      it "identifies most active users" do
        create(:borrowing, user: member1, book: book3)
        
        active_users = User.joins(:borrowings).group('users.id').order('COUNT(borrowings.id) DESC')
        expect(active_users.first).to eq(member1)
      end
    end

    describe "Availability monitoring" do
      it "tracks books with low availability" do
        low_availability_books = Book.where('available_copies <= 1')
        expect(low_availability_books).to include(book2) # 0 copies available
        expect(low_availability_books).to include(book3) # 1 copy available
        expect(low_availability_books).not_to include(book1) # 2 copies available
      end

      it "tracks completely unavailable books" do
        unavailable_books = Book.where(available_copies: 0)
        expect(unavailable_books).to include(book2)
         
        unavailable_book = create(:book, total_copies: 3, available_copies: 0)
        expect(Book.where(available_copies: 0)).to include(unavailable_book)
      end
    end

    describe "Performance metrics" do
      it "calculates borrowing rate" do
        total_books = Book.count
        total_borrowings = Borrowing.count
        borrowing_rate = total_borrowings.to_f / total_books
        expect(borrowing_rate).to eq(1.0) # 3 borrowings / 3 books
      end

      it "calculates return rate" do
        total_borrowings = Borrowing.count
        returned_borrowings = Borrowing.returned.count
        return_rate = returned_borrowings.to_f / total_borrowings
        expect(return_rate).to eq(1.0/3.0) # 1 returned / 3 total
      end

      it "calculates overdue rate" do
        total_borrowings = Borrowing.count
        overdue_borrowings = Borrowing.overdue.count
        overdue_rate = overdue_borrowings.to_f / total_borrowings
        expect(overdue_rate).to eq(0.0) # 0 overdue / 3 total
      end
    end
  end
end
