# Cosmos rjr adapter
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'active_support/inflector'

module Cosmos

# Provides mechanisms to invoke Cosmos subsystem functionality remotely over RJR.
#
# Do not instantiate as interface is defined on the class.
class RJRAdapter

  class << self
    # @!group Config options

    # User to use to communicate w/ other modules over the local rjr node
    attr_accessor :cosmos_rjr_username

    # Password to use to communicate w/ other modules over the local rjr node
    attr_accessor :cosmos_rjr_password

    # Set config options using Omega::Config instance
    #
    # @param [Omega::Config] config object containing config options
    def set_config(config)
      self.cosmos_rjr_username  = config.cosmos_rjr_user
      self.cosmos_rjr_password  = config.cosmos_rjr_pass
    end

    # @!endgroup
  end

  # Return user which can invoke privileged cosmos operations over rjr
  #
  # First instantiates user if it doesn't exist.
  def self.user
    @@cosmos_user ||= Users::User.new(:id       => Cosmos::RJRAdapter.cosmos_rjr_username,
                                      :password => Cosmos::RJRAdapter.cosmos_rjr_password)
  end

  # Initialize the Cosmos subsystem and rjr adapter.
  def self.init
    Cosmos::Registry.instance.init
    self.register_handlers(RJR::Dispatcher)
    #Cosmos::Registry.instance.init
    @@local_node = RJR::LocalNode.new :node_id => 'cosmos'
    @@local_node.message_headers['source_node'] = 'cosmos'
    @@local_node.invoke_request('users::create_entity', self.user)
    role_id = "user_role_#{self.user.id}"
    @@local_node.invoke_request('users::add_privilege', role_id, 'view',   'locations')
    @@local_node.invoke_request('users::add_privilege', role_id, 'create', 'locations')

    session = @@local_node.invoke_request('users::login', self.user)
    @@local_node.message_headers['session_id'] = session.id

    @@remote_cosmos_manager = RemoteCosmosManager.new
  end

  # Register handlers with the RJR::Dispatcher to invoke various cosmos operations
  #
  # @param rjr_dispatcher dispatcher to register handlers with
  def self.register_handlers(rjr_dispatcher)
    rjr_dispatcher.add_handler('cosmos::create_entity'){ |entity, parent_name|
       Users::Registry.require_privilege(:privilege => 'create', :entity => 'cosmos_entities',
                                         :session   => @headers['session_id'])

       valid_types = Cosmos::Registry.instance.entity_types
       raise ArgumentError, "Invalid #{entity.class} entity specified, must be one of #{valid_types.inspect}" unless valid_types.include?(entity.class)

       parent_type = entity.class.parent_type

       rparent = Cosmos::Registry.instance.find_entity(:type => parent_type, :name => parent_name)
       if rparent.nil?
         # create placeholder parent
         rparent = Cosmos::Registry.instance.create_parent entity, parent_name
       end
       raise Omega::DataNotFound, "parent entity of type #{parent_type} with name #{parent_name} not found" if rparent.nil?

       # XXX ugly but allows us to lookup entities by name for the time being
       #   at some point change / remove this
       unless entity.is_a?(Cosmos::JumpGate)
         rentity = Cosmos::Registry.instance.find_entity(:name => entity.name)
         raise ArgumentError, "#{entity.class} name #{entity.name} already taken" unless rentity.nil?
       end

       if entity.class.remotely_trackable? && entity.remote_queue
         @@remote_cosmos_manager.create_entity(entity, parent_name)

       else
         Cosmos::Registry.instance.safely_run {
           # setting location must occur before entity is added to parent
           # entity.location.entity = entity
           entity.location.restrict_view = false
           entity.location = @@local_node.invoke_request('motel::create_location', entity.location)
           entity.location.parent = rparent.location
           # TODO add all of entities children to location tracker
         }

       end


       # TODO rparent.can_add?(entity)
       Cosmos::Registry.instance.safely_run {
         entity.parent= rparent
         rparent.add_child entity
       }

       entity
    }

    rjr_dispatcher.add_handler(['cosmos::get_entity', 'cosmos::get_entities']){ |*args|
       filter = {}
       while qualifier = args.shift
         raise ArgumentError, "invalid qualifier #{qualifier}" unless ["of_type", "with_id", "with_name", "with_location"].include?(qualifier)
         val = args.shift
         raise ArgumentError, "qualifier #{qualifier} requires value" if val.nil?
         qualifier = case qualifier
                       when "of_type"
                         :type
                       when "with_id"
                         :name
                       when "with_name"
                         :name
                       when "with_location"
                         :location
                     end
         filter[qualifier] = val
       end

       entities = Cosmos::Registry.instance.find_entity(filter)

       return_first = false
       unless entities.is_a?(Array)
         raise Omega::DataNotFound, "entity not found with params #{filter.inspect}" if entities.nil?
         Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "cosmos_entity-#{entities.name}"},
                                                    {:privilege => 'view', :entity => 'cosmos_entities'}],
                                           :session => @headers['session_id'])

         return_first = true
         entities = [entities]
       end

       entities.reject! { |entity|
         raised = false
         begin
           Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "cosmos_entity-#{entity.name}"},
                                                      {:privilege => 'view', :entity => 'cosmos_entities'}],
                                             :session => @headers['session_id'])
         rescue Omega::PermissionError => e
           raised = true
         end
         raised
       }

       # raise Omega::DataNotFound if entities.empty? (?)
       entities.each{ |entity|
         if entity.has_children?
           entity.each_child { |parent, child|
             if child.class.remotely_trackable? && child.remote_queue
               rchild = @@remote_cosmos_manager.get_entity(child)
               Cosmos::Registry.instance.safely_run {
                 parent.remove_child(child)
                 parent.add_child(rchild)
               }

             else
               Cosmos::Registry.instance.safely_run {
                 child.location = @@local_node.invoke_request('motel::get_location', 'with_id', child.location.id)
                 child.location.parent = parent.location
               }
             end

           }
         end
       }

       0.upto(entities.size-1) { |i|
         entity = entities[i]
         if entity.class.remotely_trackable? && entity.remote_queue
             entities[i] = @@remote_cosmos_manager.get_entity(entity)
         else
           Cosmos::Registry.instance.safely_run {
             # update locations w/ latest from the tracker
             entity.location = @@local_node.invoke_request('motel::get_location', 'with_id', entity.location.id) if entity.location
             entity.location.parent = entity.parent.location if entity.parent
           }
         end
       }

       return_first ? entities.first : entities
    }

    rjr_dispatcher.add_handler('cosmos::set_resource') { |entity_id, resource, quantity|
       raise ArgumentError, "quantity must be an int or float >= 0" unless (quantity.is_a?(Integer) || quantity.is_a?(Float)) && quantity >= 0
       raise ArgumentError, "#{resource} must be a resource" unless resource.is_a?(Cosmos::Resource)

       entity = Cosmos::Registry.instance.find_entity(:name => entity_id)
       raise Omega::DataNotFound, "entity of specified by #{entity_id} not found" if entity.nil?

       valid_types = Cosmos::Registry.instance.entity_types
       raise ArgumentError, "Invalid #{entity.class} entity specified, must be one of #{valid_types.inspect}" unless valid_types.include?(entity.class)

       Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "cosmos_entity-#{entity.name}"},
                                                  {:privilege => 'modify', :entity => 'cosmos_entities'}],
                                         :session => @headers['session_id'])
       raise ArgumentError, "#{resource} must be acceptable by entity #{entity}" unless entity.accepts_resource?(resource)

       Cosmos::Registry.instance.set_resource(entity_id, resource, quantity)
       nil
    }

    rjr_dispatcher.add_handler('cosmos::get_resource_sources') { |entity_id|
       entity = Cosmos::Registry.instance.find_entity(:name => entity_id)
       raise Omega::DataNotFound, "entity of specified by #{entity_id} not found" if entity.nil?
       Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "cosmos_entity-#{entity.name}"},
                                                  {:privilege => 'view', :entity => 'cosmos_entities'}],
                                         :session => @headers['session_id'])
       Cosmos::Registry.instance.resource_sources.select { |rs| rs.entity.name == entity_id }
    }

    rjr_dispatcher.add_handler('cosmos::save_state') { |output|
      raise Omega::PermissionError, "invalid client" unless @rjr_node_type == RJR::LocalNode::RJR_NODE_TYPE
      output_file = File.open(output, 'a+')
      Cosmos::Registry.instance.save_state(output_file)
      output_file.close
      nil
    }

    rjr_dispatcher.add_handler('cosmos::restore_state') { |input|
      raise Omega::PermissionError, "invalid client" unless @rjr_node_type == RJR::LocalNode::RJR_NODE_TYPE
      input_file = File.open(input, 'r')
      Cosmos::Registry.instance.restore_state(input_file)
      input_file.close
      nil
    }

  end
end # class RJRAdapter

end # module Cosmos
