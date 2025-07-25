require 'rails_helper'

class DummyUserSerializer < ActiveModel::Serializer
  include UserMethods
end

RSpec.describe UserMethods, type: :concern do
  let(:user) { create(:user, :member) }
  let(:serializer) { DummyUserSerializer.new(user) }

  describe 'concern inclusion' do
    it 'can be included in serializers' do
      expect(DummyUserSerializer.included_modules).to include(UserMethods)
    end

    it 'adds the expected methods' do
      expect(serializer).to respond_to(:librarian?)
      expect(serializer).to respond_to(:member?)
    end
  end

  describe '#librarian?' do
    it 'delegates to the user object' do
      expect(user).to receive(:librarian?)
      serializer.librarian?
    end

    it 'returns the same value as the user object' do
      expect(serializer.librarian?).to eq(user.librarian?)
    end

    context 'when user is a librarian' do
      let(:user) { create(:user, :librarian) }

      it 'returns true' do
        expect(serializer.librarian?).to be true
      end
    end

    context 'when user is a member' do
      let(:user) { create(:user, :member) }

      it 'returns false' do
        expect(serializer.librarian?).to be false
      end
    end
  end

  describe '#member?' do
    it 'delegates to the user object' do
      expect(user).to receive(:member?)
      serializer.member?
    end

    it 'returns the same value as the user object' do
      expect(serializer.member?).to eq(user.member?)
    end

    context 'when user is a member' do
      let(:user) { create(:user, :member) }

      it 'returns true' do
        expect(serializer.member?).to be true
      end
    end

    context 'when user is a librarian' do
      let(:user) { create(:user, :librarian) }

      it 'returns false' do
        expect(serializer.member?).to be false
      end
    end
  end

  describe 'method consistency' do
    it 'all methods return consistent values with the model' do
      expect(serializer.librarian?).to eq(user.librarian?)
      expect(serializer.member?).to eq(user.member?)
    end

    it 'librarian? and member? are mutually exclusive' do
      expect(serializer.librarian? && serializer.member?).to be false
    end

    it 'at least one role method returns true' do
      expect(serializer.librarian? || serializer.member?).to be true
    end
  end

  describe 'role validation' do
    context 'with librarian role' do
      let(:user) { create(:user, :librarian) }

      it 'has correct boolean values' do
        expect(serializer.librarian?).to be true
        expect(serializer.member?).to be false
      end
    end

    context 'with member role' do
      let(:user) { create(:user, :member) }

      it 'has correct boolean values' do
        expect(serializer.librarian?).to be false
        expect(serializer.member?).to be true
      end
    end
  end
end 