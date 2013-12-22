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
  end

  describe "#dispatch_users_rjr_init" do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      Users::RJR.registry.clear!
      @d   = @n.dispatcher
      @rjr = Object.new.extend(Users::RJR)
    end

    it "dispatches users* in Users::RJR environment" do
      dispatch_users_rjr_init(@d)
      @d.environments[/users::.*/].should  == Users::RJR
    end

    it "adds users rjr modules to dispatcher" do
      @d.should_receive(:add_module).with('users/rjr/create')
      @d.should_receive(:add_module).with('users/rjr/get')
      @d.should_receive(:add_module).with('users/rjr/update')
      @d.should_receive(:add_module).with('users/rjr/permissions')
      @d.should_receive(:add_module).with('users/rjr/register')
      @d.should_receive(:add_module).with('users/rjr/session')
      @d.should_receive(:add_module).with('users/rjr/attribute')
      @d.should_receive(:add_module).with('users/rjr/events')
      @d.should_receive(:add_module).with('users/rjr/state')
      dispatch_users_rjr_init(@d)
    end

    it "sets dispatcher on node" do
      dispatch_users_rjr_init(@d)
      @rjr.node.dispatcher.should == @d
    end

    it "sets source_node message header on node" do
      dispatch_users_rjr_init(@d)
      @rjr.node.message_headers['source_node'].should == 'users'
    end

    it "creates the user" do
      dispatch_users_rjr_init(@d)
      Users::RJR.registry.entity(&with_id(Users::RJR.user.id)).should_not be_nil
    end

    context "user exists" do
      it "does not raise error" do
        Users::RJR.registry.entities << Users::RJR.user
        lambda{
          dispatch_users_rjr_init(@d)
        }.should_not raise_error
      end
    end

    it "logs in the user using the node" do
      lambda{
        dispatch_users_rjr_init(@d)
      }.should change{Users::RJR.registry.entities.size}.by(3)
      Users::RJR.registry.
                 entity(&matching{ |s| s.is_a?(Session) &&
                                       s.user.id == Users::RJR.user.id }).
                 should_not be_nil
    end

    it "sets session if on node" do
      dispatch_users_rjr_init(@d)
      @rjr.node.message_headers['source_node'].should_not be_nil
    end

    context "additional users configured" do
      before(:each) do
        @au1 = {:user_id  => 'foo',
                :password => 'oof',
                :permissions => [['view', 'cosmos_entities'], ['modify']]}
        @au2 = {:user_id  => 'bar',
                :password => 'rab'}
        Users::RJR.additional_users = [@au1, @au2]
      end

      it "creates the additional users" do
        dispatch_users_rjr_init(@d)
        ru1 = Users::RJR.registry.proxy_for(&with_id('foo'))
        ru2 = Users::RJR.registry.proxy_for(&with_id('bar'))

        ru1.should_not be_nil
        ru1.valid_login?('foo', 'oof').should be_true

        ru2.should_not be_nil
        ru2.valid_login?('bar', 'rab').should be_true
      end

      context "an additional user exists" do
        it "does not raise error, creates other users" do
          Users::RJR.registry << Users::User.new(:id => 'foo')
          Users::RJR.registry << Users::Role.new(:id => 'user_role_foo')
          lambda{
            dispatch_users_rjr_init(@d)
          }.should_not raise_error

          ru2 = Users::RJR.registry.proxy_for(&with_id('bar'))
          ru2.should_not be_nil
          ru2.valid_login?('bar', 'rab').should be_true
        end
      end

      it "adds permissions to users" do
        dispatch_users_rjr_init(@d)
        ru1 = Users::RJR.registry.entity(&with_id('foo'))

        ru1.has_privilege?('modify').should be_true
        ru1.has_privilege_on?('view', 'cosmos_entities').should be_true
      end
    end
  end

end # module Users::RJR
