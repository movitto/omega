# Omega Spec Trackable Entity
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'omega/client/mixins'

module OmegaTest
  class Trackable
    include Omega::Client::Trackable
    include Omega::Client::TrackEvents
    include Omega::Client::TrackState
    include Omega::Client::TrackEntity
    entity_type Manufactured::Ship
    get_method "manufactured::get_entity"

    server_state :test_state,
      { :check => lambda { |e| @toggled ||= false ; @toggled = !@toggled },
        :on    => lambda { |e| @on_toggles_called  = true },
        :off   => lambda { |e| @off_toggles_called = true } }

    attr_accessor :setup_run
    attr_accessor :updated

    entity_event :setup_event => { :setup => proc { |e| @setup_run = true } }

    entity_event :subscribe_event => { :subscribe => 'subscribe_method' }

    entity_event :notification_event => { :notification => 'notification_method',
                                          :update => proc { |e,*args| e.updated = true }}

    entity_event :match_event => { :notification => 'match_method',
                                    :match => proc { |e,*args| false } }

    attr_accessor :entity_initialized
    entity_init{ |e|
      @entity_initialized = true
    }
  end

  class Trackable1
    include Omega::Client::Trackable
    include Omega::Client::TrackEvents
    include Omega::Client::TrackEntity
    entity_type Manufactured::Station
    get_method "manufactured::get_entity"
  end
end
