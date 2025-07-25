require 'rails_helper'

RSpec.describe BookSerializer, type: :serializer do
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

    it 'includes calculated attributes' do
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

  describe 'associations' do
    let!(:borrowings) { create_list(:borrowing, 2, book: book) }
    let(:json) { JSON.parse(serialization.to_json) }

    it 'does not include borrowings association to avoid circular references' do
      expect(json['borrowings']).to be_nil
    end
  end

  describe 'custom methods' do
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

  describe 'serialization with different book states' do
    context 'with no borrowings' do
      let(:book) { create(:book, total_copies: 3, available_copies: 3) }
      let(:json) { JSON.parse(serialization.to_json) }

      it 'returns correct borrowed_copies' do
        expect(json['borrowed_copies']).to eq(0)
      end

      it 'returns correct available?' do
        expect(json['available?']).to be true
      end

      it 'does not include borrowings to avoid circular references' do
        expect(json['borrowings']).to be_nil
      end
    end

    context 'with all copies borrowed' do
      let(:book) { create(:book, total_copies: 2, available_copies: 0) }
      let(:json) { JSON.parse(serialization.to_json) }

      it 'returns correct borrowed_copies' do
        expect(json['borrowed_copies']).to eq(2)
      end

      it 'returns correct available?' do
        expect(json['available?']).to be false
      end
    end
  end
end 