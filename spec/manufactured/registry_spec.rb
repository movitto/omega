# registry module tests
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
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

  context "adding command" do
    it "runs check_command" do
      r = Registry.new
      c = Omega::Server::Command.new
      r.should_receive(:check_command).with(c)
      r << c
    end
  end

  it "runs command loop" do
    r = Registry.new
    r.instance_variable_get(:@event_loops).should include{ run_commands }
  end

  describe "#stop_commands_for" do
    it "removes commands for which processes?(entity) returns true" do
      r = Registry.new
      e = {}
      c1 = Omega::Server::Command.new :id => 'cmd1'
      c2 = Omega::Server::Command.new :id => 'cmd2'

      c1.should_receive(:processes?).with(e).and_return(true)
      c2.should_receive(:processes?).with(e).and_return(false)
      r << c1
      r << c2

      r.stop_commands_for(e)
      r.entity { |e| e.id == 'cmd1' }.should be_nil
      r.entity { |e| e.id == 'cmd2' }.should_not be_nil
    end
  end

end # describe Registry
end # module Manufactured
