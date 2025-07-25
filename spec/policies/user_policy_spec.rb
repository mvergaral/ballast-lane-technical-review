require 'rails_helper'

RSpec.describe UserPolicy, type: :policy do
  subject { described_class }

  let(:librarian) { create(:user, :librarian) }
  let(:member) { create(:user, :member) }
  let(:other_member) { create(:user, :member) }
  let(:other_librarian) { create(:user, :librarian) }

  permissions :index? do
    it "allows access to librarians" do
      expect(subject).to permit(librarian, User)
    end

    it "denies access to members" do
      expect(subject).not_to permit(member, User)
    end
  end

  permissions :show? do
    context "when user is a librarian" do
      it "allows librarian to view any user" do
        expect(subject).to permit(librarian, member)
        expect(subject).to permit(librarian, other_librarian)
        expect(subject).to permit(librarian, librarian)
      end
    end

    context "when user is a member" do
      it "allows member to view their own profile" do
        expect(subject).to permit(member, member)
      end

      it "denies member access to other users" do
        expect(subject).not_to permit(member, other_member)
        expect(subject).not_to permit(member, librarian)
      end
    end
  end

  permissions :create? do
    it "allows access to librarians" do
      expect(subject).to permit(librarian, User)
    end

    it "denies access to members" do
      expect(subject).not_to permit(member, User)
    end
  end

  permissions :update? do
    context "when user is a librarian" do
      it "allows librarian to update any user" do
        expect(subject).to permit(librarian, member)
        expect(subject).to permit(librarian, other_librarian)
        expect(subject).to permit(librarian, librarian)
      end
    end

    context "when user is a member" do
      it "allows member to update their own profile" do
        expect(subject).to permit(member, member)
      end

      it "denies member access to update other users" do
        expect(subject).not_to permit(member, other_member)
        expect(subject).not_to permit(member, librarian)
      end
    end
  end

  permissions :destroy? do
    context "when user is a librarian" do
      it "allows librarian to delete other users" do
        expect(subject).to permit(librarian, member)
        expect(subject).to permit(librarian, other_librarian)
      end

      it "prevents librarian from deleting themselves" do
        expect(subject).not_to permit(librarian, librarian)
      end
    end

    context "when user is a member" do
      it "denies member access to delete any user" do
        expect(subject).not_to permit(member, member)
        expect(subject).not_to permit(member, other_member)
        expect(subject).not_to permit(member, librarian)
      end
    end
  end

  describe "UserPolicy::Scope" do
    subject { described_class::Scope }

    context "when user is a librarian" do
      it "returns all users" do
        create_list(:user, 3, :member)
        create_list(:user, 2, :librarian)

        scope = subject.new(librarian, User).resolve
        expect(scope).to eq(User.all)
        expect(scope.count).to eq(6) # 3 members + 2 librarians + 1 original librarian
      end
    end

    context "when user is a member" do
      it "returns no users" do
        create_list(:user, 3, :member)
        create_list(:user, 2, :librarian)

        scope = subject.new(member, User).resolve
        expect(scope).to eq(User.none)
        expect(scope.count).to eq(0)
      end
    end
  end
end
