require 'cosmos/registry'
require 'cosmos/galaxy'

FactoryGirl.define do
  factory :galaxy, class: Cosmos::Galaxy do
    after(:build) { |g|
      unless Cosmos::Registry.instance.has_child?(g.name)
        Cosmos::Registry.instance.add_child(g)
      end
    }
  end

  factory :gal1, parent: :galaxy do
    name     'gal1'

    association :location, factory: :gal1_location, :strategy => :build
  end
end
