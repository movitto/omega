# registry module tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'manufactured/registry'

module Manufactured
describe Registry do
  [:ship, :station, :loot].each { |e|
    it "provides access to #{e}" do
      f = "valid_#{e}".intern
      g = e == :loot ? e : "#{e}s".intern
      r = Registry.new
      r << build(f)
      r << build(f)
      r << build(e == :ship ? :valid_station : :valid_ship)
      r.send(e == :loot ? e : "#{e}s".intern).size.should == 2
    end
  }

  context "adding entity" do
    it "resolves system references"

    it "enforces entity types" do
      g = build(:galaxy)
      r = Registry.new
      (r << g).should be_false
    end

    it "enforces unique ids" do
      s = build(:valid_ship)
      r = Registry.new
      (r << s).should be_true
      r.entities.size.should == 1

      (r << s).should be_false
      r.entities.size.should == 1
    end

    it "enforces entity validity" do
      s = build(:ship)
      s.id = nil
      r = Registry.new
      (r << s).should be_false
    end
  end

  it "runs command loop" do
    r = Registry.new
    r.instance_variable_get(:@event_loops).should include{ run_commands }
  end

end # describe Registry
end # module Manufactured
