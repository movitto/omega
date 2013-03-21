# rjr adapter tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'rjr/local_node'

describe Stats::RJRAdapter do
  it "should permit users with view stats to get stat results" do
    # insufficient permissions
    lambda{
      Omega::Client::Node.invoke_request('stats::get', 'num_of', 'users')
    #}.should raise_error(Omega::PermissionError)
    }.should raise_error(Exception)

    TestUser.add_privilege('view', 'stats')

    # invalid stat
    lambda{
      Omega::Client::Node.invoke_request('stats::get', 'invalid')
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    # invalid stat
    lambda{
      Omega::Client::Node.invoke_request('stats::get')
    #}.should raise_error(Omega::DataNotFound)
    }.should raise_error(Exception)

    # valid call
    result = nil
    lambda{
      result = Omega::Client::Node.invoke_request('stats::get', 'num_of', 'users')
    }.should_not raise_error

    result.class.should == Stats::StatResult
    result.stat_id.should == 'num_of'
    result.args.should == ['users']
    result.value.should == Users::Registry.instance.find(:type => "Users::User").size
  end
end
