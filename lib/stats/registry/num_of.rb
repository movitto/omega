# num_of stat
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Stats
  # Return number of specified entity
  num_of_proc = proc { |entity_type|
    case entity_type
    when "users" then
      Stats::RJR.node.invoke('users::get_entities', 'of_type', 'Users::User').size
  
    when "entities" then
      Stats::RJR.node.invoke('manufactured::get_entities').size
  
    when "ships" then
      Stats::RJR.node.invoke('manufactured::get_entities',
                        'of_type', 'Manufactured::Ship').size
  
    when "stations" then
      Stats::RJR.node.invoke('manufactured::get_entities',
                        'of_type', 'Manufactured::Station').size
  
    when "galaxies" then
      Stats::RJR.node.invoke('cosmos::get_entities',
                        'of_type', 'Cosmos::Entities::Galaxy').size
  
    when "solar_systems" then
      Stats::RJR.node.invoke('cosmos::get_entities',
                        'of_type', 'Cosmos::Entities::SolarSystem').size
  
    when "planets" then
      Stats::RJR.node.invoke('cosmos::get_entities',
                        'of_type', 'Cosmos::Entities::Planet').size
  
    when "missions" then
      Stats::RJR.node.invoke('missions::get_missions').size
  
    else
      nil
    end
  }
  
  num_of = Stat.new(:id => :num_of,
                    :description => 'Total number of entities',
                    :generator   => num_of_proc)

  register_stat num_of
end # module Stats
