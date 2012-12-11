require 'manufactured/station'

FactoryGirl.define do
  factory :station, class: Manufactured::Station do
  end

  factory :station1, parent: :station do
    id     'station1'

    association :solar_system, factory: :solar_system1, :strategy => :build
    association :location, factory: :station1_location, :strategy => :build
  end

end
