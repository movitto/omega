# omega config module tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

describe Omega::Config do
  before(:each) do
  end

  it "should load config overwriting defaults" do
    #oatimes = Omega::Config::CONFIG_FILES.collect { |c| File.atime(c) if File.exists?(c) }
    local = YAML.load(File.open("./omega.yml"))
    conf  = Omega::Config.load :omega_url => local["omega_url"] + "different"
    local.each { |k,v|
      conf[k].should == v
    }
    #Omega::Config::CONFIG_FILES.each_index { |ci|
    #  c = Omega::Config::CONFIG_FILES[ci]
    #  File.atime(c).should > oatimes[ci] if File.exists?(c)
    #}
  end

  it "should get/set/verify config" do
    conf  = Omega::Config.new
    conf.has_attributes?(:foobar).should be_false
    conf[:foobar] = :baz
    conf[:foobar].should == :baz
    conf.has_attributes?(:foobar).should be_true
    conf.has_attributes?(:money).should be_false
  end

  it "should update config" do
    conf  = Omega::Config.new
    conf[:foobar] = :baz
    conf.update!({:foobar => :money})
    conf[:foobar].should == :money
  end

  it "should set config on specified classes" do
    conf  = Omega::Config.new
    receiver = mock(Object, :set_config => conf)
    conf.set_config([receiver])
  end
end
