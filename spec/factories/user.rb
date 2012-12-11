require 'users/user'

FactoryGirl.define do
  factory :user, class: Users::User do
    password          'super_secret_pass'
    permenant         false
    registration_code nil
    secure_password   true

    after(:build) { |u| u.add_role(build(:role, id: "#{u.id}_role")) }
  end

  factory :admin, parent: :user do
    id                'admin'
    password          'nimda'
    email             'ad@mi.n'
    permentant        true
  end

  factory :reg_user, parent: :user do
    alliances         { [association(id + "_alliance", strategy: :build)] }
  end

  factory :mmorsi, parent: :reg_user do
    id                'mmorsi'
    email             'mo@morsi.org'
  end

  factory :user1, parent: :reg_user do
    id                'user1'
    email             '1@us.er'
  end
end
