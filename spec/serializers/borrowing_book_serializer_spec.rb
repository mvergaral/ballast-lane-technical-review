require 'rails_helper'

RSpec.describe BorrowingBookSerializer, type: :serializer do
  let(:book) { create(:book, total_copies: 5, available_copies: 3) }
  let(:serializer) { described_class.new(book) }
  let(:serialization) { ActiveModelSerializers::Adapter.create(serializer) }

  describe 'attributes' do
    let(:json) { JSON.parse(serialization.to_json) }

    it 'includes all required attributes' do
      expect(json['id']).to eq(book.id)
      expect(json['title']).to eq(book.title)
      expect(json['author']).to eq(book.author)
      expect(json['genre']).to eq(book.genre)
      expect(json['isbn']).to eq(book.isbn)
      expect(json['total_copies']).to eq(book.total_copies)
      expect(json['available_copies']).to eq(book.available_copies)
    end

    it 'includes calculated attributes from BookMethods concern' do
      expect(json['borrowed_copies']).to eq(2) # 5 total - 3 available
      expect(json['available?']).to be true
    end

    it 'calculates borrowed_copies correctly' do
      expect(json['borrowed_copies']).to eq(book.borrowed_copies)
    end

    it 'calculates available? correctly' do
      expect(json['available?']).to eq(book.available?)
    end

    context 'when book is not available' do
      let(:book) { create(:book, total_copies: 5, available_copies: 0) }

      it 'returns false for available?' do
        expect(json['available?']).to be false
      end

      it 'calculates borrowed_copies correctly' do
        expect(json['borrowed_copies']).to eq(5)
      end
    end
  end

  describe 'concern inclusion' do
    it 'includes BookMethods concern' do
      expect(described_class.included_modules).to include(BookMethods)
    end

    it 'responds to concern methods' do
      expect(serializer).to respond_to(:borrowed_copies)
      expect(serializer).to respond_to(:available?)
    end
  end

  describe 'custom methods from concern' do
    describe '#borrowed_copies' do
      it 'delegates to the book object' do
        expect(serializer.borrowed_copies).to eq(book.borrowed_copies)
      end
    end

    describe '#available?' do
      it 'delegates to the book object' do
        expect(serializer.available?).to eq(book.available?)
      end
    end
  end

  describe 'serialization consistency with BookSerializer' do
    let(:book_serializer) { BookSerializer.new(book) }
    let(:book_json) { JSON.parse(ActiveModelSerializers::Adapter.create(book_serializer).to_json) }
    let(:borrowing_book_json) { JSON.parse(serialization.to_json) }

    it 'produces identical output to BookSerializer' do
      expect(borrowing_book_json).to eq(book_json)
    end
  end

  describe 'edge cases' do
    context 'with minimum copies (1 total, 0 available)' do
      let(:book) { create(:book, total_copies: 1, available_copies: 0) }
      let(:json) { JSON.parse(serialization.to_json) }

      it 'handles minimum total copies correctly' do
        expect(json['borrowed_copies']).to eq(1)
        expect(json['available?']).to be false
      end
    end

    context 'with all copies available' do
      let(:book) { create(:book, total_copies: 5, available_copies: 5) }
      let(:json) { JSON.parse(serialization.to_json) }

      it 'handles all available copies' do
        expect(json['borrowed_copies']).to eq(0)
        expect(json['available?']).to be true
      end
    end
  end
end 