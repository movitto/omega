require 'manufactured/loot'

FactoryGirl.define do
  factory :server_loot, class: Manufactured::Loot do
    after(:build) { |lt| 
      # TODO would like to move the to individual factories but set_loot request quantity > 0
      lt.add_resource('gem-ruby', 100)

      FactoryGirl.build(lt.system_name.intern)
      lt.solar_system = Cosmos::Registry.instance.find_entity(:name => lt.system_name)
      Manufactured::Registry.instance.set_loot(lt)
    }
  end

  factory :loot1, parent: :server_loot do
    id      'loot1'
    system_name 'sys1'
    association :location, factory: :loot1_location, :strategy => :build
  end
end
