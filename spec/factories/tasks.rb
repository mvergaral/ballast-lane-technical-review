FactoryBot.define do
  factory :task do
    title { "Sample Task" }
    description { "This is a sample task description" }
    status { :pending }
    due_date { Date.current + 1.week }
    association :user

    trait :in_progress do
      status { :in_progress }
    end

    trait :done do
      status { :done }
    end

    trait :overdue do
      due_date { Date.current - 1.day }
    end
  end
end
