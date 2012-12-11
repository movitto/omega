require 'users/role'
require 'omega/roles'

FactoryGirl.define do
  factory :role, class: Users::Role do
  end

  Omega::Roles::ROLES.each_key { |rid|
    factory rid, parent: :role do
      id rid

      after(:build) { |r|
        omr = Omega::Roles::ROLES[r.id]
        omr.each { |pe| r.add_privilege(*pe) }
      }
    end
  }
end
