require 'cosmos/star'

FactoryGirl.define do
  factory :star, class: Cosmos::Star do
  end

  factory :star1, parent: :star do
    name     'star1'
    size      50
    color     Cosmos::Star::STAR_COLORS.first

    association :location, factory: :star1_location, :strategy => :build
  end
end
