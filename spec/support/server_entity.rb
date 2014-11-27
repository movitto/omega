# Omega Spec Server Entity
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module OmegaTest
  class ServerEntity
    attr_accessor :id, :val
    def initialize(args={})
      attr_from_args args, :id => nil, :val => nil
    end

    def to_json(*a)
      { 'json_class' => self.class.name, 'data' => { :id => id, :val => val }}.to_json(*a)
    end

    def self.json_create(o)
      self.new(o['data'])
    end

    def ==(other)
      other.is_a?(ServerEntity) && other.id == id && other.val == val
    end
  end
end
