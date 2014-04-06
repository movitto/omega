# Omega Server attribute DSL tests
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'omega/server/dsl/attributes'
require 'users/attributes/other'

module Omega
module Server
describe DSL do
  include Omega::Server::DSL

  before(:each) do
    @anon = create(:anon)
    @rjr_headers = {}
  end

  describe "#check_attribute", :rjr => true do
    mal = Users::Attributes::MissionAgentLevel.id

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
                        :attribute_id => mal).should be_false
      end
    end

    context "user has attribute" do
      it "returns true" do
        add_attribute @anon.id, mal, 6
        check_attribute(:node    => @n,
                        :user_id => @anon.id,
                        :attribute_id => mal).should be_true
      end
    end

    it "takes optional level to check" do
      add_attribute @anon.id, mal, 6
      check_attribute(:node    => @n,
                      :user_id => @anon.id,
                      :attribute_id => mal,
                      :level   => 10).should be_false
      check_attribute(:node    => @n,
                      :user_id => @anon.id,
                      :attribute_id => mal,
                      :level   => 5).should be_true
    end
  end

  describe "#require_attribute", :rjr => true do
    mal = Users::Attributes::MissionAgentLevel.id

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
                            :attribute_id => mal)
        }.should raise_error(PermissionError)
      end
    end

    context "user has attribute" do
      it "does not raise error" do
        add_attribute @anon.id, mal, 6
        lambda {
          require_attribute(:node    => @n,
                            :user_id => @anon.id,
                            :attribute_id => mal)
        }.should_not raise_error
      end
    end

    it "takes optional level to check" do
      add_attribute @anon.id, mal, 6
      lambda {
        require_attribute(:node    => @n,
                          :user_id => @anon.id,
                          :attribute_id => mal,
                          :level   => 10)
      }.should raise_error(PermissionError)

      lambda {
        require_attribute(:node    => @n,
                          :user_id => @anon.id,
                          :attribute_id => mal,
                          :level   => 5)
      }.should_not raise_error
    end
  end


end # describe DSL
end # module Server
end # module Omega
