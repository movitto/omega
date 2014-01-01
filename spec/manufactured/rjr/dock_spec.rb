# manufactured::dock,manufactured::undock tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'manufactured/rjr/dock'
require 'rjr/dispatcher'

module Manufactured::RJR
  describe "#dock", :rjr => true do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      setup_manufactured :DOCK_METHODS

      @sys = create(:solar_system)
      @sh = create(:valid_ship,    :solar_system => @sys)
      @st = create(:valid_station, :solar_system => @sys)

      @rsh,@rst = 
        @registry.safe_exec { |entities|
          [entities.find(&with_id(@sh.id)),
           entities.find(&with_id(@st.id))]
        }
      @rshl =
        Motel::RJR.registry.safe_exec { |entities|
          entities.find(&with_id(@sh.location.id))
        }
    end

    context "invalid ship id/type" do
      it "raises DataNotFound" do
        lambda {
          @s.dock 'invalid', @st.id
        }.should raise_error(DataNotFound)
        lambda {
          @s.dock @st.id, @st.id
        }.should raise_error(DataNotFound)
      end
    end

    context "invalid station id/type" do
      it "raises DataNotFound" do
        lambda {
          @s.dock @sh.id, 'invalid'
        }.should raise_error(DataNotFound)
        lambda {
          @s.dock @sh.id, @sh.id
        }.should raise_error(DataNotFound)
      end
    end

    context "insufficient permissions (modify-ship)" do
      it "raises PermissionError" do
        lambda {
          @s.dock @sh.id, @st.id
        }.should raise_error(PermissionError)
      end
    end

    context "sufficient permissions (modify-ship)" do
      before(:each) do
        add_privilege @login_role, 'modify', "manufactured_entities"
      end

      it "does not raise PermissionError" do
        lambda {
          @s.dock @sh.id, @st.id
        }.should_not raise_error
      end

      it "updates ship location" do
        Manufactured::RJR.node.should_receive(:invoke).
           with('motel::get_location', 'with_id', @rsh.location.id).and_call_original
        Manufactured::RJR.node.should_receive(:invoke).
           with{ |*a|
             a[0].should == 'motel::update_location'
             a[1].should be_an_instance_of(Motel::Location)
             a[1].id.should == @rsh.location.id
           }
        @s.dock @sh.id, @st.id
      end

      context "station cannot accept ship" do
        it "raises OperationError" do
          @rshl.x = @rst.location.x + @rst.docking_distance * 2
          lambda {
            @s.dock @sh.id, @st.id
          }.should raise_error(OperationError)
        end
      end

      context "ship cannot dock at station" do
        it "raises OperationError" do
          @rsh.hp = 0
          lambda {
            @s.dock @sh.id, @st.id
          }.should raise_error(OperationError)
        end
      end

      it "sets ship movement strategy to stopped" do
        @s.dock @sh.id, @st.id
        Motel::RJR.registry.entity(&with_id(@rsh.location.id)).
                                  movement_strategy.should ==
                              Motel::MovementStrategies::Stopped.instance
      end

      it "sets docked_at on ship to return" do
        r = @s.dock @sh.id, @st.id
        r.docked_at.id.should == @st.id
      end

      it "returns ship" do
        r = @s.dock @sh.id, @st.id
        r.should be_an_instance_of(Ship)
        r.id.should == @sh.id
      end
    end

  end # describe #dock

  describe "#undock", :rjr => true do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      setup_manufactured :DOCK_METHODS

      @sys = create(:solar_system)
      @st = create(:valid_station, :solar_system => @sys)
      @sh = create(:valid_ship,    :solar_system => @sys)

      @rsh,@rst = 
        @registry.safe_exec { |entities|
          [entities.find(&with_id(@sh.id)),
           entities.find(&with_id(@st.id))]
        }
      @rshl =
        Motel::RJR.registry.safe_exec { |entities|
          entities.find(&with_id(@sh.location.id))
        }

      @rsh.dock_at @rst
    end

    context "invalid ship id/type" do
      it "raises DataNotFound" do
        lambda {
          @s.undock 'invalid'
        }.should raise_error(DataNotFound)
        lambda {
          @s.undock @st.id
        }.should raise_error(DataNotFound)
      end
    end

    context "insufficient permissions (modify-ship)" do
      it "raises PermissionError" do
        lambda {
          @s.undock @sh.id
        }.should raise_error(PermissionError)
      end
    end

    context "sufficient permissions (modify-ship)" do
      before(:each) do
        add_privilege @login_role, 'modify', "manufactured_entities"
      end

      context "ship not docked" do
        it "raises OperationError" do
          @rsh.dock_at nil
          lambda {
            @s.undock @sh.id
          }.should raise_error(OperationError)
        end
      end

      it "undocks ship" do
        @s.undock @sh.id
        @rsh.docked_at.should be_nil
      end

      it "returns ship" do
        r = @s.undock @sh.id
        r.should be_an_instance_of(Manufactured::Ship)
        r.id.should == @sh.id
        r.docked_at.should be_nil
      end
    end
  end # describe #undock

  describe "#dispatch_manufactured_rjr_dock" do
    it "adds manufactured::dock to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_manufactured_rjr_dock(d)
      d.handlers.keys.should include("manufactured::dock")
    end

    it "adds manufactured::dock to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_manufactured_rjr_dock(d)
      d.handlers.keys.should include("manufactured::dock")
    end
  end
end #module Manufactured::RJR
