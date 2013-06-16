require 'manufactured/loot'

FactoryGirl.define do
  factory 'manufactured/loot' do
    #server_entity
    #create_method 'manufactured::set_loot'

    factory :loot do
      sequence(:id, 10000) { |n| n.to_s }

      factory :valid_loot do
        association :solar_system, :strategy => :build
      end
    end
  end
end
