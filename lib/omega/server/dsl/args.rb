# Omega Server DSL args operations
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Omega
  module Server
    module DSL
      # Filter properties able / not able to be set by the end user
      def filter_properties(data, filter = {})
        is_hash = data.is_a?(Hash)
        ndata   = is_hash ? {} : data.class.new
        if filter[:allow]
          filter[:allow] = [filter[:allow]] unless filter[:allow].is_a?(Array)
          # copy allowed attributes over
          filter[:allow].each { |a|
            if is_hash
              # TODO ensure data key strings include a before interning
              ndata[a.intern] = data[a.intern] || data[a.to_s]
            else
              # TODO ensure a.responds to a before interning
              ndata.send("#{a}=".intern, data.send(a.intern))
            end
          }

        else
          # TODO copy all attributes over

        end

        # if filter[:reject] TODO

        return ndata
      end

      # Return a list of filters constructed from the specified args
      #
      # @example generating filters from args
      #   def get_data(*args)
      #     filters =
      #       filters_from_args args,
      #         :with_id   => proc { |e, id| e.id == id },
      #         :between   => proc { |e, lval, gval|
      #           e.value < gval && e.value > lval
      #         }
      #
      #      return my_entities.all? { |e| filters.all? { |f| f.call(e) } }
      #    end
      #
      #    get_data(:with_id, 'foo')
      #    get_data(:with_id, 'bar',
      #             :between, 0, 5)
      #    get_data(:with_property, "foobar")
      #    #=> raises error since "with_property" not defined
      def filters_from_args(args, allowed_filters)
        filters = []

        # create copy of args list so as to modify
        nargs   = Array.new(args)

        # shift first argument of from list (the filter id)
        while arg = nargs.shift

          # find the filter with the same key as the filter id
          filter = allowed_filters.find { |k,v| k.to_s == arg.to_s }

          # raise error if it could not be found
          raise ValidationError, "invalid filter #{arg}" if filter.nil?
          filter = filter.last

          # shift number of arguments off list corresponding to the
          # arity of the filter method (minus one, assume first param
          # is for the entity to match with the filter)
          params  = []
          nparams = filter.arity - 1 #
          0.upto(nparams - 1) {
            params << nargs.shift
          } if nparams > 0

          # addd a procedure calling the filter with the
          # specified entity and parameter list to the filter list
          # XXX need to define/call an inline function to bind filter/params variables
          filters << proc { |f,p| proc { |e| f.call e, *p } }.call(filter, params)
        end

        filters
      end
    end # module DSL
  end # module Server
end # module Omega
