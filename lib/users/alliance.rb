# Users module alliance definition
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Users
class Alliance
  attr_reader   :id
  attr_accessor :members
  attr_accessor :enemies

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

  def add_enemy(enemy_alliance)
    @enemies << enemy_alliance unless @enemies.include?(enemy_alliance)
  end

  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       => {:id => id,
                       :member_ids => members.collect { |m| m.id },
                       :enemy_ids  => enemies.collect { |e| e.id }}
    }.to_json(*a)
  end

  def self.json_create(o)
    alliance = new(o['data'])
    return alliance
  end

end
end
