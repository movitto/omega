# Users Sanitizes Entities Mixin
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Users
module SanitizesEntities
  # TODO raise errors if references can't be resolved?

  def set_creation_timestamps(user)
    @lock.synchronize {
      ruser = @entities.find { |e| e.is_a?(Users::User) && e.id == user.id }
      ruser.created_at       = Time.now
      ruser.last_modified_at = Time.now
    }
  end

  def sanitize_user(nuser, ouser=nil)
    @lock.synchronize {
      ruser = @entities.find { |e| e.is_a?(Users::User) && e.id == nuser.id }

      # update role references
      ruser.roles.each_index { |rolei|
        ri   = ruser.roles[rolei].id
        role = @entities.find { |e| e.is_a?(Users::Role) && e.id == ri }
        ruser.roles[rolei] = role
      } unless ruser.roles.nil?
    }
  end

  def sanitize_session(session)
    @lock.synchronize {
      # update session user reference
      rsession = @entities.find { |e| e.is_a?(Users::Session) &&
                                      e.id == session.id }
      ruser = @entities.find { |e| e.is_a?(Users::User) &&
                                   e.id == rsession.user.id }
      rsession.user = ruser
    }
  end
end # module SanitizesEntities
end # module Users
