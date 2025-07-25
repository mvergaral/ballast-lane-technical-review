require 'rails_helper'

RSpec.describe BorrowingPolicy, type: :policy do
  subject { described_class }

  let(:librarian) { create(:user, :librarian) }
  let(:member) { create(:user, :member) }
  let(:other_member) { create(:user, :member) }
  let(:borrowing) { create(:borrowing, user: member) }
  let(:other_borrowing) { create(:borrowing, user: other_member) }

  permissions :index? do
    it "allows access to all users" do
      expect(subject).to permit(librarian, Borrowing)
      expect(subject).to permit(member, Borrowing)
    end
  end

  permissions :show? do
    it "allows librarians to see any borrowing" do
      expect(subject).to permit(librarian, borrowing)
      expect(subject).to permit(librarian, other_borrowing)
    end

    it "allows members to see their own borrowings" do
      expect(subject).to permit(member, borrowing)
    end

    it "denies members access to other users' borrowings" do
      expect(subject).not_to permit(member, other_borrowing)
    end
  end

  permissions :create? do
    it "allows access to members" do
      expect(subject).to permit(member, Borrowing)
    end

    it "denies access to librarians" do
      expect(subject).not_to permit(librarian, Borrowing)
    end
  end

  permissions :update? do
    it "allows access to librarians" do
      expect(subject).to permit(librarian, borrowing)
    end

    it "denies access to members" do
      expect(subject).not_to permit(member, borrowing)
    end
  end

  permissions :destroy? do
    it "allows access to librarians" do
      expect(subject).to permit(librarian, borrowing)
    end

    it "denies access to members" do
      expect(subject).not_to permit(member, borrowing)
    end
  end

  permissions :return? do
    it "allows access to librarians" do
      expect(subject).to permit(librarian, borrowing)
    end

    it "denies access to members" do
      expect(subject).not_to permit(member, borrowing)
    end
  end

  describe "Scope" do
    let!(:librarian_borrowings) { create_list(:borrowing, 2, user: librarian) }
    let!(:member_borrowings) { create_list(:borrowing, 2, user: member) }
    let!(:other_borrowings) { create_list(:borrowing, 2, user: other_member) }

    context "for librarians" do
      let(:scope) { Pundit.policy_scope(librarian, Borrowing) }

      it "returns all borrowings" do
        expect(scope.count).to eq(6)
        expect(scope).to include(*librarian_borrowings, *member_borrowings, *other_borrowings)
      end
    end

    context "for members" do
      let(:scope) { Pundit.policy_scope(member, Borrowing) }

      it "returns only their own borrowings" do
        expect(scope.count).to eq(2)
        expect(scope).to include(*member_borrowings)
        expect(scope).not_to include(*librarian_borrowings, *other_borrowings)
      end
    end

    context "for other members" do
      let(:scope) { Pundit.policy_scope(other_member, Borrowing) }

      it "returns only their own borrowings" do
        expect(scope.count).to eq(2)
        expect(scope).to include(*other_borrowings)
        expect(scope).not_to include(*librarian_borrowings, *member_borrowings)
      end
    end
  end
end 