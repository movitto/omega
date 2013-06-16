require 'manufactured/ship'

FactoryGirl.define do
  factory 'manufactured/ship' do
    server_entity
    create_method 'manufactured::create_entity'

    factory :ship do
      sequence(:id, 10000) { |n| n.to_s }

      factory :valid_ship do
        user_id 'user1'
        association :solar_system, :strategy => :build
        type :frigate
      end
    end
  end
end

#factory :ship1, parent: :server_ship do
#  id      'ship1'
#  user_id 'user1'
#  system_name 'sys1'
#  type    :destroyer
#
#  association :location, factory: :ship1_location, :strategy => :build
#end
#
#factory :ship2, parent: :server_ship do
#  id      'ship2'
#  user_id 'user1'
#  system_name 'sys1'
#  type    :mining
#
#  association :location, factory: :ship2_location, :strategy => :build
#
#  after(:build) { |sh| sh.add_resource('metal-alluminum', 50) }
#end
#
#factory :ship3, parent: :server_ship do
#  id      'ship3'
#  user_id 'user2'
#  type    :mining
#  system_name 'sys1'
#
#  association :location, factory: :ship3_location, :strategy => :build
#end
#
#factory :ship4, parent: :server_ship do
#  id      'ship4'
#  user_id 'user1'
#  system_name 'sys1'
#  type :corvette
#
#  association :location, factory: :ship4_location, :strategy => :build
#end
#
#factory :ship5, parent: :server_ship do
#  id      'ship5'
#  user_id 'user2'
#  system_name 'sys1'
#
#  association :location, factory: :ship5_location, :strategy => :build
#end
#
#factory :ship6, parent: :server_ship do
#  id      'ship6'
#  user_id 'user2'
#  system_name 'sys1'
#  type    :mining
#
#  association :location, factory: :ship6_location, :strategy => :build
#  after(:build) { |sh| sh.add_resource('metal-steel', 100) }
#end
#
#factory :ship7, parent: :server_ship do
#  id      'ship7'
#  user_id 'user2'
#  system_name 'sys1'
#  type    :mining
#
#  association :location, factory: :ship7_location, :strategy => :build
#end
#
#factory :ship8, parent: :server_ship do
#  id      'ship8'
#  user_id 'user1'
#  system_name 'sys1'
#  type    :destroyer
#
#  association :location, factory: :ship8_location, :strategy => :build
#end
#
#factory :ship9, parent: :server_ship do
#  id      'ship9'
#  user_id 'user1'
#  system_name 'sys2'
#  type    :mining
#
#  association :location, factory: :ship9_location, :strategy => :build
#end
