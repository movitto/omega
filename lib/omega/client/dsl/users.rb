# Omega Client DSL Users Interface
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Omega
  module Client
    module DSL
      # Return user w/ the given user_id, else if it is not found create
      # it w/ the specified password and attributes
      #
      # @param [String] user_id string id to assign to the new user
      # @param [String] password password to assign to the new user
      # @param [Callable] bl option callback block parameter to call w/ the newly created user
      # @return [Users::User] user created
      def user(user_id, password = nil, args = {}, &bl)
        # lookup / return user
        begin return invoke('users::get_entity', 'with_id', user_id)
        rescue Exception => e ; end

        # create / return user
        u = Users::User.new(args.merge({:id => user_id, :password => password,
                                        :registration_code => nil}))
        invoke('users::create_user', u)
        dsl.run u, :user => u, &bl
        u
      end

      # Create a new role, or if @user is set, simply add the specified role id
      # to the user
      #
      # Operates in one of two modes depending on if \@user is set. If it is, specify
      # a string role name to this function to be added to the user indicated by
      # \@user. Else specify a Users::Role to create on the server side
      #
      # @param [Users::Role,String] nrole name of role to add to user or Users::Role to create on the server side
      def role(nrole)
        if @user
          RJR::Logger.info "Adding role #{nrole} to #{@user}"
          invoke('users::add_role', @user.id, nrole)

        else
          RJR::Logger.info "Creating role #{nrole}"
          invoke('users::create_role', nrole)
        end
      end
    end # module DSL
  end # module Client
end # module Omega
