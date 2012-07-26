# omega config data
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'yaml'

module Omega

class Config
   CONFIG_FILES = ['/etc/omega.yml', '~/.omega.yml', './omega.yml']

  def self.load(defaults = {})
    c = Config.new defaults

    CONFIG_FILES.each { |f|
      ff = File.expand_path(f)
      if File.file?(ff)
        c.update! YAML.load(File.open(ff))
      end
    }

    c
  end

  def initialize(data={})
    @data = {}
    update!(data)
  end

  def has_attributes?(*required_attributes)
    # TODO multilevel / hash
    required_attributes.flatten.each { |attr|
      return false if !@data.has_key?(attr) || @data[attr].nil? || @data[attr] == ""
    }
    return true
  end

  def update!(data)
    data.each do |key, value|
      self[key] = value
    end
  end

  def [](key)
    @data[key.to_sym]
  end

  def []=(key, value)
    if value.class == Hash
      @data[key.to_sym] = Config.new(value)
    else
      @data[key.to_sym] = value
    end
  end

  def method_missing(sym, *args)
    if sym.to_s =~ /(.+)=$/
      self[$1] = args.first
    else
      self[sym]
    end
  end

end
end
