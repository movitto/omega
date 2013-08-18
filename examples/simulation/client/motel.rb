# Motel client definitions to be loaded by bin/rjr-client
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'motel/location'
require 'motel/movement_strategies/stopped'

include RJR::MessageMixins

def dispatch_motel(dispatcher)
  dispatcher.handle "motel::on_movement" do |l, d, dx, dy, dz|
  end

  0.upto(500) { |i|
    define_message "get_location_#{i}"  do
      { :method => "motel::get_location",
        :params => ['with_id', i],
        :result => lambda { |l| l.id == i } }
    end

    define_message "update_location_#{i}" do
      { :method => 'motel::update_location',
        :params => [lambda { l = Motel::Location.random ; l.id = i ; l }],
        :result =>  lambda { |l| l.id == i } }
    end

    define_message "track_movement_of_#{i}" do
      { :method => "motel::track_movement",
        :params => [i, 5],
        :result =>  lambda { |n| n.nil? },
        :transports => [:amqp, :tcp, :ws] }
    end
  }

  define_message :get_all_locations do
    { :method => 'motel::get_locations' }
  end

  define_message :create_location do
    { :method => 'motel::create_location',
      :params => [lambda { Motel::Location.random } ] }
  end
end

alias :dispatch_examples_simulation_client_motel :dispatch_motel
