# Manufactured entity registry
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/server/registry'

module Manufactured

# Primary server side entity tracker for Manufactured module.
#
# Provides a thread safe registry through which manufactured
# entity heirarchies and resources can be accessed.
#
# Singleton class, access via Manufactured::Registry.instance.
class Registry
  include Omega::Server::Registry

  # Return array of ships tracked by registry
  def ships    ; entities.select { |e| e.is_a?(Ship)    } ; end

  # Return array of stations tracked by registry
  def stations ; entities.select { |e| e.is_a?(Station) } ; end

  # Return array of loot tracked by registry
  def loot     ; entities.select { |e| e.is_a?(Loot)    } ; end

  # [Array<Manufactured::Commands>] commands to be regularily run
  attr_reader :commands

  # Time attack thread sleeps between event cycles
  POLL_DELAY = 0.5 # TODO make configurable?

  private

  def check_entity(entity, old_entity)
    @lock.synchronize {
      # TODO resolve system references here
      rentity = @entities.find { |e| e.id == entity.id }
    }
  end

  public

  def initialize
    init_registry

# TODO validate command id is unique

    # validate entities upon creation
    self.validation = proc { |r,e|
      # confirm type
      [Ship, Station].include?(e.class) &&

      # ensure id not take
      r.find { |re| re.id == e.id }.nil? &&

      # ensure valid entity
      e.valid?
    }

    # sanity checks on entity
    on(:added)   { |e|    check_entity(e) }
    on(:updated) { |e,oe| check_entity(e) }

    # run commands
    run { run_commands }
  end

end # class Registry
end # module Manufactured

  # Perform resource transfer operation between manufactured entities
  #
  # @param [Manufactured::Entity] from_entity entity intiating transfer
  # @param [Manufactured::Entity] to_entity entity to receivereceived resources
  # @param [String] resource_id string id of the reosurce
  # @param [Integer] quantity amount of reosurce to transfer
  # @return [Array<Manufactured::Entity,Manufactured::Entity>, nil] array containing from_entity and to_entity or nil if transfer could not take place
  #def transfer_resource(from_entity, to_entity, resource_id, quantity)
  #  @entities_lock.synchronize{
  #    # TODO throw exception ?
  #    quantity = quantity.to_f
  #    return if from_entity.nil? || to_entity.nil? ||
  #              !from_entity.can_transfer?(to_entity, resource_id, quantity) ||
  #              !to_entity.can_accept?(resource_id, quantity)
  #    begin
  #      # transfer resource
  #      to_entity.add_resource(resource_id, quantity)
  #      from_entity.remove_resource(resource_id, quantity)

  #      # invoke callbacks
  #      [from_entity, to_entity].each { |e|
  #        e.notification_callbacks.
  #        select { |c| c.type == :transfer }.
  #        each { |c|
  #          c.invoke 'transfer', from_entity, to_entity
  #        }
  #      }
  #    rescue Exception => e
  #      return nil
  #    end

  #    return [from_entity, to_entity]
  #  }
  #end

  # Collect loot using manufactured entity
  #
  # @param [Manufactured::Entity] entity entity to collect resource with
  # @param [Manufactured::Loot] loot loot to collect
  #def collect_loot(entity, loot)
  #  total = 0
  #  @entities_lock.synchronize{
  #    begin
  #      # copy of loot for use in callbacks
  #      oloot = Loot.new

  #      # transfer loot
  #      loot.resources.each { |rs,q|
  #        total += q
  #        entity.add_resource(rs, q)
  #        oloot.add_resource(rs, q)
  #        loot.remove_resource(rs, q)
  #      }

  #      # invoke callbacks
  #      entity.notification_callbacks.
  #        select { |c| c.type == :collected_loot }.
  #        each { |c|
  #          c.invoke 'collected_loot', entity, oloot
  #        }

  #    rescue Exception => e
  #    end
  #  }
  #  return total
  #end


  # Set loot to registry. If empty deletes loot, else adds / updates loot record
  #
  # @param [Manufactured::Loot] loot loot to add to / update in registry
  #def set_loot(loot)
  #  @entities_lock.synchronize{
  #    if loot.quantity == 0
  #      @loot.delete(loot.id)
  #    else
  #      @loot[loot.id] = loot
  #    end
  #  }
  #end
