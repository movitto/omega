# Users module alliance definition
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Users

# An alliance represents a union of users which may be
# associated with enemy alliances.
class Alliance
  # [String] Unique identifier of the alliance
  attr_reader   :id

  # [Array<Users::User>] array of users in alliance
  attr_accessor :members

  # [Array<Users::Alliance] array of enemy alliances
  attr_accessor :enemies

  # Alliance initializer
  # @param [Hash] args hash of options to initialize alliance with
  # @option args [String] :id,'id' id to assign to the alliance
  # @option args [Array<Users::User>] :members,'members' array of users to assign to the alliance
  # @option args [Array<Users::Alliance>] :enemies,'enemies' array of enemy alliances to assign to alliance
  # @option args [Array<String>] :member_ids,'member_ids' array of ids of users to lookup in the {Users::Registry} and add to the alliance
  # @option args [Array<String>] :enemy_ids,'enemy_ids' array of ids of enemy alliances to lookup in the {Users::Registry} and add to the alliance
  def initialize(args = {})
    @id       = args['id']       || args[:id]
    @members  = args['members']  || args[:members]   || []
    @enemies  = args['enemies']  || args[:enemies]   || []

    [:member_ids, 'member_ids'].each { |member_ids|
      args[member_ids].each { |member_id|
        member = Users::Registry.instance.find(:id => member_id).first
        unless member.nil?
          @members << member
          member.add_alliance self
        end
      } if args.has_key?(member_ids)
    }

    [:enemy_ids, 'enemy_ids'].each { |enemy_ids|
      args[enemy_ids].each { |enemy_id|
        enemy = Users::Registry.instance.find(:id => enemy_id).first
        unless enemy.nil?
          @enemies << enemy
          enemy.add_enemy self
        end
      } if args.has_key?(enemy_ids)
    }

    #Users::Registry.instance.create self
  end

  # Add new enemy to alliance
  #
  # @param [Users::Alliance] enemy_alliance enemy to add to alliance
  def add_enemy(enemy_alliance)
    @enemies << enemy_alliance unless !enemy_alliance.is_a?(Users::Alliance) ||
                                      @enemies.collect { |e| e.id }.
                                        include?(enemy_alliance.id) ||
                                      enemy_alliance.id == id
  end

  # Convert alliance to human readable string and return it
  def to_s
    "alliance-#{@id}"
  end

  # Convert alliance to json representation and return it
  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       => {:id => id,
                       :member_ids => members.collect { |m| m.id },
                       :enemy_ids  => enemies.collect { |e| e.id }}
    }.to_json(*a)
  end

  # Create new alliance from json representation
  def self.json_create(o)
    alliance = new(o['data'])
    return alliance
  end

end
end
