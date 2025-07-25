require 'rails_helper'

RSpec.describe Api::DashboardController, type: :controller do
  let(:librarian) { create(:user, :librarian) }
  let(:member) { create(:user, :member) }

  describe 'GET #index' do
    context 'when user is a librarian' do
      before do
        sign_in librarian
        create_list(:book, 5)
        # Create overdue borrowing respecting model validations
        @overdue_borrowing = create(:borrowing, returned_at: nil)
        @overdue_borrowing.update_column(:due_date, 1.week.ago) # Bypass validation
        @recent_borrowing = create(:borrowing, user: member)
      end

      it 'returns librarian dashboard data' do
        get :index
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        
        expect(json_response['role']).to eq('librarian')
        expect(json_response).to have_key('stats')
        expect(json_response).to have_key('overdue_members')
        expect(json_response).to have_key('recent_borrowings')
      end

      it 'includes correct stats for librarian' do
        get :index
        
        json_response = JSON.parse(response.body)
        stats = json_response['stats']
        
        expect(stats['total_books']).to eq(Book.count)
        expect(stats['total_borrowed_books']).to eq(Borrowing.active.count)
        expect(stats['books_due_today']).to eq(Borrowing.due_today.count)
        expect(stats['overdue_books_count']).to eq(Borrowing.overdue.count)
      end

      it 'includes overdue members with user details' do
        get :index
        
        json_response = JSON.parse(response.body)
        overdue_members = json_response['overdue_members']
        
        expect(overdue_members).to be_an(Array)
        if overdue_members.any?
          first_member = overdue_members.first
          expect(first_member).to have_key('id')
          expect(first_member).to have_key('email')
          expect(first_member).to have_key('overdue_count')
        end
      end

      it 'includes recent borrowings with book and user details' do
        get :index
        
        json_response = JSON.parse(response.body)
        recent_borrowings = json_response['recent_borrowings']
        
        expect(recent_borrowings).to be_an(Array)
        if recent_borrowings.any?
          first_borrowing = recent_borrowings.first
          expect(first_borrowing).to have_key('id')
          expect(first_borrowing).to have_key('book_title')
          expect(first_borrowing).to have_key('user_email')
          expect(first_borrowing).to have_key('borrowed_at')
        end
      end

      it 'handles case with no overdue books' do
        Borrowing.destroy_all
        
        get :index
        
        json_response = JSON.parse(response.body)
        expect(json_response['overdue_members']).to eq([])
        expect(json_response['stats']['overdue_books_count']).to eq(0)
      end

      it 'handles case with no borrowings at all' do
        Borrowing.destroy_all
        
        get :index
        
        json_response = JSON.parse(response.body)
        stats = json_response['stats']
        
        expect(stats['total_books']).to eq(Book.count)
        expect(stats['total_borrowed_books']).to eq(0)
        expect(stats['overdue_books_count']).to eq(0)
        expect(json_response['recent_borrowings']).to eq([])
      end
    end

    context 'when user is a member' do
      before do
        sign_in member
        @book = create(:book)
        @borrowing = create(:borrowing, user: member, book: @book, returned_at: nil)
      end

      it 'returns member dashboard data' do
        get :index
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        
        expect(json_response['role']).to eq('member')
        expect(json_response).to have_key('stats')
        expect(json_response).to have_key('my_borrowings')
        expect(json_response).to have_key('my_borrowing_history')
      end

      it 'includes correct stats for member with active borrowings' do
        get :index
        
        json_response = JSON.parse(response.body)
        stats = json_response['stats']
        
        expect(stats['my_borrowed_books']).to eq(1)
        expect(stats['my_books_due_soon']).to be >= 0
        expect(stats['my_overdue_books']).to be >= 0
      end

      it 'includes borrowed books with book details' do
        get :index
        
        json_response = JSON.parse(response.body)
        borrowed_books = json_response['my_borrowings']
        
        expect(borrowed_books).to be_an(Array)
        expect(borrowed_books.length).to eq(1)
        
        first_book = borrowed_books.first
        expect(first_book).to have_key('id')
        expect(first_book).to have_key('book_title')
        expect(first_book).to have_key('book_author')
        expect(first_book).to have_key('due_date')
        expect(first_book).to have_key('is_overdue')
        expect(first_book).to have_key('is_due_soon')
      end

      it 'includes overdue books with book details' do
        # Create and then make it overdue
        @borrowing.update_column(:due_date, 1.week.ago) # Bypass validation
        
        get :index
        
        json_response = JSON.parse(response.body)
        stats = json_response['stats']
        
        expect(stats['my_overdue_books']).to eq(1)
        
        borrowed_books = json_response['my_borrowings']
        overdue_book = borrowed_books.find { |b| b['is_overdue'] }
        expect(overdue_book).to be_present
      end

      it 'handles member with no borrowings' do
        Borrowing.destroy_all
        
        get :index
        
        json_response = JSON.parse(response.body)
        stats = json_response['stats']
        
        expect(stats['my_borrowed_books']).to eq(0)
        expect(stats['my_books_due_soon']).to eq(0)
        expect(stats['my_overdue_books']).to eq(0)
        expect(json_response['my_borrowings']).to eq([])
      end

      it 'handles member with multiple borrowings' do
        create(:borrowing, user: member, returned_at: nil)
        # Create and then make it overdue
        overdue_borrowing = create(:borrowing, user: member, returned_at: nil)
        overdue_borrowing.update_column(:due_date, 1.week.ago) # Bypass validation
        
        get :index
        
        json_response = JSON.parse(response.body)
        stats = json_response['stats']
        
        expect(stats['my_borrowed_books']).to eq(3) # All active borrowings including overdue
        expect(stats['my_overdue_books']).to eq(1)
      end

      it 'excludes returned books from active borrowings' do
        create(:borrowing, user: member, returned_at: 1.day.ago)
        
        get :index
        
        json_response = JSON.parse(response.body)
        stats = json_response['stats']
        
        expect(stats['my_borrowed_books']).to eq(1) # Only active borrowings
        expect(json_response['my_borrowings'].length).to eq(1)
      end
    end
  end

  describe 'authorization' do
    it 'requires authentication' do
      get :index
      
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'edge cases' do
    context 'when database has no data' do
      before do
        Book.destroy_all
        Borrowing.destroy_all
        sign_in librarian
      end

      it 'handles empty database gracefully for librarian' do
        get :index
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        
        stats = json_response['stats']
        expect(stats['total_books']).to eq(0)
        expect(stats['total_borrowed_books']).to eq(0)
        expect(stats['books_due_today']).to eq(0)
        expect(stats['overdue_books_count']).to eq(0)
        expect(json_response['overdue_members']).to eq([])
        expect(json_response['recent_borrowings']).to eq([])
      end
    end

    context 'when user has mixed borrowing states' do
      before do
        sign_in member
        @active_borrowing = create(:borrowing, user: member, returned_at: nil)
        @overdue_borrowing = create(:borrowing, user: member, returned_at: nil)
        @overdue_borrowing.update_column(:due_date, 1.week.ago) # Bypass validation
      end

      it 'correctly categorizes different borrowing states' do
        get :index
        
        json_response = JSON.parse(response.body)
        stats = json_response['stats']
        
        # Active borrowings include overdue ones
        expect(stats['my_borrowed_books']).to eq(2)
        expect(stats['my_overdue_books']).to eq(1)
        expect(json_response['my_borrowings'].length).to eq(2)
      end
    end
  end
end 