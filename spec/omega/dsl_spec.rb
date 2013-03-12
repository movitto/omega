# client dsl module tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

describe Omega::Client::DSL do

  include Omega::Client::DSL

  before(:each) do
    TestUser.add_role(:superadmin)
  end

  it "should create an new user" do
    u = user('foo', 'bar')
    u.id.should == 'foo'
    Users::Registry.instance.find(:id => 'foo', :type => 'Users::User').first.should_not be_nil
  end

  it "should allow user to specify args when creating new user" do
    u = user('foo1', 'bar', :npc => true)
    u.id.should == 'foo1'

    ru = Users::Registry.instance.find(:id => 'foo1', :type => 'Users::User').first
    ru.should_not be_nil
    ru.npc.should be_true
  end

  it "should create a new role" do
    u = role(Users::Role.new(:id => 'foozrole'))
    u.id.should == 'foozrole'
    Users::Registry.instance.find(:id => 'foozrole', :type => 'Users::Role').first.should_not be_nil
  end

  it "should add role to user" do
    role(Users::Role.new(:id => 'foozrole'))
    user('bar', 'foo') { |u|
      u.id.should == 'bar'
      @user.id.should == 'bar'
      role('foozrole')
    }
    Users::Registry.instance.find(:id => 'bar', :type => 'Users::User').first.roles.size.should == 2
    Users::Registry.instance.find(:id => 'bar', :type => 'Users::User').first.roles.last.id.should == 'foozrole'
  end

  it "should create a new alliance" do
    a = alliance('ally1')
    a.id.should == 'ally1'
    Users::Registry.instance.find(:id => 'ally1', :type => 'Users::Alliance').first.should_not be_nil
  end

  it "should create a new galaxy" do
    g = galaxy('far') { |g|
      g.name.should == 'far'
      @galaxy.should_not be_nil
      @galaxy.name.should == 'far'
    }
    g.name.should == 'far'
    Cosmos::Registry.instance.find_entity(:id => 'far', :type => 'Cosmos::Galaxy').first.should_not be_nil
  end

  it "should create a new system" do
    galaxy('ngal1') { |g|
      s = system('system1') { |s|
        s.name.should == 'system1'
        @system.should_not be_nil
        @system.name.should == 'system1'
      }
      s.id.should == 'system1'
    }
    Cosmos::Registry.instance.find_entity(:id => 'system1', :type => 'Cosmos::SolarSystem').first.should_not be_nil
    # TODO ensure star gets created
  end

  it "should raise error if no galaxy is set when creating system" do
    lambda {
      system('system1')
    }.should raise_error(ArgumentError)
  end

  it "should retrieve the specified system" do
    galaxy('ngal1') { |g|
      system('system1')
    }
    s = system('system1')
    s.name.should == 'system1'
  end

  it "should create a new asteroid" do
    galaxy('ngal1') { |g|
      system('system1') { |s|
        a = asteroid('nast1') { |a|
          a.name.should == 'nast1'
        }
        a.name.should == 'nast1'
      }
    }
    Cosmos::Registry.instance.find_entity(:id => 'nast1', :type => 'Cosmos::Asteroid').first.should_not be_nil
  end

  it "should raise error if no system is set when creating asteroid" do
    lambda {
      asteroid('nast1')
    }.should raise_error(ArgumentError)
  end

  it "should create a new resource" do
    galaxy('ngal1') { |g|
      system('system1') { |s|
        asteroid('nast1') { |a|
          res = resource(:name => "res1", :type => 'metal', :quantity => 420) { |r|
            r.name.should == 'res1'
          }
          res.name.should == 'res1'
        }
      }
    }
    # TODO verify resource source exists
  end

  it "should raise error if no asteroid is set when creating resource" do
    lambda {
      resource(:id => 'res1')
    }.should raise_error(ArgumentError)
  end

  it "should create a new planet" do
    galaxy('ngal1') { |g|
      system('system1') { |s|
        p = planet('pl1') { |p|
          p.name.should == 'pl1'
        }
      }
    }
    Cosmos::Registry.instance.find_entity(:id => 'pl1', :type => 'Cosmos::Planet').first.should_not be_nil
  end

  it "should raise error if no system is set when creating planet" do
    lambda {
      planet('pl1')
    }.should raise_error(ArgumentError)
  end

  it "should create a new moon" do
    galaxy('ngal1') { |g|
      system('system1') { |s|
        planet('pl1') { |p|
          m = moon('mn1') { |m|
            m.name.should == 'mn1'
          }
          m.name.should == 'mn1'
        }
      }
    }
    Cosmos::Registry.instance.find_entity(:id => 'mn1', :type => 'Cosmos::Moon').first.should_not be_nil
  end

  it "should raise error if no planet is set when creating moon" do
    lambda {
      moon('mn1')
    }.should raise_error(ArgumentError)
  end

  it "should create a new jump_gate" do
    s1 = s2 = nil
    galaxy('ngal1') { |g|
      s1 = system('system1')
      s2 = system('system2')
    }

    jg = jump_gate s1, s2
    jg.solar_system.name.should == s1.name
    jg.endpoint.name.should == s2.name
    # TODO verify in registry
  end

  it "should create a new station" do
    user('user1', '1resu')
    galaxy('ngal1') { |g| system('system1') }
    s = station('st1', :user_id => 'user1', :type => :manufacturing,
                       :solar_system => system('system1'), :location => Motel::Location.new()) { |s|
      s.id.should == 'st1'
    }
    s.id.should == 'st1'
    Manufactured::Registry.instance.find(:id => 'st1', :type => 'Manufactured::Station').first.should_not be_nil
  end

  it "should create a new ship" do
    user('user2', '2resu')
    galaxy('ngal1') { |g| system('system1') }
    s = ship('sh1', :user_id => 'user2', :type => :mining,
                    :solar_system => system('system1'), :location => Motel::Location.new()) { |s|
      s.id.should == 'sh1'
    }
    s.id.should == 'sh1'
    Manufactured::Registry.instance.find(:id => 'sh1', :type => 'Manufactured::Ship').first.should_not be_nil
  end

  it "should schedule a new periodic missions event" do
    e = schedule_event 10, Missions::Event.new(:id => 'event123')
    e.id.should == 'event123-scheduler'
    Missions::Registry.instance.events.find { |e|
      e.id == 'event123-scheduler' && e.interval == 10 && e.template_event.id == 'event123'
    }.should_not be_nil
  end

  it "should create a new mission" do
    m = mission 'mission123', :title => 'test mission'
    m.id.should == 'mission123'
    Missions::Registry.instance.missions.find { |m|
      m.id == 'mission123' && m.title == 'test mission'
    }.should_not be_nil
  end

end
