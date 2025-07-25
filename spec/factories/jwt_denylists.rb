FactoryBot.define do
  factory :jwt_denylist do
    jti { "MyString" }
    exp { "2025-07-24 12:21:13" }
  end
end
