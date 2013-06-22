# Omega Client DSL tests
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'omega/client/dsl'

module Omega
module Client
describe DSL do

  include Omega::Server::DSL
  include Omega::Client::DSL

  before(:each) do
    @u = create(:user)
    add_role "user_role_#{@u.id}", :superadmin

    dsl.rjr_node = @n
    @n.dispatcher.add_module('users/rjr/init')
    @n.dispatcher.add_module('motel/rjr/init')
    @n.dispatcher.add_module('cosmos/rjr/init')
    @n.dispatcher.add_module('manufactured/rjr/init')
    @n.dispatcher.add_module('missions/rjr/init')

    login @u.id, @u.password
  end

  describe "#login" do
    it "logs the node in"
    it "sets session id on node"
  end

  describe "#user" do
    it "retrieves the specified user" do
      user('foo2', 'foo2')
      u = user('foo2')
      u.id.should == 'foo2'
    end

    context "user does not exist" do
      it "creates the specified user" do
        u = user('foo', 'bar')
        u.id.should == 'foo'
        Users::RJR.registry.entity(&with_id('foo')).should_not be_nil
      end

      it "accepts user params" do
        u = user('foo1', 'bar', :npc => true)
        u.id.should == 'foo1'
    
        ru = Users::RJR.registry.entity &with_id('foo1')
        ru.npc.should be_true
      end
    end
  end

  describe "#role" do
    it "creates the specified role" do
      r = build(:role)
      role(r)
      Users::RJR.registry.entity(&with_id(r.id)).should_not be_nil
    end

    context "@user not nil" do
      it "adds role to user" do
        r = build(:role)
        role(r)
        user('bar', 'foo') { |u|
          u.id.should == 'bar'
          role(r.id)
        }
        rr = Users::RJR.registry.entity &with_id('bar')
        rr.roles.size.should == 2
        rr.roles.last.id.should == r.id
      end
    end
  end

  describe "#galaxy" do
    it "creates the specified galaxy" do
      g = galaxy('far') { |g|
        g.name.should == 'far'
      }
      g.name.should == 'far'
      Cosmos::RJR.registry.entity(&with_id(g.id)).should_not be_nil
    end
  end

  describe "#system" do
    it "returns the system" do
      sys = create(:solar_system)
      s = system(sys.name)
      s.should be_an_instance_of(Cosmos::Entities::SolarSystem)
      s.name.should == sys.name
    end

    context "system not found" do
      it "creates the specified system" do
        s = nil
        galaxy('ngal1') { |g|
          s = system('system1') { |s|
            s.name.should == 'system1'
          }
          s.name.should == 'system1'
        }
        s.should be_an_instance_of(Cosmos::Entities::SolarSystem)
        Cosmos::RJR.registry.entity(&with_id(s.id)).should_not be_nil
      end

      it "creates star"

      context "no galaxy is set" do
        it "raises ArgumentError" do
          lambda {
            system('system1')
          }.should raise_error(ArgumentError)
        end
      end
    end
  end

  describe "#asteroid" do
    it "creates a new asteroid" do
      a = nil
      galaxy('ngal1') { |g|
        system('system1') { |s|
          a = asteroid('nast1') { |a|
            a.name.should == 'nast1'
          }
          a.name.should == 'nast1'
        }
      }
      a.should be_an_instance_of(Cosmos::Entities::Asteroid)
      Cosmos::RJR.registry.entity(&with_id(a.id)).should_not be_nil
    end

    context "@system is nil" do
      it "raises ArgumentError" do
        lambda {
          asteroid('nast1')
        }.should raise_error(ArgumentError)
      end
    end
  end

  describe "#resource" do
    it "creates a new resource" do
      a = nil
      galaxy('ngal1') { |g|
        system('system1') { |s|
          a = asteroid('nast1') { |a|
            r = resource(:id => 'gem-ruby', :quantity => 420)
            r.id.should == 'gem-ruby'
            r.quantity.should == 420
          }
        }
      }
      r = Cosmos::RJR.registry.entity(&with_id(a.id)).resources.first
      r.id.should == 'gem-ruby'
      r.quantity.should == 420
    end

    context "@asteroid is nil" do
      it "raises ArgumentError" do
        lambda {
          resource(:id => 'metal-steel')
        }.should raise_error(ArgumentError)
      end
    end
  end

  describe "#planet" do
    it "creates new planet" do
      p = nil
      galaxy('ngal1') { |g|
        system('system1') { |s|
          p = planet('pl1') { |p|
            p.name.should == 'pl1'
          }
        }
      }
      p.should be_an_instance_of(Cosmos::Entities::Planet)
      Cosmos::RJR.registry.entity(&with_id(p.id)).should_not be_nil
    end

    context "@solar_system is nil" do
      it "raises ArgumentError" do
        lambda {
          planet('pl1')
        }.should raise_error(ArgumentError)
      end
    end
  end

  describe "#moon" do
    it "creates new moon" do
      m = nil
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
      m.should be_an_instance_of(Cosmos::Entities::Moon)
      Cosmos::RJR.registry.entity(&with_id(m.id)).should_not be_nil
    end

    context "@planet is nil" do
      it "raises ArgumentError" do
        lambda {
          moon('mn1')
        }.should raise_error(ArgumentError)
      end
    end
  end

  describe "#jump_gate" do
    it "creates new jump_gate" do
      s1 = s2 = nil
      galaxy('ngal1') { |g|
        s1 = system('system1')
        s2 = system('system2')
      }
  
      jg = jump_gate s1, s2
      jg.parent_id.should == s1.id
      jg.endpoint_id.should == s2.id
      Cosmos::RJR.registry.entity(&with_id(jg.id)).should_not be_nil
    end
  end

  describe "#station" do
    it "retrieve station" do
      st = create(:valid_station)
      s = station(st.id)
      s.should be_an_instance_of(Manufactured::Station)
      s.id.should == st.id
    end

    context "station not found" do
      it "creates new station" do
        s = station('st1',
                    :user_id => create(:user).id,
                    :type    => :manufacturing,
                    :solar_system => create(:solar_system)){ |st|
                      st.id.should == 'st1'
                    }
        s.should be_an_instance_of(Manufactured::Station)
        s.id.should == 'st1'
        Manufactured::RJR.registry.entity(&with_id(s.id)).should_not be_nil
      end
    end
  end

  describe "#ship" do
    it "retrieve ship" do
      st = create(:valid_ship)
      s = ship(st.id)
      s.should be_an_instance_of(Manufactured::Ship)
      s.id.should == st.id
    end

    context "ship not found" do
      it "creates new ship" do
        s = ship('sh1',
                 :user_id => create(:user).id,
                 :type    => :frigate,
                 :solar_system => create(:solar_system)){ |sh|
                   sh.id.should == 'sh1'
                 }
        s.should be_an_instance_of(Manufactured::Ship)
        s.id.should == 'sh1'
        Manufactured::RJR.registry.entity(&with_id(s.id)).should_not be_nil
      end
    end
  end

  describe "#schedule" do
    it "creates new periodic missions event" do
      e = schedule 10, Omega::Server::Event.new(:id => 'event123')
      e.id.should == 'event123-scheduler'
      e = Missions::RJR.registry.entity(&with_id(e.id))
      e.should_not be_nil
      e.interval.should == 10
      e.template_event.id.should == 'event123'
    end
  end

  describe "#mission" do
    it "creates new mission" do
      m = mission 'mission123', :title => 'test mission'
      m.id.should == 'mission123'
      m = Missions::RJR.registry.entity(&with_id('mission123'))
      m.should_not be_nil
      m.title.should == 'test mission'
    end
  end

  describe DSL::Base do
    describe "#rjr_node=" do
      it "sets rjr node on client"
    end

    describe "#join" do
      it "joins worker threads"
    end

    describe "#run" do
      context "parallel is true" do
        it "runs block in new workers thread"
      end

      it "sets instance variables"
      it "runs block"
      it "unsets instance variables"
    end
  end

end # describe DSL
end # module Client
end # module Omega
