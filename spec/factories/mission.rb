require 'missions/mission'

FactoryGirl.define do
  factory 'missions/mission' do
    server_entity
    create_method 'missions::create_mission'

    factory :mission do
      sequence(:id)   {  |n| "mission#{n}" }
      sequence(:title){  |n| "mission#{n}" }
      association :creator, :factory => :admin

      factory :assigned_mission do |m|
        assigned_to { create(:user) }
        assigned_time Time.now
        m.timeout 60

        factory :victorious_mission do
          victorious true
        end

        factory :failed_mission do
          failed true
          assigned_time Time.new(0)
        end
      end
    end
  end
end
