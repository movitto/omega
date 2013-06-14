require 'cosmos/entities/moon'

FactoryGirl.define do
  factory 'cosmos/entities/moon' do
    factory :moon1 do
      sequence(:id)   {  |n| "moon#{n}" }
      sequence(:name) {  |n| "moon#{n}" }
    end
  end
end
