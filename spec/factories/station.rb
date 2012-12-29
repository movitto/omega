require 'manufactured/registry'
require 'manufactured/station'

FactoryGirl.define do
  factory :server_station, class: Manufactured::Station do
    after(:build) { |st| 
      FactoryGirl.build(st.system_name.intern)
      st.solar_system = Cosmos::Registry.instance.find_entity(:name => st.system_name)
      unless Manufactured::Registry.instance.has_child?(st.id)
        Manufactured::Registry.instance.create(st)
      end
    }
  end

  factory :station1, parent: :server_station do
    id      'station1'
    user_id 'omega-test'
    system_name 'sys1'

    association :location, factory: :station1_location, :strategy => :build
  end

  factory :station2, parent: :server_station do
    id      'station2'
    user_id 'omega-test'
    system_name 'sys2'

    association :location, factory: :station2_location, :strategy => :build
  end

  factory :station3, parent: :server_station do
    id      'station3'
    user_id 'omega-test'
    type    :manufacturing
    system_name 'sys1'

    association :location, factory: :station3_location, :strategy => :build

    after(:build) { |st| st.add_resource('metal-rock', 300) }
  end

  factory :station4, parent: :server_station do
    id      'station4'
    user_id 'user2'
    system_name 'sys1'

    association :location, factory: :station4_location, :strategy => :build
  end

  factory :station5, parent: :server_station do
    id      'station5'
    user_id 'user2'
    system_name 'sys1'

    association :location, factory: :station5_location, :strategy => :build
  end

  factory :station6, parent: :server_station do
    id      'station6'
    user_id 'user2'
    system_name 'sys1'

    association :location, factory: :station6_location, :strategy => :build
  end

  factory :station7, parent: :server_station do
    id      'station7'
    user_id 'test-user'
    system_name 'sys2'

    association :location, factory: :station7_location, :strategy => :build
  end
end
