require 'factory_girl'

FactoryGirl.define do
  factory :user, :aliases => [:owner, :modifier, :actor] do
    sequence(:username) { |n| "user#{n + FACTORY_GIRL_SEQUENCE_OFFSET}" }
    password 'password'
    first_name {Faker::Name.first_name}
    last_name {Faker::Name.last_name}
    title 'Chief Data Scientist'
    dept 'Corporation Corp., Inc.'
    notes 'One of our top performers'
    email {Faker::Internet.email(first_name)}
  end

  factory :admin, :parent => :user do
    sequence(:first_name) { |n| "Admin_#{n + FACTORY_GIRL_SEQUENCE_OFFSET}" }
    sequence(:last_name) { |n| "User_#{n + FACTORY_GIRL_SEQUENCE_OFFSET}" }
    admin true
  end
end