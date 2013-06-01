# users/rjr/init tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

module Users::RJR
  describe "#user" do
    it "provides centralized user" do
      rjr = Object.new.extend(Users::RJR)
      rjr.user.should be_an_instance_of User
      rjr.user.valid_login?(Users::RJR.users_rjr_username,
                             Users::RJR.users_rjr_password)

      rjr.user.should equal(rjr.user)
    end

    it "is accessible on module" do
      rjr = Object.new.extend(Users::RJR)
      Users::RJR.user.should equal(rjr.user)
    end
  end

  describe "#node" do
    it "provides centralized rjr node" do
      rjr = Object.new.extend(Users::RJR)
      rjr.node.should be_an_instance_of(::RJR::Nodes::Local)
      rjr.node.should equal(rjr.node)
    end

    it "is accessible on module" do
      rjr = Object.new.extend(Users::RJR)
      Users::RJR.node.should equal(rjr.node)
    end
  end

  describe "#registry" do
    it "provides centralized registry" do
      rjr = Object.new.extend(Users::RJR)
      rjr.registry.should be_an_instance_of(Registry)
      rjr.registry.should equal(rjr.registry)
    end

    it "is accessible on module" do
      rjr = Object.new.extend(Users::RJR)
      Users::RJR.registry.should equal(rjr.registry)
    end
  end

  describe "#reset" do
    it "clears users registry" do
      Users::RJR.registry << build(:user)
      Users::RJR.registry.entities.size.should > 0
      Users::RJR.reset
      Users::RJR.registry.entities.size.should == 0
    end

    it "clears chat messages"
  end

  describe "#dispatch_init" do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      @d = ::RJR::Dispatcher.new
      @d.add_module('lib/users/rjr') # dispatch_init requires users::login
      @rjr = Object.new.extend(Users::RJR)
    end

    it "dispatches user* in Users::RJR environment" do
      dispatch_init(@d)
      @d.environments.size.should == 1
      @d.environments.first.first.should == /users::.*/
      @d.environments.first.last.should  == Users::RJR
    end

    it "sets dispatcher on node" do
      dispatch_init(@d)
      @rjr.node.dispatcher.should == @d
    end

    it "sets source_node message header on node" do
      dispatch_init(@d)
      @rjr.node.message_headers['source_node'].should == 'users'
    end

    it "creates the user" do
      dispatch_init(@d)
      Users::RJR.registry.entity(&with_id(Users::RJR.user.id)).should_not be_nil
    end

    context "user exists" do
      it "does not raise error" do
        Users::RJR.registry.entities << Users::RJR.user
        lambda{
          dispatch_init(@d)
        }.should_not raise_error
      end
    end

    it "logs in the user using the node" do
      #lambda{ # XXX @d.add_module above will have already called dispatch_init
      #  dispatch_init(@d)
      #}.should change{Users::RJR.registry.entities.size}.by(2)
      Users::RJR.registry.
                 entity(&matching{ |s| s.is_a?(Session) &&
                                        s.user.id == Users::RJR.user.id }).
                 should_not be_nil
    end

    it "sets session if on node" do
      dispatch_init(@d)
      @rjr.node.message_headers['source_node'].should_not be_nil
    end
  end

end # module Users::RJR