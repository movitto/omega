# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'users'
require 'manufactured'
require 'cosmos'
require 'motel'

require 'singleton'

module Omega
  module Client

    module CachedAttribute
      def self.cache(entity, attribute, &callback)
        cval = entity.instance_variable_get("@#{attribute}".intern)
        cval.extend(CachedAttribute)
        cval.enable_tracking(true) # TODO default to false?

        entity.instance_variable_set("@cached_#{attribute}", cval)

        entity.class.send(:define_method, attribute.intern){
          te = cval.tracking_enabled?
          ts = entity.instance_variable_get("@#{attribute}_timestamp".intern)
          orig = entity.instance_variable_get("@cached_#{attribute}")
          if te && (ts.nil? || (Time.now - ts) > TIMEOUT)
            entity.instance_variable_set("@#{attribute}_timestamp".intern, Time.now)
            entity.instance_variable_set("@cached_#{attribute}", callback.call(orig))
          end
          entity.instance_variable_get("@cached_#{attribute}")
        }
      end

      # 1/2 minute
      TIMEOUT = 30

      def tracking_enabled?
        @tracking_enabled
      end

      def enable_tracking(val)
        @tracking_enabled = val
      end

    end

    class Node
      class << self
        # @!group Config options
        attr_accessor :server_endpoint

        attr_accessor :refresh_time

        attr_accessor :client_username

        attr_accessor :client_password
      end

      def initialize(args = {})
        @registry       = {}
        @event_handlers = {}
        @refresh_list   = {}
        @event_queue    = Queue.new
        @lock           = Mutex.new
      end

      def node=(node)
Omega::Client::Node.refresh_time = 1
        # set default server endpoint depending on node type
        Omega::Client::Node.server_endpoint =
          case node.class::RJR_NODE_TYPE
            when :amqp then 'omega-queue'
            when :tcp  then 'json-rpc://localhost:8181'
            else nil
          end

        @node = node
        @node.message_headers['source_node'] = @node.node_id
        @node.listen

        @user =
          Users::User.new(:id => Omega::Client::Node.client_username,
                          :password => Omega::Client::Node.client_password)
        @session = self.invoke_request('users::login', @user)
        @node.message_headers['session_id'] = @session.id
                    
        @node
      end

      def user
        @user
      end

      # permit singleton instance methods to be
      # invoked directly on class
      include Singleton
      def self.method_missing(method_id, *args, &bl)
        Node.instance.send method_id, *args, &bl
      end

      def get(id)
        @lock.synchronize{
          @registry[id]
        }
      end

      def select(&bl)
        tr = Hash.new
        @lock.synchronize{
          tr.merge! @registry
        }
        tr.select(&bl)
      end

      def set(entity)
        @lock.synchronize{
          @registry[entity.id] = entity
        }

        raise_event(:updated, entity)
        entity
      end

      def cached(id, &retrieval)
        entity = get(id)
        entity = retrieval.call(id) if entity.nil?
        set(entity)
      end

      def invoke_request(method, *args)
        args = convert_invoke_args(args)
        args.unshift method
        args.unshift Omega::Client::Node.server_endpoint unless Omega::Client::Node.server_endpoint.nil?
        res = nil
        @lock.synchronize {
          res = @node.invoke_request *args
        }

        set_result(res)
        res
      end

      def add_method_handler(method)
        RJR::Dispatcher.add_handler(method) { |*args|
          Node.set_result(args)
          Node.raise_event(method, *args)
        }
      end

      def raise_event(method, *args)
        @event_queue.push([method, args])

        @lock.synchronize{
          return if @event_cycle
          @event_cycle = true

          @node.em_repeat_async(Omega::Client::Node.refresh_time) {
            while @event_queue.size > 0 && event = @event_queue.pop
              method,args = event.first,event.last
              entity_id = id_from_event_args(args)  # extract id
              nice_args = prettify_event_args(args) # standardize event args format # TODO shouldn't be necessary, should be done server side
              @event_handlers[entity_id][method].each { |cb|
                cb.call(*nice_args)
              } if @event_handlers[entity_id] && @event_handlers[entity_id][method]
            end
          }
        }
      end

      def has_method_handler_for?(event)
        RJR::Dispatcher.has_handler_for?(event)
      end

      def add_event_handler(entity_id, event, &bl)
        @lock.synchronize {
          @event_handlers[entity_id]        ||= {}
          @event_handlers[entity_id][event] ||= []
          @event_handlers[entity_id][event] << bl
        }
      end

      #def refresh(entity, &bl)
      #  @lock.synchronize {
      #    @refresh_list[entity.id] = [entity, bl] unless @refresh_list.has_key?(entity)

      #    return if @refresh_cycle
      #    @refresh_cycle = true

      #    # TODO support multiple refresh runners at some point w/ variables times
      #    @node.em_repeat_async(Omega::Client::Node.refresh_time) {
      #      @lock.synchronize{
      #        @refresh_list.each { |id,e|
      #          entity,cb = e.first,e.last
      #          entity.get
      #          cb.call(entity) if cb
      #        }
      #      }
      #    }
      #  }
      #end

      def set_result(res)
        if(res.is_a?(Array))
          res.each { |r| set_result(r) }

        elsif Cosmos::Registry.instance.entity_types.include?(res.class) &&
              !res.is_a?(Cosmos::JumpGate)
          set(res)
          set(res.location)
          if(res.is_a?(Cosmos::SolarSystem))
            res.planets.each   { |pl|
              set(pl)
              CachedAttribute.cache(pl, :location) { |l|
                Node.invoke_request('motel::get_location', 'with_id', l.id)
              }
            }
            res.asteroids.each { |ast|
              #set(ast)
              CachedAttribute.cache(ast, :resource_sources) { |rs|
                Node.invoke_request('cosmos::get_resource_sources', ast.name)
              }
            }
            #res.jump_gates.each { |gate|
            #  gate.endpoint = cached(gate.endpoint)
            #}
          end

        elsif Manufactured::Registry.instance.entity_types.include?(res.class)
          set(res)
          set(res.location)
          res.solar_system = cached(res.system_name) { |id|
            invoke_request 'cosmos::get_entity',
                  'with_name', res.system_name
          }

        elsif Users::Registry::VALID_TYPES.include?(res.class) ||
              res.is_a?(Motel::Location)
          set(res)

        end
      end

      private

      def id_from_event_args(args)
        types = Cosmos::Registry.instance.entity_types       +
                Manufactured::Registry.instance.entity_types +
                Users::Registry::VALID_TYPES

        e = args.find { |e| types.include?(e.class) ||
                              (e.class.respond_to?(:entity_type) &&
                               types.include?(e.class.entity_type)) }
        if e.nil? && args.first.is_a?(Motel::Location)
          e = self.select { |eid,e| types.include?(e.class) &&
                                    e.location.id == args.first.id }.first.last
        end
        e.id
      end

      def convert_invoke_args(args)
        args.collect { |a|
          if a.is_a?(Cosmos::JumpGate)
            if a.solar_system.is_a?(Omega::Client::SolarSystem)
              a.solar_system = a.solar_system.name
            end

            if a.endpoint.is_a?(Omega::Client::SolarSystem)
              a.endpoint = a.endpoint.name
            end

          elsif a.is_a?(Manufactured::Ship) || a.is_a?(Manufactured::Station)
            if a.solar_system.is_a?(Omega::Client::SolarSystem)
              a.solar_system = get(a.solar_system.name)
            end
          end

          a
        }
      end

      def prettify_event_args(args)
        # TODO
        args
      end

    end
  end
end
