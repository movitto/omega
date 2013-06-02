# Rotation Callback tests
#
# Copyright (C) 2010-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'motel/location'
require 'motel/callbacks/rotation'

module Motel::Callbacks
describe Rotation do
  describe "should_invoke?" do
    it "should return true" do
      r = Rotation.new
      r.should_invoke?(build(:location), 0, 0, 0).should be_true
    end

    context "minimum rotation set" do
      context "location rotated minimum rotation" do
        it "returns true" do
          l = Motel::Location.new :orientation => [0,0,1]

          r = Rotation.new :min_rotation => 3.13
          r.should_invoke?(l, 0, 0, -1).should be_true
        end
      end

      context "location did not rotate minimum rotation" do
        it "returns false" do
          l = Motel::Location.new :orientation => [0,0,1]

          r = Rotation.new :min_rotation => 3.13
          r.should_invoke?(l, 0, 0, 1).should be_false

          r = Rotation.new :min_rotation => 3.13
          r.should_invoke?(l, 0.57, 0.57, 0.57).should be_false
        end
      end
    end

    context "min theta set" do
      context "location rotated min theta" do
        it "returns true" do
          l = Motel::Location.new :orientation => [0,0,1]
          r = Rotation.new :min_theta => 3.14
          r.should_invoke?(l, 0, 0, -1).should be_true
        end
      end

      context "location did not rotate min theta" do
        it "returns false" do
          l = Motel::Location.new :orientation => [0,0,1]
          r = Rotation.new :min_theta => 3.14
          r.should_invoke?(l, 0, 0, 1).should be_false

          r = Rotation.new :min_theta => 3.14
          r.should_invoke?(l, 0.57, 0.57, 0.57).should be_false

          r = Rotation.new :min_theta => 3.14
          r.should_invoke?(l, 0, -1, 1).should be_false
        end
      end
    end

    context "min phi set" do
      context "location rotated min phi" do
        it "returns true" do
          l = Motel::Location.new :orientation => [0,0,1]
          r = Rotation.new :min_phi => 3.13
          r.should_invoke?(l, -1, 0, 0).should be_true
        end
      end

      context "location did not rotate min phi" do
        it "returns false" do
          l = Motel::Location.new :orientation => [0,0,1]
          r = Rotation.new :min_phi => 3.13
          r.should_invoke?(l, 0, 0, 1).should be_false

          r = Rotation.new :min_phi => 3.13
          r.should_invoke?(l, 0.57, 0.57, 0.57).should be_false

          r = Rotation.new :min_phi => 3.13
          r.should_invoke?(l, 0, 0, -1).should be_false
        end
      end
    end
  end

  describe "#invoke" do
    it "invokes handler with rotation,dt,dp"
    it "resets tracked orientation"
  end

  describe "#to_json" do
    it "returns callback in json format" do
      cb = Rotation.new :endpoint_id => 'baz',
                        :min_rotation => 3.14,
                        :min_theta    => 0.56

      j = cb.to_json
      j.should include('"json_class":"Motel::Callbacks::Rotation"')
      j.should include('"endpoint_id":"baz"')
      j.should include('"min_rotation":3.14')
      j.should include('"min_theta":0.56')
    end
  end

  describe "#json_create" do
    it "returns callback from json format" do
      j = '{"json_class":"Motel::Callbacks::Rotation","data":{"endpoint_id":"baz","min_phi":1.78}}'
      cb = JSON.parse(j)

      cb.class.should == Motel::Callbacks::Rotation
      cb.endpoint_id.should == "baz"
      cb.min_phi.should == 1.78
    end
  end

end # describe Rotation
end # module Motel::Callbacks
