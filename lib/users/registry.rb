# Users entity registry
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'omega/server/registry'
require 'omega/server/event'
require 'omega/server/event_handler'

require 'users/session'
require 'users/mixins/registry'

module Users

# Primary server side entity tracker for the Users module.
#
# Provides a thread safe registry through which users can be accessed and managed.
#
# Also provides thread safe methods which to query users and privileges
# based on a session id and other parameters
#
# Singleton class, access via Users::Registry.instance.
class Registry
  include Omega::Server::Registry
  include SanitizesEntities
  include ManagesSessions
  include Authentication

  class << self
    # @!group Config options

    # Boolean toggling if user permission system is enabled / disabled.
    # Disabling permissions will result in all require/check privileges
    # calls returning true
    #
    # TODO ideally would have this in rjr adapter like user_attributes.
    # To do this, all require/check privilege calls (as invoked by other subsystems)
    # would have to go through rjr
    attr_accessor :user_perms_enabled

    # Set config options using Omega::Config instance
    #
    # @param [Omega::Config] config object containing config options
    def set_config(config)
      self.user_perms_enabled = config.user_perms_enabled
    end

    # @!endgroup
  end

  private

  # validate user/role id or session's user id is unique on creation
  def validate_entity(entities, entity)
    if entity.is_a?(Session)
      entities.none? { |re| re.is_a?(Session) && re.user.id == entity.user.id }
    else
      entities.none? { |re| re.class == entity.class && re.id == entity.id }
    end
  end

  def init_validations
    validation_callback { |entities, check|
      check.kind_of?(Omega::Server::Event) ||
      check.kind_of?(Omega::Server::EventHandler) ||

      ([User, Role, Session].include?(check.class) &&
       validate_entity(entities, check))
    }
  end

  def init_callbacks
    on(:added) { |entity|
      if entity.is_a?(User)
        set_creation_timestamps(entity)
        sanitize_user(entity)

      elsif entity.is_a?(Users::Session)
        sanitize_session(entity)

      elsif entity.kind_of?(Omega::Server::EventHandler)
        sanitize_event_handlers(entity)
      end
    }

    # sanity checks on user
    on(:updated) { |entity, oentity|
      sanitize_user(entity, oentity) if entity.is_a?(Users::User)
    }
  end

  # Users::Registry intitializer
  def initialize
    init_registry
    init_validations
    init_callbacks

    exclude_from_backup Users::Session
    exclude_from_backup Omega::Server::EventHandler

    run { run_events }
  end
end # class Registry
end # module Users
