require 'users/user'

FactoryGirl.define do
  factory 'users/user' do
    server_entity
    create_method 'users::create_user'

    permenant         false
    registration_code nil

    # leave password security off on client side
    # (serverside create rjr handler sets password)
    secure_password   false

    factory :admin do
      id                'admin'
      password          'nimda'
      email             'ad@mi.n'
      permenant          true
    end

    factory :anon do
      id                'anon'
      password          'nona'
      email             'an@o.n'
      permenant          true
    end

    factory :user do
      sequence(:id)       { |n| "user#{n}"     }
      sequence(:email)    { |n| "us#{n}@e.r"   }
      sequence(:password) { |n| "password#{n}" }
    end
  end
end
