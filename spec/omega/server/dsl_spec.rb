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

module Omega
module Server
describe DSL do
  include Omega::Server::DSL
  
  before(:each) do
    @anon = create(:anon)
    @rjr_node = @n
    @rjr_headers = {}
  end

  describe "#login" do
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

  describe "#require_privilege" do
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

  describe "#check_privilege" do
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

  describe "#current_user" do
    it "return registry user corresponding to session_id header" do
      @rjr_headers['session_id'] = login(@n, @anon.id, @anon.password).id
      u = current_user(:registry => Users::RJR.registry)
      u.should be_an_instance_of(Users::User)
      u.id.should == @anon.id
    end
  end

  describe "#check_attribute" do
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

  describe "#require_attribute" do
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

end

end # module Server
end # module Omega
