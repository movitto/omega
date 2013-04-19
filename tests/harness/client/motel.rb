require 'rjr/util'
require 'motel'
include RJR::Definitions

rjr_method \
  "motel::on_movement" =>
    lambda { |l, d, dx, dy, dz|
    }

0.upto(5000) { |i|
  rjr_message \
    "get_location_#{i}" =>
      { :method => "motel::get_location",
        :params => ['with_id', i],
        :result => lambda { |l| l.id == i } },

    "update_location_#{i}" =>
      { :method => 'motel::update_location',
        :params => [lambda { l = Motel::Location.random ; l.id = i ; l }],
        :result =>  lambda { |l| l.id == i } },

    "track_movement_of_#{i}" =>
      { :method => "motel::track_movement",
        :params => [i, 5],
        :result =>  lambda { |l| l.id == i },
        :transports => [:amqp, :tcp, :ws] }
}

rjr_message :get_all_locations => 
  { :method => 'motel::get_locations' }

rjr_message :create_location =>
  { :method => 'motel::create_location',
    :params => [lambda { Motel::Location.random } ] }
