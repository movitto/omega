# [motel::get_locations, motel::get_location] rjr definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'motel/rjr/init'

module Motel::RJR
# retrieve locations filtered by args
get_location = proc { |*args|
  # retrieve locations matching filters specified by args
  filters = filters_from_args args,
    :with_id => proc { |l, id| l.id == id },
    :within  => proc { |l, d, of, loc|
      if !(d.numeric? && d > 0)
        raise ValidationError, "distance must be > 0"

      elsif of != "of"
        raise ValidationError, "filter must be: within <distance> of <loc>"

      elsif !loc.is_a?(Location)
        raise ValidationError, "valid location must be specified"

      end

      l.parent_id == loc.parent_id && l - loc <= d
    },
    :children  => proc { |l, v| true },
    :recursive => proc { |l, v| true }
  locs = registry.entities { |e| filters.all? { |f| f.call(e) }}

  return_first       =  args.include?('with_id')
  include_children   = !args.include?('children')  || args[args.index('children')  + 1]
  recursive_children = !args.include?('recursive') || args[args.index('recursive') + 1]

  if include_children
    # only include first level descendents if recursive is false
    unless recursive_children
      locs.each { |loc|
        loc.children.each { |child| child.children = [] }
      }
    end

  # swap children w/ their id's if include_children is false
  else
    locs.each { |loc|
      loc.children.each_index { |i|
        loc.children[i] = loc.children[i].id
      }
    }
  end

  # if id of location to retrieve is specified, only return a single location
  if return_first
    locs = locs.first

    # make sure the location was found
    id = args[args.index('with_id') + 1]
    raise DataNotFound, id if locs.nil?

    # make sure the user has privileges on the specified location
    require_privilege :registry => user_registry, :any =>
      [{:privilege => 'view', :entity => "location-#{locs.id}"},
       {:privilege => 'view', :entity => 'locations'}] if locs.restrict_view

  # else return an array of locations which the user has access to
  else
    locs.reject! { |loc|
      loc.restrict_view &&
      !check_privilege(:registry => user_registry, :any =>
        [{:privilege => 'view', :entity => "location-#{loc.id}"},
         {:privilege => 'view', :entity => 'locations'}])
    }

  end

  locs
}

GET_METHODS = { :get_location => get_location }
end

def dispatch_motel_rjr_get(dispatcher)
  m = Motel::RJR::GET_METHODS
  dispatcher.handle ['motel::get_location', 'motel::get_locations'],
                                                  &m[:get_location]
end
