# omega config data
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'yaml'

module Omega

# Omega configuration manager, loads configuration options from
# config files, allowing the user to specify default values.
#
# Config options can be accessed directly through instances of this class
# and consist of key (symbol) / value pairs.
class Config

   # Omega config files in the order that they are loaded, eg options in
   # later entries in the array with override those in previous entries
   CONFIG_FILES = ['/etc/omega.yml', '~/.omega.yml', './omega.yml']

   # Omega classes which define the 'set_config' method taking an instance
   # of Omega::Config containing configuration options to set
   CONFIG_CLASSES = [Cosmos::RJRAdapter, Manufactured::RJRAdapter, Users::RJRAdapter,
                     Users::ChatProxy, Users::EmailHelper,
                     Motel::RemoteLocationManager, Cosmos::RemoteCosmosManager]

  # Instantiate new Config instance and load values from the config files
  #
  # @param [Hash] defaults default config options and their values to set
  #   before loading config files (options in config files will override defaults)
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

  # Initialize the configuration, specifying config options
  #
  # @param [Hash] data config options which to set
  def initialize(data={})
    @data = {}
    update!(data)
  end

  # Return boolean indicating if the config has the specified options
  # and they are not nil / blank.
  #
  # @param [Array] required_attributes array of config options to check for
  # @return [true, false] indicating if config options were found
  def has_attributes?(*required_attributes)
    # TODO multilevel / hash
    required_attributes.flatten.each { |attr|
      return false if !@data.has_key?(attr) || @data[attr].nil? || @data[attr] == ""
    }
    return true
  end

  # Update the config with the specified data
  #
  # @param [Hash] data hash of key / value pairs to add to the config, overriding
  #   previously set options w/ corresponding keys
  def update!(data)
    data.each do |key, value|
      self[key] = value
    end
  end

  # Return value for the specified key
  #
  # @param [Symbol,String] key key to lookup
  # @return [Object] value of the config option, nil if not found
  def [](key)
    @data[key.to_sym]
  end

  # Set the value of the specified config option
  #
  # @param [Symbol,String] key config option to set the value of
  # @param [Object] value to set the config option to
  def []=(key, value)
    if value.class == Hash
      @data[key.to_sym] = Config.new(value)
    else
      @data[key.to_sym] = value
    end
  end

  # Return or set value of the config option specified by the name
  #   of a missing method invoked on the config object
  def method_missing(sym, *args)
    if sym.to_s =~ /(.+)=$/
      self[$1] = args.first
    else
      self[sym]
    end
  end

  # Set local config on Omega classes specified by CONFIG_CLASSES above.
  # If specified only the classes given will have their config set.
  #
  # @param [Array<Class>] optional array of classes which to restrict
  #   setting of the configuration to
  def set_config(classes = CONFIG_CLASSES)
    classes.each { |kls|
      kls.set_config(self)
    }
    self
  end

end
end
