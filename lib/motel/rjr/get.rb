# [motel::get_locations, motel::get_location] rjr definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

get_location = proc { |*args|
  return_first = false
  filters = []
  while qualifier = args.shift
    raise ArgumentError, "invalid qualifier #{qualifier}" unless ["with_id", "within"].include?(qualifier)
    filter = case qualifier
               when "with_id"
                 return_first = true
                 val = args.shift
                 raise ArgumentError, "qualifier #{qualifier} requires value" if val.nil?
                 lambda { |loc| loc.id == val }
               when "within"
                 distance = args.shift
                 raise ArgumentError, "qualifier #{qualifier} requires int or float distance > 0" if distance.nil? || (!distance.is_a?(Integer) && !distance.is_a?(Float)) || distance <= 0
                 qualifier = args.shift
                 plocation  = args.shift
                 raise ArgumentError, "must specify 'of location' when specifing 'within distance'" if qualifier != "of" || plocation.nil? || !plocation.is_a?(Motel::Location)
                 lambda { |loc| loc.parent_id == plocation.parent_id &&
                                (loc - plocation) <= distance }
               # when "of_type" # allow & ensure "Motel::Location" for compatability reasons?
             end
    filters << filter
  end

  locs = Runner.instance.locations
  filters.each { |f| locs = locs.select &f }

  if return_first
    raise Omega::DataNotFound, "location specified by id not found" if locs.empty?
    Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "location-#{locs.first.id}"},
                                               {:privilege => 'view', :entity => 'locations'}],
                                      :session => @headers['session_id']) if locs.first.restrict_view
  end

  locs.reject! { |loc|
    loc.restrict_view &&
    !Users::Registry.check_privilege(:any => [{:privilege => 'view', :entity => "location-#{loc.id}"},
                                              {:privilege => 'view', :entity => 'locations'}],
                                     :session => @headers['session_id'])
  }

  return_first ? locs.first : locs
}

def dispatch_get(dispatcher)
  dispatcher.handle ['motel::get_location', 'motel::get_locations'],
                                                      &get_location
end
