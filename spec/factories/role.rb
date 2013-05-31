require 'users/role'
require 'omega/roles'

FactoryGirl.define do
  factory 'users/role' do
    server_entity
    create_method 'users::create_role'

    factory :role do
      sequence(:id)  {  |n|  "role#{n}" }
    end

    Omega::Roles::ROLES.each_key { |rid|
      factory rid do
        id rid

        after(:build) { |r|
          omr = Omega::Roles::ROLES[r.id]
          omr.each { |pe| r.add_privilege(*pe) }
        }
      end
    }
  end
end
