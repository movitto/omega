# Omega Server session DSL tests
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'omega/server/dsl/session'

require 'users/session'

module Omega
module Server
describe DSL do
  include Omega::Server::DSL

  before(:each) do
    @anon = create(:anon)
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


end # describe DSL
end # module Server
end # module Omega
