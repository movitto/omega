require 'manufactured/ship'

FactoryGirl.define do
  factory :ship, class: Manufactured::Ship do
    after(:build) { |sh| 
      FactoryGirl.build(sh.system_name.intern)
      sh.solar_system = Cosmos::Registry.instance.find_entity(:name => sh.system_name)
      Manufactured::Registry.instance.create(sh)
    }
  end

  factory :ship1, parent: :ship do
    id      'ship1'
    user_id 'user1'
    system_name 'sys1'

    association :location, factory: :ship1_location, :strategy => :build
  end

  factory :ship2, parent: :ship do
    id      'ship2'
    user_id 'user1'
    system_name 'sys1'
    type    :mining

    association :location, factory: :ship2_location, :strategy => :build

    after(:build) { |sh| sh.add_resource('metal-alluminum', 50) }
  end

  factory :ship3, parent: :ship do
    id      'ship3'
    user_id 'user2'
    type    :mining
    system_name 'sys1'

    association :location, factory: :ship3_location, :strategy => :build
  end

  factory :ship4, parent: :ship do
    id      'ship4'
    user_id 'user1'
    system_name 'sys1'
    type :corvette

    association :location, factory: :ship4_location, :strategy => :build
  end

  factory :ship5, parent: :ship do
    id      'ship5'
    user_id 'user2'
    system_name 'sys1'

    association :location, factory: :ship5_location, :strategy => :build
  end

end
