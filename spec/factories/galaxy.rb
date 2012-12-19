require 'cosmos/registry'
require 'cosmos/galaxy'

FactoryGirl.define do
  factory :server_galaxy, class: Cosmos::Galaxy do
    after(:build) { |g|
      unless Cosmos::Registry.instance.has_child?(g.name)
        Cosmos::Registry.instance.add_child(g)
      end
    }
  end

  factory :gal1, parent: :server_galaxy do
    name     'gal1'

    association :location, factory: :gal1_location, :strategy => :build
  end
end
