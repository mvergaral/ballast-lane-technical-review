require 'rails_helper'

RSpec.describe ApplicationPolicy, type: :policy do
  subject { described_class }
  
  let(:user) { create(:user, :member) }
  let(:librarian) { create(:user, :librarian) }
  let(:record) { create(:book) }

  describe 'initialization' do
    it 'sets user and record attributes' do
      policy = ApplicationPolicy.new(user, record)
      
      expect(policy.user).to eq(user)
      expect(policy.record).to eq(record)
    end

    it 'works with nil user' do
      policy = ApplicationPolicy.new(nil, record)
      
      expect(policy.user).to be_nil
      expect(policy.record).to eq(record)
    end

    it 'works with nil record' do
      policy = ApplicationPolicy.new(user, nil)
      
      expect(policy.user).to eq(user)
      expect(policy.record).to be_nil
    end
  end

  describe 'default permissions' do
    let(:policy) { ApplicationPolicy.new(user, record) }

    describe '#index?' do
      it 'returns false by default' do
        expect(policy.index?).to be false
      end
    end

    describe '#show?' do
      it 'returns false by default' do
        expect(policy.show?).to be false
      end
    end

    describe '#create?' do
      it 'returns false by default' do
        expect(policy.create?).to be false
      end
    end

    describe '#new?' do
      it 'delegates to create?' do
        expect(policy.new?).to eq(policy.create?)
        expect(policy.new?).to be false
      end
    end

    describe '#update?' do
      it 'returns false by default' do
        expect(policy.update?).to be false
      end
    end

    describe '#edit?' do
      it 'delegates to update?' do
        expect(policy.edit?).to eq(policy.update?)
        expect(policy.edit?).to be false
      end
    end

    describe '#destroy?' do
      it 'returns false by default' do
        expect(policy.destroy?).to be false
      end
    end
  end

  describe 'with different users' do
    context 'when user is a member' do
      let(:policy) { ApplicationPolicy.new(user, record) }

      it 'denies all actions by default' do
        expect(policy.index?).to be false
        expect(policy.show?).to be false
        expect(policy.create?).to be false
        expect(policy.update?).to be false
        expect(policy.destroy?).to be false
      end
    end

    context 'when user is a librarian' do
      let(:policy) { ApplicationPolicy.new(librarian, record) }

      it 'denies all actions by default' do
        expect(policy.index?).to be false
        expect(policy.show?).to be false
        expect(policy.create?).to be false
        expect(policy.update?).to be false
        expect(policy.destroy?).to be false
      end
    end

    context 'when user is nil' do
      let(:policy) { ApplicationPolicy.new(nil, record) }

      it 'denies all actions by default' do
        expect(policy.index?).to be false
        expect(policy.show?).to be false
        expect(policy.create?).to be false
        expect(policy.update?).to be false
        expect(policy.destroy?).to be false
      end
    end
  end

  describe 'method consistency' do
    let(:policy) { ApplicationPolicy.new(user, record) }

    it 'new? always returns same as create?' do
      expect(policy.new?).to eq(policy.create?)
    end

    it 'edit? always returns same as update?' do
      expect(policy.edit?).to eq(policy.update?)
    end
  end

  describe ApplicationPolicy::Scope do
    let(:scope) { double('scope') }
    let(:policy_scope) { ApplicationPolicy::Scope.new(user, scope) }

    describe 'initialization' do
      it 'sets user and scope attributes' do
        expect(policy_scope.send(:user)).to eq(user)
        expect(policy_scope.send(:scope)).to eq(scope)
      end

      it 'works with nil user' do
        nil_scope = ApplicationPolicy::Scope.new(nil, scope)
        expect(nil_scope.send(:user)).to be_nil
        expect(nil_scope.send(:scope)).to eq(scope)
      end
    end

    describe '#resolve' do
      it 'raises NoMethodError with descriptive message' do
        expect { policy_scope.resolve }.to raise_error(
          NoMethodError, 
          /You must define #resolve in #{ApplicationPolicy::Scope}/
        )
      end

      it 'includes the specific class name in error message' do
        expect { policy_scope.resolve }.to raise_error(
          NoMethodError, 
          /ApplicationPolicy::Scope/
        )
      end
    end

    describe 'private attribute readers' do
      it 'has private user attribute reader' do
        expect(policy_scope.private_methods).to include(:user)
      end

      it 'has private scope attribute reader' do
        expect(policy_scope.private_methods).to include(:scope)
      end

      it 'does not expose user as public method' do
        expect(policy_scope.public_methods).not_to include(:user)
      end

      it 'does not expose scope as public method' do
        expect(policy_scope.public_methods).not_to include(:scope)
      end
    end
  end

  describe 'inheritance behavior' do
    # Test that subclasses can override the default behavior
    let(:custom_policy_class) do
      Class.new(ApplicationPolicy) do
        def index?
          true
        end

        def show?
          user&.librarian?
        end
      end
    end

    let(:custom_policy) { custom_policy_class.new(user, record) }
    let(:custom_librarian_policy) { custom_policy_class.new(librarian, record) }

    it 'allows subclasses to override default false behavior' do
      expect(custom_policy.index?).to be true
      expect(custom_policy.show?).to be false # member user
      expect(custom_librarian_policy.show?).to be true # librarian user
    end

    it 'inherits non-overridden methods' do
      expect(custom_policy.create?).to be false
      expect(custom_policy.update?).to be false
      expect(custom_policy.destroy?).to be false
    end

    it 'maintains delegation behavior for new? and edit?' do
      expect(custom_policy.new?).to eq(custom_policy.create?)
      expect(custom_policy.edit?).to eq(custom_policy.update?)
    end
  end

  describe 'edge cases' do
    context 'with different record types' do
      let(:user_record) { create(:user, :member) }
      let(:borrowing_record) { create(:borrowing) }

      it 'works with User record' do
        policy = ApplicationPolicy.new(user, user_record)
        expect(policy.user).to eq(user)
        expect(policy.record).to eq(user_record)
      end

      it 'works with Borrowing record' do
        policy = ApplicationPolicy.new(user, borrowing_record)
        expect(policy.user).to eq(user)
        expect(policy.record).to eq(borrowing_record)
      end

      it 'works with string record' do
        policy = ApplicationPolicy.new(user, 'string_record')
        expect(policy.user).to eq(user)
        expect(policy.record).to eq('string_record')
      end
    end

    context 'with class methods' do
      it 'can be instantiated via new' do
        policy = ApplicationPolicy.new(user, record)
        expect(policy).to be_an_instance_of(ApplicationPolicy)
      end

      it 'has accessible Scope class' do
        expect(ApplicationPolicy::Scope).to be_a(Class)
      end
    end
  end
end 