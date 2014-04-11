# manufactured::construct_entity tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'manufactured/rjr/construct'
require 'rjr/dispatcher'

module Manufactured::RJR
  describe "#construct_entity", :rjr => true do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      setup_manufactured  :CONSTRUCT_METHODS
      @st = create(:valid_station)
      @construct = { :entity_type => 'Ship', :type => :frigate, :id => 'foobar' }
    end

    def build_ship
      sys = create(:solar_system)
      s = build(:valid_ship)
      s.user_id = @login_user.id
      s.solar_system = sys
      s
    end

    context "invalid manufacturer_id" do
      it "raises DataNotFound" do
        st = build(:valid_station)
        lambda {
          @s.construct_entity st.id, @construct
        }.should raise_error(DataNotFound)
      end
    end

    context "insufficient permissions (modify-manufactured_entities)" do
      it "raises PermssionError" do
        lambda {
          @s.construct_entity @st.id, @construct
        }.should raise_error(PermissionError)
      end
    end

    context "sufficient permissions (modify-manufactured_entities)" do
      before(:each) do
        add_privilege(@login_role, 'modify', 'manufactured_entities')
      end

      it "does not raise PermissionError" do
        lambda {
          @s.construct_entity @st.id, @construct
        }.should_not raise_error
      end

      it "filters all properties but id, type, and entity_type" do
        @registry.safe_exec { |es|
          rst = es.find(&with_id(@st.id))
          rst.should_receive(:can_construct?).
              with{ |*a|
                (a.first.keys - [:id, :type, :entity_type, :solar_system, :user_id]).should be_empty
              }.and_call_original
        }
        @s.construct_entity @st.id, @construct.merge({:resources => build(:resource)})
      end

      it "sets entity solar system" do
        r = @s.construct_entity @st.id, @construct
        r.last.system_id.should == @st.system_id
      end

      it "sets entity user id" do
        r = @s.construct_entity @st.id, @construct
        r.last.user_id.should == @login_user.id
      end

      context "station cannot construct entity" do
        it "raises OperationError" do
          @registry.safe_exec { |es|
            es.find(&with_id(@st.id)).
               should_receive(:can_construct?).and_return(false)
          }
          lambda{
            @s.construct_entity @st.id, @construct
          }.should raise_error(OperationError)
        end
      end

      it "constructs entity" do
        @registry.safe_exec { |es|
          es.find(&with_id(@st.id)).should_receive(:construct).and_call_original
        }
        @s.construct_entity @st.id, @construct
      end

      context "entity could not be constructed" do
        it "raises OperationError" do
          @registry.safe_exec { |es|
            es.find(&with_id(@st.id)).should_receive(:construct).and_return(nil)
          }
          lambda {
            @s.construct_entity @st.id, @construct
          }.should raise_error(OperationError)
        end
      end

      it "registers new construction command with registry" do
        lambda {
          @s.construct_entity @st.id, @construct
        }.should change{@registry.entities.size}.by(1)
        @registry.entities.last.should be_an_instance_of(Manufactured::Commands::Construction)
        @registry.entities.last.id.should == "#{@st.id}-#{@construct[:id]}"
      end

      it "returns [station,entity]" do
        r = @s.construct_entity @st.id, @construct
        r.first.should be_an_instance_of(Station)
        r.first.id.should == @st.id

        r.last.should be_an_instance_of(Ship)
        r.last.id.should == @construct[:id]
      end
    end
  end # describe #construct_entity

  describe "#dispatch_manufactured_rjr_construct" do
    it "adds manufactured::construct_entity to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_manufactured_rjr_construct(d)
      d.handlers.keys.should include("manufactured::construct_entity")
    end
  end
end #module Manufactured::RJR
