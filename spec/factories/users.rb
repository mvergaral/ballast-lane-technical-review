FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { 'password123' }
    password_confirmation { 'password123' }
    role { :member }

    trait :librarian do
      role { :librarian }
    end

    trait :member do
      role { :member }
    end

    trait :with_borrowings do
      after(:create) do |user|
        create_list(:borrowing, rand(1..5), user: user)
      end
    end
  end
end
