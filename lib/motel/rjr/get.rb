# [motel::get_locations, motel::get_location] rjr definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

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
    }
  locs = self.entities.select { |e| filters.all? { |f| f.call(e) }}

  # if id of location to retrieve is specified, only return a single location
  return_first = args.include?(:with_id)
  if return_first
    locs = locs.first

    # make sure the location was found
    id = args[args.index(:with_id) + 1]
    raise DataNotFound, (id) if locs.nil

    # make sure the user has privileges on the specified location
    require_privilege :any =>
      [{:privilege => 'view', :entity => "location-#{locs.id}"},
       {:privilege => 'view', :entity => 'locations'}] if locs.restrict_view

  # else return an array of locations which the user has access to
  else
    locs.reject! { |loc|
      loc.restrict_view &&
      !check_privilege(:any => [{:privilege => 'view', :entity => "location-#{loc.id}"},
                                {:privilege => 'view', :entity => 'locations'}])
    }

  end

  locs
}

def dispatch_get(dispatcher)
  dispatcher.handle ['motel::get_location', 'motel::get_locations'],
                                                      &get_location
end
