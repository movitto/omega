# Motel messages module. Defines concrete instances
# of Motel::MessageBase as defined in qpid.rb. Provides
# RequestMessage to perform a request on the motel amqp
# interface and ResponseMessage to return the result.
#
# Copyright (C) 2009 Mohammed Morsi <movitto@yahoo.com>
# See COPYING for the License of this software

require 'motel/qpid'

module Motel

# Defines various request messages which Client instances
# can send to Server instances to handle and respond to.
# A common handler scenario is provided in with the
# register_handlers method below.
class RequestMessage < MessageBase
 public
   # get location with the specified id
   define_message :get_location, :location_id

   # register the location with the specified id
   define_message :register_location, :location_id

   # save location with the specified id
   define_message :save_location, :location_id

   # update specified location with optional new attributes and movement strategy
   define_message :update_location, :location, :movement_strategy

   # subscribe to location updates for location specified by id
   define_message :subscribe_to_location, :location_id

   # define & register handlers for each of the request
   # message events, making use of the specified Runner 
   # and QpidNode instances
   # runner should be a Motel::Runner instance used to track locations
   # node should be a Motel::QpidNode instance used to send replies
   def register_handlers(runner, node)

      # on get location, try to find the location_id in the runner and return the found location, else return failed
      @get_location_handler= Proc.new { |location_id, response_route|
         $logger.info "received get location message " + location_id.to_s
         failed = true

         runner.locations.each { |loc|
           if loc.id == location_id.to_i
             $logger.info "  specific location id to get found, responding to #{response_route} with location  " + loc.to_s

             node.send_message response_route, ResponseMessage::location(loc)
             failed = false
             break
           end
         }

         $logger.info "  failed to perform get location operation " + location_id.to_s if failed
         node.send_message response_route, ResponseMessage::status("failed") if failed
      }

      # on get location, try to find the location_id in the db and add it to the runner, 
      # return success if at the end the location is in the runner, else failed
      @register_location_handler= Proc.new { |location_id, response_route|
         $logger.info "received register location message " + location_id.to_s

         runner = Loader.Load("id = #{location_id}", runner)
         succeeded = !runner.nil?

         status = succeeded ? "success" : "failed"
         $logger.info "  registration operation returning  to #{response_route} with status " + status.to_s
         node.send_message response_route, ResponseMessage::status(status)
      }

      # on save location, try to find the specified running location and save it, 
      # return success if found/saved, failed otherwise
      @save_location_handler= Proc.new { |location_id, response_route|
         $logger.info "received save location message " + location_id.to_s
         succeeded = false
         runner.locations.each { |loc|
           if loc.id == location_id.to_i
             $logger.info "  specific location id to save found, saving" + location_id.to_s
             loc.save!
             succeeded = true
             break
           end
         }
         status = succeeded ? "success" : "failed"
         $logger.info "  save operation returning  to #{response_route} with status " + status.to_s
         node.send_message response_route, ResponseMessage::status(status)
      }

      # on update location, try to find the specified running location id, and update it with the set
      # attributes on the specified location object and movement strategy if specified.
      # return success if found/updated, failed otherwise
      @update_location_handler= Proc.new { |location, movement_strategy, response_route|
         $logger.info "received update location message " + location.to_s
         succeeded = false

         unless location.nil?
           runner.locations.each { |loc|
             if loc.id == location.id
               $logger.info "  location id #{location.id.to_s} found, updating "

               unless movement_strategy.nil?
                 $logger.info "  updating location movement strategy with #{movement_strategy.to_s}"

                 if loc.movement_strategy.type == movement_strategy.type
                   loc.movement_strategy.update_attributes movement_strategy.to_h
                 else
                   loc.movement_strategy = movement_strategy
                   loc.save! # TODO catch save errors
                 end
               end

               loc.update_attributes location.to_h
               succeeded = true
               break
             end
           }
         end
         status = succeeded ? "success" : "failed"
         $logger.info "  #{location.id.to_s} update operation completed, returning  to #{response_route} with status " + status.to_s
         node.send_message response_route, ResponseMessage::status(status)
      }

      # on subscribe to location, try to find specified location and create queue for corresponding location updates,
      # add movement_callback to location to publish messages to queue. return success if successful else false, the
      # reply_to field of the return message will contain the routing_key for the subscription queue
      @subscribe_to_location_handler= Proc.new { |location_id, response_route|
         $logger.info "received subscribe location message " + location_id.to_s
         succeeded = false
         tnode = node

         runner.locations.each { |loc|
           if loc.id == location_id.to_i
             $logger.info "  specific location id to subscribe to found, opening channel " + location_id.to_s
             node_id = "location" + location_id.to_s + "-updates"
             tnode = QpidNode.new :id => node_id

             # subscribe to location movement updates, sending events to queue just created
             loc.movement_strategy.movement_callbacks.push(Proc.new do |location|
                tnode.send_message(node_id + "-queue", ResponseMessage.location(location))
             end)

             node.children[location_id] = tnode
             succeeded = true
             break
           end
         }

         status = succeeded ? "success" : "failed"
         $logger.info "  subscribe operation returning  to #{response_route} with status " + status.to_s
         tnode.send_message response_route, ResponseMessage::status(status)
      }

   end
end

# Defines various response messages which Server instances
# send to Client instances in response to requests
class ResponseMessage < MessageBase
 public
  # status response which conveys the status of an operation
  define_message :status, :status

  # repsonse which conveys a location
  define_message :location, :location
end

end # module Motel
