# callbacks module tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require File.dirname(__FILE__) + '/../spec_helper'

describe Manufactured::Callback do
  it "should invoke specified callback when prompted" do
    invoked1 = false
    invoked2 = false
    args1    = nil
    args2    = nil
    c1 = Manufactured::Callback.new('foobar', :handler => lambda { |arg|
      invoked1 = true
      args1 = arg
    })
    c2 = Manufactured::Callback.new('foobar'){ |*args|
      invoked2 = true
      args2 = args
    }

    invoked1.should be_false
    invoked2.should be_false

    c1.invoke 42
    c2.invoke "hello", "world"

    invoked1.should be_true
    invoked2.should be_true

    args1.should == 42
    args2.should include("hello")
    args2.should include("world")
  end

end
