require 'rails_helper'

class DummyBookSerializer < ActiveModel::Serializer
  include BookMethods
end

RSpec.describe BookMethods, type: :concern do
  let(:book) { create(:book, total_copies: 5, available_copies: 3) }
  let(:serializer) { DummyBookSerializer.new(book) }

  describe 'concern inclusion' do
    it 'can be included in serializers' do
      expect(DummyBookSerializer.included_modules).to include(BookMethods)
    end

    it 'adds the expected methods' do
      expect(serializer).to respond_to(:borrowed_copies)
      expect(serializer).to respond_to(:available?)
    end
  end

  describe '#borrowed_copies' do
    it 'delegates to the book object' do
      expect(book).to receive(:borrowed_copies)
      serializer.borrowed_copies
    end

    it 'returns the same value as the book object' do
      expect(serializer.borrowed_copies).to eq(book.borrowed_copies)
    end

    context 'when book has some copies borrowed' do
      let(:book) { create(:book, total_copies: 5, available_copies: 3) }

      it 'returns correct borrowed copies count' do
        expect(serializer.borrowed_copies).to eq(2)
      end
    end

    context 'when book has no copies borrowed' do
      let(:book) { create(:book, total_copies: 3, available_copies: 3) }

      it 'returns 0' do
        expect(serializer.borrowed_copies).to eq(0)
      end
    end

    context 'when all copies are borrowed' do
      let(:book) { create(:book, total_copies: 5, available_copies: 0) }

      it 'returns total copies count' do
        expect(serializer.borrowed_copies).to eq(5)
      end
    end
  end

  describe '#available?' do
    it 'delegates to the book object' do
      expect(book).to receive(:available?)
      serializer.available?
    end

    it 'returns the same value as the book object' do
      expect(serializer.available?).to eq(book.available?)
    end

    context 'when book has available copies' do
      let(:book) { create(:book, total_copies: 5, available_copies: 3) }

      it 'returns true' do
        expect(serializer.available?).to be true
      end
    end

    context 'when book has no available copies' do
      let(:book) { create(:book, total_copies: 5, available_copies: 0) }

      it 'returns false' do
        expect(serializer.available?).to be false
      end
    end

    context 'when book has no available copies' do
      let(:book) { create(:book, total_copies: 5, available_copies: 0) }

      it 'returns false' do
        expect(serializer.available?).to be false
      end
    end
  end

  describe 'method consistency' do
    it 'all methods return consistent values with the model' do
      expect(serializer.borrowed_copies).to eq(book.borrowed_copies)
      expect(serializer.available?).to eq(book.available?)
    end

    it 'borrowed_copies + available_copies equals total_copies' do
      expect(serializer.borrowed_copies + book.available_copies).to eq(book.total_copies)
    end
  end

  describe 'edge cases' do
    context 'with minimum total copies' do
      let(:book) { create(:book, total_copies: 1, available_copies: 1) }

      it 'handles minimum copies correctly' do
        expect(serializer.borrowed_copies).to eq(0)
        expect(serializer.available?).to be true
      end
    end

    context 'with large number of copies' do
      let(:book) { create(:book, total_copies: 100, available_copies: 50) }

      it 'handles large numbers correctly' do
        expect(serializer.borrowed_copies).to eq(50)
        expect(serializer.available?).to be true
      end
    end
  end
end 