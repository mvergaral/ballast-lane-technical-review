require 'rails_helper'

RSpec.describe BookBorrowingSerializer, type: :serializer do
  let(:user) { create(:user, :member) }
  let(:book) { create(:book, total_copies: 5, available_copies: 3) }
  let(:borrowing) { create(:borrowing, user: user, book: book) }
  let(:serializer) { described_class.new(borrowing) }
  let(:serialization) { ActiveModelSerializers::Adapter.create(serializer) }

  describe 'attributes' do
    let(:json) { JSON.parse(serialization.to_json) }

    it 'includes all required borrowing attributes' do
      expect(json['id']).to eq(borrowing.id)
      expect(json['user_id']).to eq(borrowing.user_id)
      expect(json['borrowed_at']).to be_present
      expect(json['due_date']).to be_present
      expect(json['returned_at']).to be_nil
    end

    it 'includes calculated attributes from BorrowingMethods concern' do
      expect(json['active?']).to be true
      expect(json['overdue?']).to be false
      expect(json['days_overdue']).to eq(0)
    end

    it 'calculates active? correctly' do
      expect(json['active?']).to eq(borrowing.active?)
    end

    it 'calculates overdue? correctly' do
      expect(json['overdue?']).to eq(borrowing.overdue?)
    end

    it 'calculates days_overdue correctly' do
      expect(json['days_overdue']).to eq(borrowing.days_overdue)
    end
  end

  describe 'associations' do
    let(:json) { JSON.parse(serialization.to_json) }

    it 'includes user association with BorrowingUserSerializer' do
      expect(json['user']).to be_present
      expect(json['user']['id']).to eq(user.id)
      expect(json['user']['email']).to eq(user.email)
      expect(json['user']['role']).to eq(user.role)
      expect(json['user']['member?']).to be true
      expect(json['user']['librarian?']).to be false
    end

    it 'includes book association with BorrowingBookSerializer' do
      expect(json['book']).to be_present
      expect(json['book']['id']).to eq(book.id)
      expect(json['book']['title']).to eq(book.title)
      expect(json['book']['author']).to eq(book.author)
      expect(json['book']['available?']).to be true
    end
  end

  describe 'concern inclusion' do
    it 'includes BorrowingMethods concern' do
      expect(described_class.included_modules).to include(BorrowingMethods)
    end

    it 'responds to concern methods' do
      expect(serializer).to respond_to(:active?)
      expect(serializer).to respond_to(:overdue?)
      expect(serializer).to respond_to(:days_overdue)
    end
  end

  describe 'custom methods from concern' do
    describe '#active?' do
      it 'delegates to the borrowing object' do
        expect(serializer.active?).to eq(borrowing.active?)
      end
    end

    describe '#overdue?' do
      it 'delegates to the borrowing object' do
        expect(serializer.overdue?).to eq(borrowing.overdue?)
      end
    end

    describe '#days_overdue' do
      it 'delegates to the borrowing object' do
        expect(serializer.days_overdue).to eq(borrowing.days_overdue)
      end
    end
  end

  describe 'serialization with different borrowing states' do
    context 'when borrowing is active' do
      let(:borrowing) { create(:borrowing, user: user, book: book) }
      let(:json) { JSON.parse(serialization.to_json) }

      it 'returns correct active?' do
        expect(json['active?']).to be true
      end

      it 'returns correct overdue?' do
        expect(json['overdue?']).to be false
      end

      it 'has nil returned_at' do
        expect(json['returned_at']).to be_nil
      end
    end

    context 'when borrowing is overdue' do
      let(:borrowing) { create(:borrowing, user: user, book: book, borrowed_at: 3.weeks.ago, due_date: 1.week.ago) }
      let(:json) { JSON.parse(serialization.to_json) }

      it 'returns correct active?' do
        expect(json['active?']).to be true
      end

      it 'returns correct overdue?' do
        expect(json['overdue?']).to be true
      end

      it 'returns correct days_overdue' do
        expect(json['days_overdue']).to be >= 7
      end
    end

    context 'when borrowing is returned' do
      let(:borrowing) { create(:borrowing, user: user, book: book, returned_at: Time.current) }
      let(:json) { JSON.parse(serialization.to_json) }

      it 'returns correct active?' do
        expect(json['active?']).to be false
      end

      it 'has returned_at timestamp' do
        expect(json['returned_at']).to be_present
      end
    end
  end

  describe 'nested serialization behavior' do
    let(:json) { JSON.parse(serialization.to_json) }

    it 'uses BorrowingUserSerializer for user association' do
      user_json = json['user']
      expect(user_json).to include('librarian?', 'member?')
    end

    it 'uses BorrowingBookSerializer for book association' do
      book_json = json['book']
      expect(book_json).to include('borrowed_copies', 'available?')
    end

    it 'does not include circular references in nested objects' do
      expect(json['user']['borrowings']).to be_nil
      expect(json['book']['borrowings']).to be_nil
    end
  end

  describe 'date formatting' do
    let(:json) { JSON.parse(serialization.to_json) }

    it 'includes borrowed_at as ISO 8601 format' do
      expect(json['borrowed_at']).to match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
    end

    it 'includes due_date as ISO 8601 format' do
      expect(json['due_date']).to match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
    end

    it 'includes returned_at as ISO 8601 format when present' do
      borrowing.update!(returned_at: Time.current)
      json = JSON.parse(serialization.to_json)
      expect(json['returned_at']).to match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
    end
  end

  describe 'collection serialization' do
    it 'can serialize multiple borrowings correctly' do
      books = create_list(:book, 3, total_copies: 5, available_copies: 3)
      borrowings = books.map { |book| create(:borrowing, user: user, book: book) }
      
      collection_json = ActiveModel::Serializer::CollectionSerializer.new(borrowings, serializer: described_class).to_json
      parsed_json = JSON.parse(collection_json)
      
      expect(parsed_json).to be_an(Array)
      expect(parsed_json.length).to eq(3)
      
      parsed_json.each_with_index do |borrowing_json, index|
        expect(borrowing_json['id']).to eq(borrowings[index].id)
        expect(borrowing_json['user']).to be_present
        expect(borrowing_json['book']).to be_present
      end
    end
  end
end 