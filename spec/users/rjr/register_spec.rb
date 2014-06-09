# users::register, users::confirm_register tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'users/rjr/register'
require 'rjr/dispatcher'

module Users::RJR
  describe "#register", :rjr => true do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      dispatch_to @s, Users::RJR, :REGISTER_METHODS

      # XXX currently not testing email or recaptcha
      Users::EmailHelper.email_enabled = false
      Users::RJR.recaptcha_enabled = false
    end

    context "non-user specified" do
      it "raises ArgumentError" do
        lambda {
          @s.register 'anything'
        }.should raise_error(ArgumentError)
      end
    end

    context "user not valid" do
      it "raises ArgumentError" do
        u = build(:user)
        u.email = 'invalid'
        lambda {
          @s.register u
        }.should raise_error(ArgumentError)
      end
    end

    context "recaptcha not valid" do
      it "raises ArgumentError" do
        Users::RJR.recaptcha_enabled = true
        http = double(Object)
        http.should_receive(:body_str).and_return("false anything else")
        Curl::Easy.should_receive(:http_post).and_return(http)

        u = build(:user, :recaptcha_challenge => 'required',
                         :recaptcha_response  => 'required')
        @s.instance_variable_set(:@rjr_client_ip, 'required')
        lambda {
          @s.register u
        }.should raise_error(ArgumentError, "invalid recaptcha")
      end
    end

    context "user cannot be created" do
      it "raises users::create_entity error" do
        u = create(:user)
        lambda {
          @s.register u
        #}.should raise_error(OperationError)
        }.should raise_error(Exception)
      end
    end

    it "creates user" do
      u = build(:user)
      lambda {
        @s.register u
      }.should change{Users::RJR.registry.entities.size}.by(2)
      Users::RJR.registry.
                 entities.
                 select  { |e| e.is_a?(Users::User) }.
                 collect { |e| e.id }.should include(u.id)
    end

    it "sends registration email" do
      u = build(:user, :email => 'user@user.user')
      Users::EmailHelper.email_enabled = false
      EmailHelper.instance.should_receive(:send_email).
                  with(u.email, an_instance_of(String)) # TODO validate email contents
      @s.register u
    end

    it "returns user" do
      u = build(:user)
      n = @s.register u
      n.should be_an_instance_of(User)
      n.id.should == u.id
    end

  end # describe #register

  describe "#confirm_register", :rjr => true do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      dispatch_to @s, Users::RJR, :REGISTER_METHODS

      @u = build(:user)
      @u.registration_code = 'foobar'
      Users::RJR.registry << @u
    end

    context "invalid registration code" do
      it "raises DataNotFound" do
        lambda {
          @s.confirm_register 'invalid'
        }.should raise_error(DataNotFound)
      end
    end

    it "sets registration code to nil" do
      @s.confirm_register 'foobar'
      Users::RJR.registry.
        entity(&matching{|e|
                 e.is_a?(User) &&
                 e.registration_code == 'foobar'
               }).should be_nil
    end

    it "adds RegisteredUser Event to queue" do
      lambda {
        @s.confirm_register 'foobar'
      }.should change{Users::RJR.registry.entities.size}.by(1)
      event = Users::RJR.registry.entities.last
      event.should be_an_instance_of(Users::Events::RegisteredUser)
      event.user.id.should == @u.id
    end

    it "returns nil" do
      @s.confirm_register('foobar').should be_nil
    end
  end # describe #confirm_register

  describe "#dispatch_users_rjr_register", :rjr => true do
    it "adds users::register to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_users_rjr_register(d)
      d.handlers.keys.should include("users::register")
    end

    it "adds users::confirm_register to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_users_rjr_register(d)
      d.handlers.keys.should include("users::confirm_register")
    end
  end

end #module Users::RJR
