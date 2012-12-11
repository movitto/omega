require 'manufactured/fleet'

FactoryGirl.define do
  factory :fleet1, class: Manufactured::Fleet do
    id       'fleet1'
    user_id  'user1'
    ships    { [association(:ship1, strategy: :build),
                association(:ship2, strategy: :build)] }
  end
end
