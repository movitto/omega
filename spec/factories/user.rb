require 'users/user'

FactoryGirl.define do
  factory :user, class: Users::User do
    password          'super_secret_pass'
    permenant         false
    registration_code nil
    secure_password   true

    after(:build) { |u|
      r = build(:role, id: "user_role_#{u.id}")
      u.add_role(r)

      if Users::Registry.instance.find(:id => u.id, :type => "Users::User").empty?
        Users::Registry.instance.create(u)
      end

      if Users::Registry.instance.find(:id => r.id, :type => "Users::Role").empty?
        Users::Registry.instance.create(r)
      end
    }
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

  factory :test_user, parent: :user do
    id                'omega-test'
    email             'om@eg.a'
    password          'tset-agemo'
  end

  factory :mmorsi, parent: :reg_user do
    id                'mmorsi'
    email             'mo@morsi.org'
  end

  factory :user1, parent: :reg_user do
    id                'user1'
    email             '1@us.er'
  end

  factory :user2, parent: :reg_user do
    id                'user2'
    email             '2@us.er'
  end
end
