# systems_with_most stat
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Stats
  # Return list of up to <num_to_return> system ids sorted
  # by the number of the specified entity they are associated with
  systems_with_most_proc = proc { |entity_type, num_to_return|
    system_ids = []
  
    case entity_type
    # sort cosmos systems by # of entities in them
    when "entities" then
      all_systems =
        Stats::RJR.node.invoke('cosmos::get_entities',
                               'of_type', 'Cosmos::Entities::SolarSystem',
                               'children', false, 'select', ['id']).
        collect { |s| s.id }
  
      system_ids =
        Stats::RJR.node.invoke('manufactured::get_entities', 'select', ['system_id']).
                inject(Hash.new(0)) { |h,e|
                   h[e.system_id] += 1; h
                }.sort_by { |k,v| v }.reverse.
                collect { |e| e.first }
  
      # append the systems w/ 0 entities
      all_systems -= system_ids
      system_ids  += all_systems
  
    end
  
    num_to_return ||= system_ids.size
  
    # return
    system_ids[0...num_to_return]
  }
  
  systems_with_most = Stat.new(:id => :systems_with_most,
                        :description => 'Systems w/ the most entities',
                        :generator => systems_with_most_proc)

  register_stat systems_with_most
end # module Stats
