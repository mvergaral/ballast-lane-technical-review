require 'rails_helper'

RSpec.describe BorrowingSerializer, type: :serializer do
  let(:borrowing) { create(:borrowing) }
  let(:serializer) { described_class.new(borrowing) }
  let(:serialization) { ActiveModelSerializers::Adapter.create(serializer) }

  describe 'attributes' do
    let(:json) { JSON.parse(serialization.to_json) }

    it 'includes all required attributes' do
      expect(json['id']).to eq(borrowing.id)
      expect(json['borrowed_at']).to be_present
      expect(json['due_date']).to be_present
      expect(json['returned_at']).to be_nil
    end

    it 'includes calculated attributes' do
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

    it 'does not include user association to avoid circular references' do
      expect(json['user']).to be_nil
    end

    it 'does not include book association to avoid circular references' do
      expect(json['book']).to be_nil
    end
  end

  describe 'custom methods' do
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
      let(:borrowing) { create(:borrowing) }
      let(:json) { JSON.parse(serialization.to_json) }

      it 'returns correct active?' do
        expect(json['active?']).to be true
      end

      it 'returns correct overdue?' do
        expect(json['overdue?']).to be false
      end

      it 'returns correct days_overdue' do
        expect(json['days_overdue']).to eq(0)
      end

      it 'has nil returned_at' do
        expect(json['returned_at']).to be_nil
      end
    end

    context 'when borrowing is overdue' do
      let(:borrowing) { create(:borrowing, borrowed_at: 3.weeks.ago, due_date: 1.week.ago) }
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
      let(:borrowing) { create(:borrowing, returned_at: Time.current) }
      let(:json) { JSON.parse(serialization.to_json) }

      it 'returns correct active?' do
        expect(json['active?']).to be false
      end

      it 'returns correct overdue?' do
        expect(json['overdue?']).to be false
      end

      it 'returns correct days_overdue' do
        expect(json['days_overdue']).to eq(0)
      end

      it 'has returned_at timestamp' do
        expect(json['returned_at']).to be_present
      end
    end

    context 'when borrowing is overdue and returned' do
      let(:borrowing) { create(:borrowing, borrowed_at: 3.weeks.ago, due_date: 1.week.ago, returned_at: Time.current) }
      let(:json) { JSON.parse(serialization.to_json) }

      it 'returns correct active?' do
        expect(json['active?']).to be false
      end

      it 'returns correct overdue?' do
        expect(json['overdue?']).to be false
      end

      it 'returns correct days_overdue' do
        expect(json['days_overdue']).to eq(0)
      end
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
end 