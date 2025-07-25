require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_many(:borrowings).dependent(:destroy) }
    it { should have_many(:borrowed_books).through(:borrowings).source(:book) }
  end

  describe 'validations' do
    it { should validate_presence_of(:role) }
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should allow_value('user@example.com').for(:email) }
    it { should_not allow_value('invalid-email').for(:email) }
  end

  describe 'enums' do
    it { should define_enum_for(:role).with_values(member: 0, librarian: 1) }
  end

  describe 'scopes' do
    let!(:librarian) { create(:user, :librarian) }
    let!(:member) { create(:user, :member) }

    describe '.librarians' do
      it 'returns only librarians' do
        expect(User.librarians).to include(librarian)
        expect(User.librarians).not_to include(member)
      end
    end

    describe '.members' do
      it 'returns only members' do
        expect(User.members).to include(member)
        expect(User.members).not_to include(librarian)
      end
    end
  end

  describe 'instance methods' do
    let(:user) { create(:user) }

    describe '#librarian?' do
      it 'returns true for librarian' do
        librarian = create(:user, :librarian)
        expect(librarian.librarian?).to be true
      end

      it 'returns false for member' do
        expect(user.librarian?).to be false
      end
    end

    describe '#member?' do
      it 'returns true for member' do
        expect(user.member?).to be true
      end

      it 'returns false for librarian' do
        librarian = create(:user, :librarian)
        expect(librarian.member?).to be false
      end
    end

    describe '#active_borrowings' do
      let!(:active_borrowing) { create(:borrowing, user: user) }
      let!(:returned_borrowing) { create(:borrowing, :returned, user: user) }

      it 'returns only active borrowings' do
        expect(user.active_borrowings).to include(active_borrowing)
        expect(user.active_borrowings).not_to include(returned_borrowing)
      end
    end

    describe '#overdue_borrowings' do
      let!(:overdue_borrowing) { create(:borrowing, :overdue, user: user) }
      let!(:active_borrowing) { create(:borrowing, user: user) }

      it 'returns only overdue borrowings' do
        expect(user.overdue_borrowings).to include(overdue_borrowing)
        expect(user.overdue_borrowings).not_to include(active_borrowing)
      end
    end

    describe '#overdue_books_count' do
      let!(:overdue_borrowing) { create(:borrowing, :overdue, user: user) }
      let!(:active_borrowing) { create(:borrowing, user: user) }

      it 'returns count of overdue books' do
        expect(user.overdue_books_count).to eq(1)
      end
    end
  end

  describe 'devise modules' do
    it 'includes jwt_authenticatable' do
      expect(User.devise_modules).to include(:jwt_authenticatable)
    end
  end
end
