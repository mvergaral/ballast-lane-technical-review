require 'rails_helper'

RSpec.describe BookPolicy, type: :policy do
  subject { described_class }

  let(:librarian) { create(:user, :librarian) }
  let(:member) { create(:user, :member) }
  let(:book) { create(:book) }

  before(:each) { Book.destroy_all }

  permissions :index? do
    it "allows access to all users" do
      expect(subject).to permit(librarian, Book)
      expect(subject).to permit(member, Book)
    end
  end

  permissions :show? do
    it "allows access to all users" do
      expect(subject).to permit(librarian, book)
      expect(subject).to permit(member, book)
    end
  end

  permissions :create? do
    it "allows access to librarians" do
      expect(subject).to permit(librarian, Book)
    end

    it "denies access to members" do
      expect(subject).not_to permit(member, Book)
    end
  end

  permissions :update? do
    it "allows access to librarians" do
      expect(subject).to permit(librarian, book)
    end

    it "denies access to members" do
      expect(subject).not_to permit(member, book)
    end
  end

  permissions :destroy? do
    it "allows access to librarians" do
      expect(subject).to permit(librarian, book)
    end

    it "denies access to members" do
      expect(subject).not_to permit(member, book)
    end
  end

  permissions :search? do
    it "allows access to all users" do
      expect(subject).to permit(librarian, Book)
      expect(subject).to permit(member, Book)
    end
  end

  describe "Scope" do
    let!(:books) { create_list(:book, 3) }
    let(:scope) { Pundit.policy_scope(librarian, Book) }

    it "returns all books" do
      expect(scope.count).to eq(3)
      expect(scope).to include(*books)
    end

    it "returns same scope for members" do
      member_scope = Pundit.policy_scope(member, Book)
      expect(member_scope.count).to eq(3)
      expect(member_scope).to include(*books)
    end
  end
end 