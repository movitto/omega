require 'manufactured/ship'

FactoryGirl.define do
  factory :server_ship, class: Manufactured::Ship do
    after(:build) { |sh| 
      FactoryGirl.build(sh.system_name.intern)
      sh.solar_system = Cosmos::Registry.instance.find_entity(:name => sh.system_name)
      unless Manufactured::Registry.instance.has_child?(sh.id)
        Manufactured::Registry.instance.create(sh)
      end
    }
  end

  factory :ship1, parent: :server_ship do
    id      'ship1'
    user_id 'user1'
    system_name 'sys1'
    type    :destroyer

    association :location, factory: :ship1_location, :strategy => :build
  end

  factory :ship2, parent: :server_ship do
    id      'ship2'
    user_id 'user1'
    system_name 'sys1'
    type    :mining

    association :location, factory: :ship2_location, :strategy => :build

    after(:build) { |sh| sh.add_resource('metal-alluminum', 50) }
  end

  factory :ship3, parent: :server_ship do
    id      'ship3'
    user_id 'user2'
    type    :mining
    system_name 'sys1'

    association :location, factory: :ship3_location, :strategy => :build
  end

  factory :ship4, parent: :server_ship do
    id      'ship4'
    user_id 'user1'
    system_name 'sys1'
    type :corvette

    association :location, factory: :ship4_location, :strategy => :build
  end

  factory :ship5, parent: :server_ship do
    id      'ship5'
    user_id 'user2'
    system_name 'sys1'

    association :location, factory: :ship5_location, :strategy => :build
  end

  factory :ship6, parent: :server_ship do
    id      'ship6'
    user_id 'user2'
    system_name 'sys1'
    type    :mining

    association :location, factory: :ship6_location, :strategy => :build
    after(:build) { |sh| sh.add_resource('metal-steel', 100) }
  end

  factory :ship7, parent: :server_ship do
    id      'ship7'
    user_id 'user2'
    system_name 'sys1'
    type    :mining

    association :location, factory: :ship7_location, :strategy => :build
  end

end
