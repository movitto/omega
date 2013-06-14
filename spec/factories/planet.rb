require 'cosmos/entities/planet'

FactoryGirl.define do
  factory 'cosmos/server/planet' do
    server_entity
    create_method 'cosmos::create_entity'

    factory :planet do
      name     'planet'
      size      35
      color    'AABBCC'

      association :location, factory: :planet1_location, :strategy => :build
    end
  end
end
