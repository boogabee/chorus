require 'factory_girl'

FactoryGirl.define do
  factory :tag do
    sequence(:name) { |n| "tag#{n}" }
  end

  factory :tagging do
    association :entity, :factory => :workfile
    association :tag, :factory => :tag
  end
end