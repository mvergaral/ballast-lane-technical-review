require 'rails_helper'

class DummyBorrowingSerializer < ActiveModel::Serializer
  include BorrowingMethods
end

RSpec.describe BorrowingMethods, type: :concern do
  let(:borrowing) { create(:borrowing) }
  let(:serializer) { DummyBorrowingSerializer.new(borrowing) }

  describe 'concern inclusion' do
    it 'can be included in serializers' do
      expect(DummyBorrowingSerializer.included_modules).to include(BorrowingMethods)
    end

    it 'adds the expected methods' do
      expect(serializer).to respond_to(:active?)
      expect(serializer).to respond_to(:overdue?)
      expect(serializer).to respond_to(:days_overdue)
    end
  end

  describe '#active?' do
    it 'delegates to the borrowing object' do
      expect(borrowing).to receive(:active?)
      serializer.active?
    end

    it 'returns the same value as the borrowing object' do
      expect(serializer.active?).to eq(borrowing.active?)
    end

    context 'when borrowing is active' do
      let(:borrowing) { create(:borrowing) }

      it 'returns true' do
        expect(serializer.active?).to be true
      end
    end

    context 'when borrowing is returned' do
      let(:borrowing) { create(:borrowing, returned_at: Time.current) }

      it 'returns false' do
        expect(serializer.active?).to be false
      end
    end
  end

  describe '#overdue?' do
    it 'delegates to the borrowing object' do
      expect(borrowing).to receive(:overdue?)
      serializer.overdue?
    end

    it 'returns the same value as the borrowing object' do
      expect(serializer.overdue?).to eq(borrowing.overdue?)
    end

    context 'when borrowing is not overdue' do
      let(:borrowing) { create(:borrowing) }

      it 'returns false' do
        expect(serializer.overdue?).to be false
      end
    end

    context 'when borrowing is overdue' do
      let(:borrowing) { create(:borrowing, borrowed_at: 3.weeks.ago, due_date: 1.week.ago) }

      it 'returns true' do
        expect(serializer.overdue?).to be true
      end
    end

    context 'when borrowing is returned (even if was overdue)' do
      let(:borrowing) { create(:borrowing, borrowed_at: 3.weeks.ago, due_date: 1.week.ago, returned_at: Time.current) }

      it 'returns false' do
        expect(serializer.overdue?).to be false
      end
    end
  end

  describe '#days_overdue' do
    it 'delegates to the borrowing object' do
      expect(borrowing).to receive(:days_overdue)
      serializer.days_overdue
    end

    it 'returns the same value as the borrowing object' do
      expect(serializer.days_overdue).to eq(borrowing.days_overdue)
    end

    context 'when borrowing is not overdue' do
      let(:borrowing) { create(:borrowing) }

      it 'returns 0' do
        expect(serializer.days_overdue).to eq(0)
      end
    end

    context 'when borrowing is overdue' do
      let(:borrowing) { create(:borrowing, borrowed_at: 3.weeks.ago, due_date: 1.week.ago) }

      it 'returns the correct number of days' do
        expect(serializer.days_overdue).to be >= 7
      end
    end

    context 'when borrowing is returned' do
      let(:borrowing) { create(:borrowing, returned_at: Time.current) }

      it 'returns 0' do
        expect(serializer.days_overdue).to eq(0)
      end
    end
  end

  describe 'method consistency' do
    it 'all methods return consistent values with the model' do
      expect(serializer.active?).to eq(borrowing.active?)
      expect(serializer.overdue?).to eq(borrowing.overdue?)
      expect(serializer.days_overdue).to eq(borrowing.days_overdue)
    end
  end
end 