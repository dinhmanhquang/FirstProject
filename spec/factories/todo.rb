FactoryBot.define do
  factory :todo do
    # jitera-anchor-dont-touch: columns
    description { Faker::Lorem.paragraph_by_chars(number: rand(0..1000)) }
    title { Faker::Lorem.paragraph_by_chars(number: rand(0..255)) }
  end
end
