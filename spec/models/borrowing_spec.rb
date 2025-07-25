require 'rails_helper'

RSpec.describe Borrowing, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:book) }
  end

  describe 'validations' do
    it 'validates that borrowed_at and due_date are set by callbacks' do
      borrowing = build(:borrowing, borrowed_at: nil, due_date: nil)
      borrowing.save!
      expect(borrowing.borrowed_at).to be_present
      expect(borrowing.due_date).to be_present
    end
  end

  describe 'scopes' do
    let!(:active_borrowing) { create(:borrowing) }
    let!(:returned_borrowing) { create(:borrowing, :returned) }
    let!(:overdue_borrowing) { create(:borrowing, :overdue) }
    let!(:due_today_borrowing) { create(:borrowing, :due_today) }

    describe '.active' do
      it 'returns only active borrowings' do
        expect(Borrowing.active).to include(active_borrowing, overdue_borrowing, due_today_borrowing)
        expect(Borrowing.active).not_to include(returned_borrowing)
      end
    end

    describe '.returned' do
      it 'returns only returned borrowings' do
        expect(Borrowing.returned).to include(returned_borrowing)
        expect(Borrowing.returned).not_to include(active_borrowing, overdue_borrowing, due_today_borrowing)
      end
    end

    describe '.overdue' do
      it 'returns only overdue borrowings' do
        expect(Borrowing.overdue).to include(overdue_borrowing)
        expect(Borrowing.overdue).not_to include(active_borrowing, returned_borrowing, due_today_borrowing)
      end
    end

    describe '.due_today' do
      it 'returns borrowings due today' do
        expect(Borrowing.due_today).to include(due_today_borrowing)
        expect(Borrowing.due_today).not_to include(active_borrowing, returned_borrowing, overdue_borrowing)
      end
    end

    describe '.due_this_week' do
      it 'returns borrowings due this week' do
        expect(Borrowing.due_this_week).to include(due_today_borrowing)
        expect(Borrowing.due_this_week).not_to include(returned_borrowing, overdue_borrowing)
      end
    end
  end

  describe 'instance methods' do
    let(:borrowing) { create(:borrowing) }

    describe '#active?' do
      it 'returns true when not returned' do
        expect(borrowing.active?).to be true
      end

      it 'returns false when returned' do
        borrowing.update!(returned_at: Time.current)
        expect(borrowing.active?).to be false
      end
    end

    describe '#overdue?' do
      it 'returns true when overdue' do
        borrowing.update!(borrowed_at: 4.days.ago, due_date: 1.day.ago)
        expect(borrowing.overdue?).to be true
      end

      it 'returns false when not overdue' do
        expect(borrowing.overdue?).to be false
      end

      it 'returns false when returned' do
        borrowing.update!(borrowed_at: 4.days.ago, due_date: 1.day.ago, returned_at: Time.current)
        expect(borrowing.overdue?).to be false
      end

      it 'returns false when due date is in the future' do
        borrowing.update!(borrowed_at: 1.day.ago, due_date: 1.day.from_now)
        expect(borrowing.overdue?).to be false
      end
    end

    describe '#days_overdue' do
      it 'returns 0 when not overdue' do
        expect(borrowing.days_overdue).to eq(0)
      end

      it 'returns correct number of days when overdue' do
        borrowing.update!(borrowed_at: 5.days.ago, due_date: 3.days.ago)
        expect(borrowing.days_overdue).to eq(3)
      end

      it 'returns 0 when returned' do
        borrowing.update!(borrowed_at: 5.days.ago, due_date: 3.days.ago, returned_at: Time.current)
        expect(borrowing.days_overdue).to eq(0)
      end

      it 'returns 0 when due date is today' do
        borrowing.update!(borrowed_at: 1.week.ago, due_date: Date.current.end_of_day)
        expect(borrowing.days_overdue).to eq(0)
      end
    end

    describe '#return!' do
      it 'sets returned_at to current time' do
        expect { borrowing.return! }.to change { borrowing.reload.returned_at }.from(nil)
      end

      it 'returns true when successful' do
        expect(borrowing.return!).to be true
      end

      it 'returns false when already returned' do
        borrowing.update!(returned_at: Time.current)
        expect(borrowing.return!).to be false
      end

      it 'does not change returned_at when already returned' do
        original_returned_at = Time.current
        borrowing.update!(returned_at: original_returned_at)
        expect { borrowing.return! }.not_to change { borrowing.reload.returned_at }
      end
    end
  end

  describe 'callbacks' do
    describe 'before_validation' do
      it 'sets borrowed_at and due_date when not provided' do
        borrowing = create(:borrowing)
        
        expect(borrowing.borrowed_at).to be_present
        expect(borrowing.due_date).to be_present
        expect(borrowing.due_date).to be_within(1.second).of(borrowing.borrowed_at + 2.weeks)
      end

      it 'does not override provided dates' do
        custom_borrowed_at = 1.week.ago
        custom_due_date = 1.week.from_now
        borrowing = create(:borrowing, borrowed_at: custom_borrowed_at, due_date: custom_due_date)
        
        expect(borrowing.borrowed_at).to be_within(1.second).of(custom_borrowed_at)
        expect(borrowing.due_date).to be_within(1.second).of(custom_due_date)
      end
    end

    describe 'after_create' do
      it 'updates book availability when borrowing is created' do
        book = create(:book, total_copies: 3, available_copies: 3)
        expect {
          create(:borrowing, book: book)
        }.to change { book.reload.available_copies }.by(-1)
      end
    end

    describe 'before_update' do
      it 'updates book availability when returned_at changes' do
        borrowing = create(:borrowing)
        book = borrowing.book
        initial_copies = book.available_copies
        
        expect {
          borrowing.update!(returned_at: Time.current)
        }.to change { book.reload.available_copies }.by(1)
      end

      it 'does not update book availability when other attributes change' do
        borrowing = create(:borrowing)
        book = borrowing.book
        initial_copies = book.available_copies
        
        expect {
          borrowing.update!(due_date: 3.weeks.from_now)
        }.not_to change { book.reload.available_copies }
      end

      it 'does not update book availability when returned_at is already set' do
        borrowing = create(:borrowing)
        borrowing.update!(returned_at: Time.current)
        book = borrowing.book
        initial_copies = book.available_copies
        
        expect {
          borrowing.update!(returned_at: Time.current + 1.hour)
        }.not_to change { book.reload.available_copies }
      end
    end
  end

  describe 'custom validations' do
    describe 'due_date_after_borrowed_at' do
      it 'adds error when due_date is before borrowed_at' do
        borrowing = build(:borrowing, borrowed_at: 1.day.from_now, due_date: Time.current)
        borrowing.valid?
        expect(borrowing.errors[:due_date]).to include('must be after borrowed date')
      end

      it 'adds error when due_date equals borrowed_at' do
        same_time = Time.current
        borrowing = build(:borrowing, borrowed_at: same_time, due_date: same_time)
        borrowing.valid?
        expect(borrowing.errors[:due_date]).to include('must be after borrowed date')
      end

      it 'does not add error when due_date is after borrowed_at' do
        borrowing = build(:borrowing, borrowed_at: Time.current, due_date: 1.day.from_now)
        borrowing.valid?
        expect(borrowing.errors[:due_date]).to be_empty
      end

      it 'does not validate when dates are not set' do
        borrowing = build(:borrowing, borrowed_at: nil, due_date: nil)
        borrowing.valid?
        expect(borrowing.errors[:due_date]).to be_empty
      end
    end

    describe 'user_cannot_borrow_same_book_twice' do
      let(:user) { create(:user) }
      let(:book) { create(:book) }

      it 'adds error when user already borrowed the book' do
        create(:borrowing, user: user, book: book)
        borrowing = build(:borrowing, user: user, book: book)
        
        borrowing.valid?
        expect(borrowing.errors[:base]).to include('User has already borrowed this book')
      end

      it 'does not add error when user has not borrowed the book' do
        borrowing = build(:borrowing, user: user, book: book)
        borrowing.valid?
        expect(borrowing.errors[:base]).to be_empty
      end

      it 'does not add error when user returned the book' do
        # Crear un borrowing y devolverlo
        borrowing1 = create(:borrowing, user: user, book: book)
        borrowing1.update!(returned_at: Time.current)
        
        # Crear un nuevo borrowing para el mismo usuario y libro
        borrowing2 = build(:borrowing, user: user, book: book)
        
        borrowing2.valid?
        expect(borrowing2.errors[:base]).to be_empty
      end

      it 'does not validate when user or book is not set' do
        borrowing = build(:borrowing, user: nil, book: book)
        borrowing.valid?
        expect(borrowing.errors[:base]).to be_empty
      end
    end

    describe 'book_must_be_available' do
      let(:book) { create(:book, :with_custom_copies, copies: 3) }

      it 'adds error when book is not available' do
        book.update!(available_copies: 0)
        borrowing = build(:borrowing, book: book)
        
        borrowing.valid?
        expect(borrowing.errors[:base]).to include('Book is not available for borrowing')
      end

      it 'does not add error when book is available' do
        borrowing = build(:borrowing, book: book)
        borrowing.valid?
        expect(borrowing.errors[:base]).to be_empty
      end

      it 'does not validate when book is not set' do
        borrowing = build(:borrowing, book: nil)
        borrowing.valid?
        expect(borrowing.errors[:base]).to be_empty
      end
    end
  end

  describe 'private methods' do
    describe '#set_borrowed_at_and_due_date' do
      it 'sets borrowed_at to current time' do
        borrowing = build(:borrowing, borrowed_at: nil, due_date: nil)
        borrowing.send(:set_borrowed_at_and_due_date)
        expect(borrowing.borrowed_at).to be_within(1.second).of(Time.current)
      end

      it 'sets due_date to 2 weeks from borrowed_at' do
        borrowing = build(:borrowing, borrowed_at: nil, due_date: nil)
        borrowing.send(:set_borrowed_at_and_due_date)
        expect(borrowing.due_date).to be_within(1.second).of(borrowing.borrowed_at + 2.weeks)
      end

      it 'does not override existing dates' do
        existing_borrowed_at = 1.week.ago
        existing_due_date = 1.week.from_now
        borrowing = build(:borrowing, borrowed_at: existing_borrowed_at, due_date: existing_due_date)
        
        borrowing.send(:set_borrowed_at_and_due_date)
        expect(borrowing.borrowed_at).to eq(existing_borrowed_at)
        expect(borrowing.due_date).to eq(existing_due_date)
      end
    end

    describe '#update_book_availability_after_return' do
      it 'calls book.return! when returned_at is present and changed' do
        borrowing = create(:borrowing)
        book = borrowing.book
        expect(book).to receive(:return!)
        
        borrowing.update!(returned_at: Time.current)
      end

      it 'does not call book.return! when returned_at is not present' do
        borrowing = create(:borrowing)
        book = borrowing.book
        expect(book).not_to receive(:return!)
        
        borrowing.update!(due_date: 3.weeks.from_now)
      end
    end

    describe '#update_book_availability_on_create' do
      it 'calls book.borrow! when borrowing is created' do
        book = create(:book)
        expect(book).to receive(:borrow!)
        
        create(:borrowing, book: book)
      end
    end
  end
end
