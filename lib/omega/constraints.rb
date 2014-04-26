# Mechanisms for loading constraints data
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'json'
require 'omega/common'

module Omega
  # TODO document
  module Constraints
    def self.data_path
      @data_path ||= File.join(File.dirname(__FILE__), 'constraints.json')
    end

    def self.data
      @data ||= JSON.parse(File.read(data_path))
    end

    def self.coin_flip
      (rand * 2).floor == 0
    end

    def self.get(*target)
      current = data
      target.each { |t|
        current = current[t]
        return nil unless current
      }
      current
    end

    def self.deviation(*target)
      ntarget = Array.new(target)
      ntarget[ntarget.size-1] += 'Deviation'
      get *ntarget
    end

    def self.randomize(base, deviation=nil)
      return "%06x" % (rand * 0xffffff) if base == "rgb"
      return base unless deviation
      return base + rand * deviation * (coin_flip ? 1 : -1) if base.numeric?

      nx = coin_flip ? 1 : -1
      ny = coin_flip ? 1 : -1
      nz = coin_flip ? 1 : -1
      {'x' => base['x'] + rand * deviation['x'] * nx,
       'y' => base['y'] + rand * deviation['y'] * ny,
       'z' => base['z'] + rand * deviation['z'] * nz}
    end

    def self.rand_invert(value)
      return value * (coin_flip ? 1 : -1) if value.numeric?

      nx = coin_flip ? 1 : -1
      ny = coin_flip ? 1 : -1
      nz = coin_flip ? 1 : -1
      {'x' => value['x'] * nx, 'y' => value['y'] * ny, 'z' => value['z'] * nz}
    end

    def self.gen(*target)
      base   = get *target
      deviat = deviation *target
      randomize(base, deviat)
    end

    def self.max(*target)
      base  = get *target
      deriv = deviation *target
      return base unless deriv
      return base + deriv if base.numeric?
      {'x' => base['x'] + deriv['x'],
       'y' => base['y'] + deriv['y'],
       'z' => base['z'] + deriv['z']}
    end

    def self.min(*target)
      base  = get *target
      deriv = deviation *target
      return base unless deriv
      return base - deriv if base.numeric?
      {'x' => base['x'] - deriv['x'],
       'y' => base['y'] - deriv['y'],
       'z' => base['z'] - deriv['z']}
    end

    def self.valid?(value, *target)
      base = get *target
      return value =~ /^[a-fA-F0-9]{6}$/ if base == "rgb"

      vmax = max(*target)
      vmin = min(*target)
      return value.abs <= vmax && value.abs >= vmin if value.numeric?
      value['x'].abs <= vmax['x'] && value['x'].abs >= vmin['x'] &&
      value['y'].abs <= vmax['y'] && value['y'].abs >= vmin['y'] &&
      value['z'].abs <= vmax['z'] && value['z'].abs >= vmin['z']
    end
  end # module Constraints

# TODO move into its own file
  module ConstrainedAttributes
    def self.included(base)
      base.extend(ClassMethods)
    end

    # Explicity set instance var
    def explicitly_set!(attr, value)
      instance_variable_set("@#{attr}", value)
      instance_variable_set("@set_#{attr}", true)
    end

    # Return bool indicating if constraint was explicity set
    def explicitly_set?(attr)
      instance_variable_get("@set_#{attr}")
    end

    # Return explicit value set
    def explicit_value(attr)
      instance_variable_get("@#{attr}")
    end

    # Return the owner of the constraints
    def constraint_owner
      self.class.include?(Omega::ConstrainedAttributes) ? self.class : self
    end

    module ClassMethods
      # Get / Set constraint domain, or custom prefix prepended to constraints
      # before lookup. Default to lower-case demodulized class name
      def constraint_domain(val=nil)
        @constraint_domain   = val.to_s unless val.nil?
        @constraint_domain ||= self.to_s.demodulize.downcase
        @constraint_domain
      end

      # Retrieve specified constraint
      #
      # TODO cache after retrieved ?
      def get_constraint(constraint, opts={})
        constraint = [constraint].flatten.collect { |c| c.to_s }
        value = Omega::Constraints.get *constraint

        # on failure attempt to prepend constraint domain & rerun retrieval
        if value.nil?
          constraint.unshift constraint_domain
          value = Omega::Constraints.get *constraint
        end

        if opts[:intern]
          if value.is_a?(Array)
            value.map! { |v| v.intern }

          elsif value.is_a?(Hash)
            value.keys.each { |k|
              value[k.intern] = value.delete(k)
            }

          elsif !value.nil?
            value = value.intern

          end
        end

        value
      end

      # Return boolean indicating if constraint is valid
      def constraint_satisfied?(constraint, new_value, opts={})
        value = get_constraint constraint, opts
        if value.is_a?(Array)
          value.include?(new_value)
        elsif opts[:qualifier] == "<="
          new_value <= value

        elsif opts[:qualifier] == ">="
          new_value >= value

        else
          value == new_value
        end
      end


      # Return a new procedure which to read constraint value or
      # overridden value.
      def constraint_reader(attr, constraint, opts={})
        proc {
          value = constraint_owner.get_constraint constraint, opts

          if explicitly_set?(attr)
            explicit_value(attr)
          elsif opts[:nullable]
            nil
          else
            value
          end
        }
      end

      # Return a new procedure which returns value of block invoked w/
      # constraint value
      def constraint_wrapper(attr, constraint, opts={}, &bl)
        proc { instance_exec constraint_owner.get_constraint(constraint, opts), &bl }
      end

      # Return procedure that writes the constraint attribute
      def constraint_writer(attr, constraint, opts={})
        proc { |new_value|
          new_value = new_value.intern if (opts[:intern] && !new_value.nil?)

          # ensure constraint is valid
          satisfied = constraint_owner.constraint_satisfied?(constraint, new_value, opts)
          nullable  = opts[:nullable] && new_value.nil?
          raise ArgumentError, [attr, new_value] unless satisfied || nullable

          # explicity set attribute
          explicitly_set! attr, new_value
        }
      end

      # Create a new constraint attribute using the specified attribute name
      # (and optional constraint key). Will define a reader and optionally a
      # writer to get/set the attribute
      def constrained_attr(attr, opts={}, &bl)
        # store constraint opts so as to be available later
        constraint_opts(attr, opts)

        # generate specified constraint else use attribute,
        # defer loading of constraint till needed in accessors
        # so as to properly pull in full restraint content
        constraint = opts[:constraint] || attr

        # define reader
        reader = bl ? constraint_wrapper(attr, constraint, opts, &bl) :
                       constraint_reader(attr, constraint, opts)
        define_method(attr.intern, &reader)

        # define writer if specified
        if opts[:writable]
          writer = constraint_writer(attr, constraint, opts)
          define_method("#{attr}=".intern, &writer)
        end

        # return nil
        nil
      end

      # Return opts used to define constraint attribute
      def constraint_opts(attr=nil, opts=nil)
        @constrained_attrs ||= {}
        @constrained_attrs[attr] = opts unless opts.nil?
        attr.nil? ? @constrained_attrs : @constrained_attrs[attr]
      end

      # Copy constraint option accessors
      def copy_constraints(from)
        from.constraint_opts.each { |k,v| constraint_opts(k, v) }
      end
      alias :inherit_constraints :copy_constraints
    end # module ClassMethods
  end # module ConstrainedAttributes
end # module Omega
