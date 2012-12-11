require 'cosmos/asteroid'

FactoryGirl.define do
  factory :asteroid, class: Cosmos::Asteroid do
  end

  factory :asteroid1, parent: :asteroid do
    name     'ast1'
    color    'FFEEDD'
    size      20

    association :location, factory: :ast1_location, :strategy => :build
  end
end
