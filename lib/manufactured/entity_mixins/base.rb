# Manufactured Base EntityMixin definition
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/constraints'

module Manufactured
module Entity
  module Base
    include Omega::ConstrainedAttributes

    def self.included(base)
      base.extend(ClassMethods)
      base.inherit_constraints self
    end

    # Unique string id of the entity
    attr_accessor :id

    # ID of user which entity belongs to
    attr_accessor :user_id

    # General category / classification of entity
    constrained_attr :type, :constraint => :types,
                            :writable   =>   true,
                            :nullable   =>   true,
                            :intern     =>   true

    # Size of the entity
    constrained_attr(:size, :intern     => :true,
                            :constraint => :sizes) { |sizes| sizes[type] }

    # Initialize base attributes from args
    def base_attrs_from_args(args)
      attr_from_args args, :id      => nil,
                           :user_id => nil,
                           :type    => nil
    end

    # Return boolean indicating if base attributes are valid
    def base_attrs_valid?
      id_valid? && user_id_valid? && type_valid?
    end

    # Return boolean indicating if id is valid
    def id_valid?
      !@id.nil? && @id.is_a?(String) && @id != ""
    end

    # Return boolean indicating if user_id is valid
    def user_id_valid?
      !@user_id.nil? && @user_id.is_a?(String)
    end

    # Return boolean indicating if type is valid
    def type_valid?
      !@type.nil? && self.class.types.include?(@type)
    end

    # Return base entity attributes in json format
    def base_json
      {:id => id, :user_id => user_id, :type => type, :size => size}
    end

    module ClassMethods
      # List of acceptable types
      def types
        @types ||= get_constraint 'types', constraint_opts(:type)
      end

      # List of acceptable sizes
      def sizes
        @sizes ||= get_constraint 'sizes', constraint_opts(:size)
      end
    end
  end # module Base
end # module Entity
end # module Manufactured
