require 'cosmos/moon'

FactoryGirl.define do
  factory :moon, class: Cosmos::Moon do
  end

  factory :moon1, parent: :moon do
    name     'moon1'

    association :location, factory: :moon1_location, :strategy => :build
  end
end
