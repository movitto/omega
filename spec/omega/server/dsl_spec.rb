# Omega Server DSL tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'ostruct'

require 'spec_helper'
require 'omega/server/dsl'

require 'rjr/nodes/local'
require 'rjr/nodes/tcp'
require 'users/session'

require 'users/attributes/other'
require 'missions/event_handler'

module Omega
module Server
describe DSL do
  include Omega::Server::DSL

  before(:each) do
    @anon = create(:anon)
    @rjr_node = @n
    @rjr_headers = {}
  end

  describe "#login", :rjr => true do
    it "invokes remote login" do
      lambda {
        login @n, @anon.id, @anon.password
      }.should change{Users::RJR.registry.entities.size}.by(1)
    end

    it "returns session" do
      s = login @n, @anon.id, @anon.password
      s.should be_an_instance_of Users::Session
    end

    it "sets node session_id" do
      s = login @n, @anon.id, @anon.password
      @n.message_headers['session_id'].should == s.id
    end
  end

  describe "#is_node?" do
    context "node is of specified type" do
      it "returns true" do
        is_node?(RJR::Nodes::Local).should be_true
      end
    end

    context "node is not of specified type" do
      it "returns false" do
        is_node?(RJR::Nodes::TCP).should be_false
      end
    end
  end
  
  describe "#persistent_transport?" do
    context "rjr node is persistent" do
      before(:each) do
        @rjr_node = Object.new
        @rjr_node.stub(:persistent?).and_return(true)
      end

      it "returns true" do
        persistent_transport?.should be_true
      end
    end

    context "rjr node is not persistent" do
      before(:each) do
        @rjr_node = Object.new
        @rjr_node.stub(:persistent?).and_return(false)
      end

      it "returns false" do
        persistent_transport?.should be_false
      end
    end
  end

  describe "#require_persistent_transport!" do
    context "transport is persistent" do
      before(:each) do
        @rjr_node = Object.new
        @rjr_node.stub(:persistent?).and_return(true)
      end

      it "does not raise error" do
        lambda {
          require_persistent_transport!
        }.should_not raise_error
      end
    end

    context "transport is not persistent" do
      before(:each) do
        @rjr_node = Object.new
        @rjr_node.stub(:persistent?).and_return(false)
      end

      it "raises OperationError" do
        lambda {
          require_persistent_transport!
        }.should raise_error(OperationError)
      end
    end
  end

  describe "#from_valid_source?" do
    before(:each) do
      @rjr_headers = {}
    end

    context "source_node rjr header is a non empty string" do
      it "returns true" do
        @rjr_headers['source_node'] = 'node-user1'
        from_valid_source?.should be_true
      end
    end

    context "source_node rjr header is anything else" do
      it "returns false" do
        from_valid_source?.should be_false

        @rjr_headers['source_node'] = ''
        from_valid_source?.should be_false

        @rjr_headers['source_node'] = 42
        from_valid_source?.should be_false
      end
    end
  end

  describe "#require_valid_source!" do
    before(:each) do
      @rjr_headers = {}
    end

    context "valid source node" do
      it "does not raise error" do
        @rjr_headers['source_node'] = 'node-user1'
        lambda {
          require_valid_source!
        }.should_not raise_error
      end
    end

    context "invalid source node" do
      it "raises PermissionError" do
        lambda {
          require_valid_source!
        }.should raise_error(PermissionError)
      end
    end
  end

  describe "#require_privilege", :rjr => true do
    before(:each) do
      @rjr_headers['session_id'] = login(@n, @anon.id, @anon.password).id
    end

    context "user has privilege" do
      it "does not throw error" do
        lambda {
          require_privilege :registry => Users::RJR.registry,
                            :privilege => 'view', :entity => "user-#{@anon.id}"
        }.should_not raise_error
      end
    end

    context "user does not have privilege" do
      it "throws error" do
        lambda {
          require_privilege :registry => Users::RJR.registry,
                            :privilege => 'modify', :entity => 'users'
        }.should raise_error(Omega::PermissionError)
      end
    end
  end

  describe "#check_privilege", :rjr => true do
    before(:each) do
      @rjr_headers['session_id'] = login(@n, @anon.id, @anon.password).id
    end

    context "user has privilege" do
      it "returns true" do
        check_privilege(:registry => Users::RJR.registry,
                        :privilege => 'view', :entity => "user-#{@anon.id}").should be_true
      end
    end

    context "user does not have privilege" do
      it "return false" do
        check_privilege(:registry => Users::RJR.registry,
                        :privilege => 'modify', :entity => 'users').should be_false
      end
    end
  end

  describe "#current_user", :rjr => true do
    it "return registry user corresponding to session_id header" do
      @rjr_headers['session_id'] = login(@n, @anon.id, @anon.password).id
      u = current_user(:registry => Users::RJR.registry)
      u.should be_an_instance_of(Users::User)
      u.id.should == @anon.id
    end
  end

  describe "#current_session", :rjr => true do
    it "returns registry session corresponding to session_id header" do
      @rjr_headers['session_id'] = login(@n, @anon.id, @anon.password).id
      s = current_session(:registry => Users::RJR.registry)
      s.should be_an_instance_of(Users::Session)
      s.id.should == @rjr_headers['session_id']
    end
  end

  describe "#validate_session_source!", :rjr => true do
    before(:each) do
      session = login(@n, @anon.id, @anon.password)
      @rjr_headers['session_id'] = session.id
      @rjr_headers['source_node'] = session.endpoint_id
    end

    context "current session endpoint doesn't match source_node rjr header" do
      it "raises PermissionError" do
        @rjr_headers['source_node'] = 'something_else'
        lambda {
          validate_session_source! :registry => Users::RJR.registry
        }.should raise_error(PermissionError)
      end
    end

    context "current sesison endpoint matches source_node rjr header" do
      it "does not raise and error" do
        lambda {
          validate_session_source! :registry => Users::RJR.registry
        }.should_not raise_error
      end
    end
  end

  describe "#check_attribute", :rjr => true do
    MAL = Users::Attributes::MissionAgentLevel.id

    before(:each) do
      # login so as to be able to access user attributes
      login @n, @anon.id, @anon.password
    end

    around(:each) do |example|
      enable_attributes {
        example.run
      }
    end

    context "user does not have attribute" do
      it "returns false" do
        check_attribute(:node    => @n,
                        :user_id => @anon.id,
                        :attribute_id => MAL).should be_false
      end
    end

    context "user has attribute" do
      it "returns true" do
        add_attribute @anon.id, MAL, 6
        check_attribute(:node    => @n,
                        :user_id => @anon.id,
                        :attribute_id => MAL).should be_true
      end
    end

    it "takes optional level to check" do
      add_attribute @anon.id, MAL, 6
      check_attribute(:node    => @n,
                      :user_id => @anon.id,
                      :attribute_id => MAL,
                      :level   => 10).should be_false
      check_attribute(:node    => @n,
                      :user_id => @anon.id,
                      :attribute_id => MAL,
                      :level   => 5).should be_true
    end
  end

  describe "#require_attribute", :rjr => true do
    MAL = Users::Attributes::MissionAgentLevel.id

    before(:each) do
      # login so as to be able to access user attributes
      login @n, @anon.id, @anon.password
    end

    around(:each) do |example|
      enable_attributes {
        example.run
      }
    end

    context "user does not have attribute" do
      it "raises PermissionError" do
        lambda {
          require_attribute(:node    => @n,
                            :user_id => @anon.id,
                            :attribute_id => MAL)
        }.should raise_error(PermissionError)
      end
    end

    context "user has attribute" do
      it "does not raise error" do
        add_attribute @anon.id, MAL, 6
        lambda {
          require_attribute(:node    => @n,
                            :user_id => @anon.id,
                            :attribute_id => MAL)
        }.should_not raise_error
      end
    end

    it "takes optional level to check" do
      add_attribute @anon.id, MAL, 6
      lambda {
        require_attribute(:node    => @n,
                          :user_id => @anon.id,
                          :attribute_id => MAL,
                          :level   => 10)
      }.should raise_error(PermissionError)

      lambda {
        require_attribute(:node    => @n,
                          :user_id => @anon.id,
                          :attribute_id => MAL,
                          :level   => 5)
      }.should_not raise_error
    end
  end

  describe "#filter_properites" do
    it "returns new instance of data type" do
      o = Object.new
      filter_properties(o).should_not equal(o)
    end

    it "copies whitelisted attributes from original instance to new one" do
      o = OpenStruct.new
      o.first = 123

      n = filter_properties o, :allow => [:first]
      n.first.should == 123
    end

    it "does not copy attributes not on the whitelist" do
      o = OpenStruct.new
      o.first  = 123
      o.second = 234

      n = filter_properties o, :allow => [:first]
      n.first.should == 123
      n.second.should be_nil
    end

    it "copies a single whitelisted attribute from original instance to new one" do
      o = OpenStruct.new
      o.first = 123
      o.second = 234

      n = filter_properties o, :allow => :first
      n.first.should == 123
      n.second.should be_nil
    end

    context "hash source specified" do
      before(:each) do
        @o = {:first => 123, :second => 123}
      end

      it "creates a new hash" do
        filter_properties(@o).should_not eq(@o)
      end

      it "copies whitelisted attributes to new hash" do
        filter_properties(@o, :allow => :first).should == {:first => 123}
      end

      it "copies whitelisted string attributes to new hash" do
        @o['third'] = 123
        filter_properties(@o, :allow => :third).should == {:third => 123}
      end
    end
  end

  describe "#filter_from_args" do
    before(:each) do
      @f  = nil
      @f1 = proc { |i| @f = i + 1  }
      @f2 = proc { |i| @f = i + 2 }
    end

    it "generates filter from args list" do
      filters = filters_from_args ['with_f1'],
        :with_f1 => @f1, :with_f2 => @f2

      filters.size.should == 1
      filters.first.call(42)
      @f.should == 43
    end

    context "arg specifies invalid filter id" do
      it "throws a ValidationError" do
        lambda {
          filters = filters_from_args ['with_f3'],
            :with_f1 => @f1, :with_f2 => @f2
        }.should raise_error(Omega::ValidationError)
      end
    end
  end

  describe "#require_state" do
    it "invokes validation with entity" do
      e = Object.new
      v = proc { |e| }
      v.should_receive(:call).with(e).and_return(true)
      require_state e, &v
    end

    context "validation passes" do
      it "does not raise error" do
        e = Object.new
        v = proc { |e| true }
        lambda {
          require_state e, &v
        }.should_not raise_error
      end
    end

    context "validation fails" do
      it "does raises ValidationError" do
        e = Object.new
        v = proc { |e| false }
        lambda {
          require_state e, &v
        }.should raise_error(ValidationError)
      end
    end
  end

  describe "#with" do
    it "matches objects with specified attribute value" do
      a = [[1,2], [3,4], [5], [6,7,8], Object.new]
      r = a.select &with(:size, 2)
      r.should == [[1,2], [3,4]]

      r = a.find &with(:size, 2)
      r.should == [1,2]
    end
  end


  describe "#with_id" do
    it "matches objects with specified id" do
      o1 = OpenStruct.new
      o1.id = 1
      o1a = OpenStruct.new
      o1a.id = 1
      o2 = OpenStruct.new
      o2.id = 2

      a = [o1, o1a, o2, Object.new]
      r = a.select &with_id(1)
      r.should == [o1, o1a]

      r = a.find &with_id(1)
      r.should == o1
    end
  end

  describe "#matching" do
    it "matches objects using specified callback" do
      a = [1,2,3,4]
      r = a.select(&matching { |e| e % 2 == 0})
      r.should == [2,4]

      r = a.find(&matching { |e| e % 2 == 0})
      r.should == 2
    end
  end

  describe "#in_subsystem" do
    it "matches objects _not_ descending from the Omega::Server namespace" do
      n1 = Omega::Server::EventHandler.new
      n2 = Missions::EventHandler.new
      y = Users::User.new
      a = [n1,n2,y]
      a.select(&in_subsystem).should == [y]
    end
  end

  describe "#is_cmd" do
    context "entity is a Omega::Server::Command" do
      it "returns true" do
        is_cmd?(Omega::Server::Command.new).should be_true
      end
    end

    context "entity is not a Omega::Server::Command" do
      it "returns false" do
        is_cmd?(Object.new).should be_false
      end
    end
  end

  describe "#delete_event_handler_for" do
    before(:each) do
      @eh1 = Omega::Server::EventHandler.new(:event_id => 'registered_user-10',
                                             :event_type => 'registered_user',
                                             :endpoint_id => 'node1')
      @registry = Users::Registry.new
      @registry << @eh1
    end

    it "removes registry handler for specified event id/endpoint" do
      delete_event_handler_for :event_id => 'registered_user-10',
                               :endpoint_id => 'node1',
                               :registry => @registry
      @registry.entities.should be_empty
    end

    it "removes registry handler for specified event type/endpoint" do
      delete_event_handler_for :event_type => 'registered_user',
                               :endpoint_id => 'node1',
                               :registry => @registry
      @registry.entities.should be_empty
    end
  end

  describe "#remove_callbacks_for" do
    before(:each) do
    end

    context "registry is specified" do
      it "invokes remove_callbacks_for with registry entities" do
        r = Object.new
        r.extend Omega::Server::Registry
        entities = []
        criteria = {}
        r.should_receive(:safe_exec).and_yield(entities)
        should_receive(:remove_callbacks_for).with(entities, criteria)
        should_receive(:remove_callbacks_for).with(r, criteria).and_call_original
        remove_callbacks_for(r, criteria)
      end
    end

    context "class specified" do
      it "only processes entities matching class" do
        entities = [Motel::Location.new, Manufactured::Ship.new]
        entities.last.should_not_receive(:callbacks)
        remove_callbacks_for(entities, :class => Motel::Location)
      end
    end

    context "id specified" do
      it "only processes entity matching id" do
        entities = [Motel::Location.new(:id => 1), Motel::Location.new(:id => 2)]
        entities.last.should_not_receive(:callbacks)
        remove_callbacks_for(entities, :id => 1)
      end
    end

    context "endpoint is specified" do
      it "only removes cbs matching endpoint" do
        entity = Manufactured::Ship.new
        entity.callbacks =
          [Omega::Server::Callback.new(:endpoint_id => 'e1'),
           Omega::Server::Callback.new(:endpoint_id => 'e2')]
        lambda{
          remove_callbacks_for([entity], :endpoint => 'e2')
        }.should change{entity.callbacks.size}.by(-1)
        entity.callbacks.first.endpoint_id.should == 'e1'
      end
    end

    context "type is specified" do
      it "only removes cbs matching type" do
        entity = Manufactured::Ship.new
        entity.callbacks =
          [Omega::Server::Callback.new(:event_type => 'e1'),
           Omega::Server::Callback.new(:event_type => 'e2')]
        lambda{
          remove_callbacks_for([entity], :type => 'e2')
        }.should change{entity.callbacks.size}.by(-1)
        entity.callbacks.first.event_type.should == 'e1'
      end
    end

    context "multiple criteria are specified" do
      it "only process entities/ removes cbs matching all criteria" do
        entity = Manufactured::Ship.new
        entity.callbacks =
          [Omega::Server::Callback.new(:event_type  => 'ev1',
                                       :endpoint_id => 'ei1'),
           Omega::Server::Callback.new(:event_type  => 'ev2',
                                       :endpoint_id => 'ei2'),
           Omega::Server::Callback.new(:event_type  => 'ev1',
                                       :endpoint_id => 'ei2'),]
        lambda{
          remove_callbacks_for([entity], :type => 'ev1', :endpoint => 'ei2')
        }.should change{entity.callbacks.size}.by(-1)
        entity.callbacks.first.event_type.should == 'ev1'
        entity.callbacks.last.event_type.should  == 'ev2'
      end
    end

    context "callbacks is a event_type => cb_array hash" do
      it "removes callbacks from event_type arrays" do
        entity = Motel::Location.new
        entity.callbacks = {
          :movement => [Omega::Server::Callback.new(:event_type => :movement,
                                                    :endpoint_id => 'ev1'),
                        Omega::Server::Callback.new(:event_type => :movement,
                                                    :endpoint_id => 'ev2')],
          :rotation => [Omega::Server::Callback.new(:event_type => :rotation,
                                                    :endpoint_id => 'ev2')]
        }

        lambda{
        lambda{
          remove_callbacks_for([entity], :type => :movement, :endpoint => 'ev2')
        }.should change{entity.callbacks[:movement].size}.by(-1)
        }.should_not change{entity.callbacks[:rotation].size}
      end

      it "cleans up callbacks" do
        entity = Motel::Location.new
        entity.callbacks = {
          :movement => [Omega::Server::Callback.new(:event_type => :movement)]
        }

        remove_callbacks_for([entity], :type => :movement)
        entity.callbacks.has_key?(:movement).should be_false
      end
    end

    context "callbacks is an array of cbs" do
      it "removes callbacks from array" do
        entity = Manufactured::Ship.new
        entity.callbacks =
          [Omega::Server::Callback.new(:event_type  => 'ev1',
                                       :endpoint_id => 'ei1'),
           Omega::Server::Callback.new(:event_type  => 'ev2',
                                       :endpoint_id => 'ei2')]
        lambda{
          remove_callbacks_for([entity], :type => 'ev1', :endpoint => 'ei1')
        }.should change{entity.callbacks.size}.by(-1)
      end

      it "cleans up callbacks" do
        entity = Manufactured::Ship.new
        entity.callbacks =
          [Omega::Server::Callback.new(:event_type  => 'ev1',
                                       :endpoint_id => 'ei1')]
        remove_callbacks_for([entity], :type => 'ev1', :endpoint => 'ei1')
        entity.callbacks.should be_empty
      end
    end
  end

  describe "#handle_node_closed" do
    it "subscribes to node closed event"
    context "on node closed" do
      it "invokes registered callback"
    end
  end
end

end # module Server
end # module Omega
