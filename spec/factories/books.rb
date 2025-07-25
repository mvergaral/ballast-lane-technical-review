FactoryBot.define do
  factory :book do
    sequence(:title) { |n| "Book Title #{n}" }
    sequence(:author) { |n| "Author #{n}" }
    sequence(:genre) { |n| "Genre #{n}" }
    sequence(:isbn) { |n| sprintf("%013d", n) }
    total_copies { rand(1..10) }
    available_copies { total_copies }

    trait :with_borrowings do
      after(:create) do |book|
        create_list(:borrowing, rand(1..3), book: book)
      end
    end

    trait :unavailable do
      available_copies { 0 }
    end

    trait :with_custom_copies do
      transient do
        copies { 5 }
      end
      
      total_copies { copies }
      available_copies { copies }
    end
  end
end
