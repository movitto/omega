# Omega Spec Factory Girl Helper
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'factory_girl'
FactoryGirl.find_definitions

# Build is used to construct entity locally,
# create used to construct on server
FactoryGirl.define do
  trait :server_entity do
    # entities which use this should define the rjr create_method
    ignore do
      create_method nil
    end

    # skip traditonal save! based creation
    skip_create

    # register custom hook to construct the entity serverside
    before(:create) do |e,i|
      # temporarily disable permission system
      disable_permissions {
        begin $fgnode.invoke(i.create_method, e)
        # assuming operation error just means entity was previously
        # created, and silently ignore
        # (TODO should only rescue OperationError when rjr supports error forwarding)
        rescue Exception => e ; end
      }

      e.location.id = e.id if e.respond_to?(:location)
   end
  end
end
