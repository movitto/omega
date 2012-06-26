# Motel rjr adapter
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'active_support/inflector'

module Cosmos

class RJRAdapter
  def self.user
    @@cosmos_user ||= Users::User.new(:id => 'cosmos',
                                      :password => 'changeme')
  end

  def self.init
    self.register_handlers(RJR::Dispatcher)
    #Cosmos::Registry.instance.init
    @@local_node = RJR::LocalNode.new :node_id => 'cosmos'
    @@local_node.message_headers['source_node'] = 'cosmos'
    @@local_node.invoke_request('users::create_entity', self.user)
    @@local_node.invoke_request('users::add_privilege', self.user.id, 'view',   'locations')
    @@local_node.invoke_request('users::add_privilege', self.user.id, 'create', 'locations')

    session = @@local_node.invoke_request('users::login', self.user)
    @@local_node.message_headers['session_id'] = session.id

    @@remote_cosmos_manager = RemoteCosmosManager.new
  end

  def self.register_handlers(rjr_dispatcher)
    rjr_dispatcher.add_handler('cosmos::create_entity'){ |entity, parent_name|
       Users::Registry.require_privilege(:privilege => 'create', :entity => 'cosmos_entities',
                                         :session   => @headers['session_id'])

       parent_type = entity.class.parent_type

       rparent = Cosmos::Registry.instance.find_entity(:type => parent_type, :name => parent_name)
       if rparent.nil?
         # create placeholder parent
         rparent = Cosmos::Registry.instance.create_parent entity, parent_name
       end
       raise Omega::DataNotFound, "parent entity of type #{parent_type} with name #{parent_name} not found" if rparent.nil?

       rparent.add_child entity

       if entity.class.remotely_trackable? && entity.remote_queue
         @@remote_cosmos_manager.create_entity(entity, parent_name)

       else
         # entity.location.entity = entity
         entity.location = @@local_node.invoke_request('create_location', entity.location)
         # TODO add all of entities children to location tracker

       # else raise error TODO
       end

       entity
    }

    rjr_dispatcher.add_handler('cosmos::get_entity'){ |*args|
       type = args[0]
       name = args.length > 0 ? args[1] : nil

       entities = Cosmos::Registry.instance.find_entity(:type => type.intern, :name => name)

       return_first = false
       unless entities.is_a?(Array)
         raise Omega::DataNotFound, "entity of type #{type}" + (name.nil? ? "" : " with name #{name}") + " not found" if entities.nil?
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
               parent.remove_child(child)
               parent.add_child(rchild)

             else
               child.location = @@local_node.invoke_request('get_location', child.location.id)
             end

           }
         end
       }

       0.upto(entities.size-1) { |i|
         entity = entities[i]
         if entity.class.remotely_trackable? && entity.remote_queue
           entities[i] = @@remote_cosmos_manager.get_entity(entity)
         else
           # update locations w/ latest from the tracker
           entity.location = @@local_node.invoke_request('get_location', entity.location.id) if entity.location
         end
       }

       return_first ? entities.first : entities
    }

    rjr_dispatcher.add_handler('cosmos::get_entity_from_location'){ |type, location_id|
       entity = Cosmos::Registry.instance.find_entity(:type => type.intern,
                                                      :location => location_id)

       raise Omega::DataNotFound, "entity of type #{type} with location_id #{location_id} not found" if entity.nil?
       Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "cosmos_entity-#{entity.id}"},
                                                  {:privilege => 'view', :entity => 'cosmos_entities'}],
                                         :session => @headers['session_id'])

       # update locations w/ latest from the tracker
       entity.location = @@local_node.invoke_request('get_location', entity.location.id)
       if entity.has_children?
         entity.each_child { |parent, child|
           if child.class.remotely_trackable? && child.remote_queue
             rchild = @@remote_cosmos_manager.get_entity(child)
             parent.remove_child(child)
             parent.add_child(rchild)
           else
             child.location = @@local_node.invoke_request('get_location',
                                                          child.location.id)
           end
         }
       end

       entity
    }

    rjr_dispatcher.add_handler('cosmos::set_resource') { |entity_id, resource, quantity|
       entity = Cosmos::Registry.instance.find_entity(:name => entity_id)
       raise Omega::DataNotFound, "entity of specified by #{entity_id} not found" if entity.nil?
       Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "cosmos_entity-#{entity.name}"},
                                                  {:privilege => 'modify', :entity => 'cosmos_entities'}],
                                         :session => @headers['session_id'])
       Cosmos::Registry.instance.set_resource(entity_id, resource, quantity)
       nil
    }

    rjr_dispatcher.add_handler('cosmos::get_resources') { |entity_id|
       entity = Cosmos::Registry.instance.find_entity(:name => entity_id)
       raise Omega::DataNotFound, "entity of specified by #{entity_id} not found" if entity.nil?
       Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "cosmos_entity-#{entity.name}"},
                                                  {:privilege => 'view', :entity => 'cosmos_entities'}],
                                         :session => @headers['session_id'])
       resources = Cosmos::Registry.instance.resources(:entity_id => entity_id)
       resources
    }

    rjr_dispatcher.add_handler('cosmos::get_resource_sources') { |entity_id|
       entity = Cosmos::Registry.instance.find_entity(:name => entity_id)
       raise Omega::DataNotFound, "entity of specified by #{entity_id} not found" if entity.nil?
       Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "cosmos_entity-#{entity.name}"},
                                                  {:privilege => 'view', :entity => 'cosmos_entities'}],
                                         :session => @headers['session_id'])
       Cosmos::Registry.instance.resource_sources.select { |rs| rs.entity.name == entity_id }
    }

    rjr_dispatcher.add_handler('cosmos::get_resource_source') { |resource_source_id|
       rs = Cosmos::Registry.instance.resource_sources.find { |rs| rs.id == resource_source_id }
       raise Omega::DataNotFound, "resource_source specified by #{resource_source_id} not found" if rs.nil?
       Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "cosmos_entity-#{rs.entity.name}"},
                                                  {:privilege => 'view', :entity => 'cosmos_entities'}],
                                         :session => @headers['session_id'])
       rs
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
