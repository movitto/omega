require 'cosmos/resource'

FactoryGirl.define do
  factory 'cosmos/resource' do
    server_entity
    create_method 'cosmos::set_resource'

    factory :resource do
      sequence(:id) { |n| "resource#{n}" }
      sequence(:material_id) {  |n| "type-name#{n}" }
      quantity 50
      association :entity, :factory => :asteroid
    end
  end
end
