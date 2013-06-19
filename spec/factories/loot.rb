require 'manufactured/loot'

FactoryGirl.define do
  factory 'manufactured/loot' do
    # doesn't work same as other server entities so commented:
    #server_entity
    skip_create
    before(:create) { |e,i|
      e.location.id = e.id 
      Motel::RJR.registry << e.location
      Manufactured::RJR.registry << e
    }

    factory :loot do
      sequence(:id, 10000) { |n| "loot#{n}" }

      factory :valid_loot do
        solar_system
      end
    end
  end
end
