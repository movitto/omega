require 'users/alliance'

FactoryGirl.define do
  factory :alliance, class: Users::Alliance do
  end

  factory :user1_alliance, class: Users::Alliance do
  end

  factory :user2_alliance, class: Users::Alliance do
  end
end
