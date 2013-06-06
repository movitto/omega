require 'missions/mission'

FactoryGirl.define do
  factory 'missions/mission' do
    server_entity
    create_method 'missions::create_mission'

    factory :mission do
      sequence(:id)   {  |n| "mission#{n}" }
      sequence(:title){  |n| "mission#{n}" }
    end
  end
end
