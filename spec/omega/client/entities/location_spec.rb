# client location module tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

describe Omega::Client::HasLocation do
  it "should allow client to track entity movement" do
    TestUser.add_privilege(Omega::Roles::PRIVILEGE_VIEW,
                           Omega::Roles::ENTITIES_MANUFACTURED)
    TestUser.add_privilege(Omega::Roles::PRIVILEGE_VIEW,
                           Omega::Roles::ENTITIES_COSMOS)
    TestUser.add_privilege(Omega::Roles::PRIVILEGE_MODIFY,
                           Omega::Roles::ENTITIES_MANUFACTURED)
    TestUser.add_privilege(Omega::Roles::PRIVILEGE_VIEW,
                           Omega::Roles::ENTITIES_LOCATIONS)

    @ship1 = FactoryGirl.build(:ship1)

    ts = TestShip.get(@ship1.id)
    nloc = ts.location + [50,50,50]
    Omega::Client::Node.invoke_request 'manufactured::move_entity', @ship1.id, nloc
    invoked = 0 ; slid = @ship1.location.id
    ts.handle_event(:movement, 5) { |e|
      e.id.should == slid
      invoked += 1
    }
    sleep 3
    invoked.should > 0
    Omega::Client::Node.invoke_request 'manufactured::stop_entity', @ship1.id
  end
end

