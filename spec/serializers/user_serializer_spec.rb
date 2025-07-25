require 'rails_helper'

RSpec.describe UserSerializer, type: :serializer do
  let(:user) { create(:user, :member) }
  let(:serializer) { described_class.new(user) }
  let(:serialization) { ActiveModelSerializers::Adapter.create(serializer) }

  describe 'attributes' do
    let(:json) { JSON.parse(serialization.to_json) }

    it 'includes all required attributes' do
      expect(json['id']).to eq(user.id)
      expect(json['email']).to eq(user.email)
      expect(json['role']).to eq(user.role)
    end

    it 'includes calculated attributes' do
      expect(json['librarian?']).to be false
      expect(json['member?']).to be true
    end

    it 'calculates librarian? correctly' do
      expect(json['librarian?']).to eq(user.librarian?)
    end

    it 'calculates member? correctly' do
      expect(json['member?']).to eq(user.member?)
    end
  end

  describe 'associations' do
    let!(:borrowings) { create_list(:borrowing, 2, user: user) }
    let(:json) { JSON.parse(serialization.to_json) }

    it 'does not include borrowings association to avoid circular references' do
      expect(json['borrowings']).to be_nil
    end
  end

  describe 'custom methods' do
    describe '#librarian?' do
      it 'delegates to the user object' do
        expect(serializer.librarian?).to eq(user.librarian?)
      end
    end

    describe '#member?' do
      it 'delegates to the user object' do
        expect(serializer.member?).to eq(user.member?)
      end
    end
  end

  describe 'serialization with different user roles' do
    context 'when user is a librarian' do
      let(:user) { create(:user, :librarian) }
      let(:json) { JSON.parse(serialization.to_json) }

      it 'returns correct librarian?' do
        expect(json['librarian?']).to be true
      end

      it 'returns correct member?' do
        expect(json['member?']).to be false
      end

      it 'has correct role' do
        expect(json['role']).to eq('librarian')
      end
    end

    context 'when user is a member' do
      let(:user) { create(:user, :member) }
      let(:json) { JSON.parse(serialization.to_json) }

      it 'returns correct librarian?' do
        expect(json['librarian?']).to be false
      end

      it 'returns correct member?' do
        expect(json['member?']).to be true
      end

      it 'has correct role' do
        expect(json['role']).to eq('member')
      end
    end
  end

  describe 'serialization with borrowings' do
    context 'with no borrowings' do
      let(:json) { JSON.parse(serialization.to_json) }

          it 'does not include borrowings to avoid circular references' do
      expect(json['borrowings']).to be_nil
    end
    end

    context 'with multiple borrowings' do
      let!(:active_borrowing) { create(:borrowing, user: user) }
      let!(:returned_borrowing) { create(:borrowing, user: user, returned_at: Time.current) }
      let(:json) { JSON.parse(serialization.to_json) }

      it 'does not include borrowings to avoid circular references' do
        expect(json['borrowings']).to be_nil
      end
    end
  end

  describe 'email formatting' do
    let(:json) { JSON.parse(serialization.to_json) }

    it 'includes email as string' do
      expect(json['email']).to be_a(String)
      expect(json['email']).to match(/^[^@]+@[^@]+\.[^@]+$/)
    end
  end

  describe 'role values' do
    context 'for librarian' do
      let(:user) { create(:user, :librarian) }
      let(:json) { JSON.parse(serialization.to_json) }

      it 'returns role as string' do
        expect(json['role']).to eq('librarian')
      end
    end

    context 'for member' do
      let(:user) { create(:user, :member) }
      let(:json) { JSON.parse(serialization.to_json) }

      it 'returns role as string' do
        expect(json['role']).to eq('member')
      end
    end
  end
end 