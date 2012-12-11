require 'cosmos/planet'

FactoryGirl.define do
  factory :planet, class: Cosmos::Planet do
  end

  factory :planet1, parent: :planet do
    name     'planet'
    size      35
    color    'AABBCC'

    association :location, factory: :planet1_location, :strategy => :build
  end
end
