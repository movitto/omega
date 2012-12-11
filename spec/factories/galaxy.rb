require 'cosmos/galaxy'

FactoryGirl.define do
  factory :galaxy, class: Cosmos::Galaxy do
  end

  factory :gal1, parent: :galaxy do
    name     'gal1'

    association :location, factory: :gal1_location, :strategy => :build
  end
end
