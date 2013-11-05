# Omega Client DSL tests
#
# Copyright (C) 2012-2013-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'omega/client/dsl'

module Omega
module Client
describe DSL, :rjr => true do

  include Omega::Server::DSL
  include Omega::Client::DSL

  before(:each) do
    dsl.rjr_node = @n
    @n.dispatcher.add_module('users/rjr/init')
    @n.dispatcher.add_module('motel/rjr/init')
    @n.dispatcher.add_module('cosmos/rjr/init')
    @n.dispatcher.add_module('manufactured/rjr/init')
    @n.dispatcher.add_module('missions/rjr/init')

    @u = reload_super_admin
    login @u.id, @u.password
  end

  describe "#login" do
    it "logs the node in" do
      create(:user, :id => 'foo', :password => 'bar')
      login('foo', 'bar')
      s = Users::RJR.registry.entities.last
      s.should be_an_instance_of(Users::Session)
      s.user.id.should == 'foo'
    end

    it "sets @session" do
      create(:user, :id => 'foo', :password => 'bar')
      login('foo', 'bar')
      @session.should_not be_nil
      @session.user.id.should == 'foo'
    end

    it "sets session id on node" do
      create(:user, :id => 'foo', :password => 'bar')
      login('foo', 'bar')
      s = Users::RJR.registry.entities.last
      s.id.should == @n.message_headers['session_id']
    end
  end

  describe "#logout" do
    before(:each) do
      create(:user, :id => 'foo', :password => 'bar')
      login('foo', 'bar')
    end

    it "logs out the session" do
      logout
      Users::RJR.registry.entity { |e|
        e.is_a?(Users::Session) && e.user.id == 'foo'
      }.should be_nil
    end

    it "sets session to nil" do
      logout
      @session.should be_nil
    end

    it "sets nodes session id to nil" do
      logout
      @n.message_headers['session_id'].should be_nil
    end
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

      it "creates star" do
        s = nil
        galaxy('ngal1') { |g|
          s = system('system1', 'star1')
        }
        st = Cosmos::RJR.registry.entity { |e| e.name == 'star1'}
        st.should_not be_nil
        st.should be_an_instance_of(Cosmos::Entities::Star)
        st.parent_id.should == s.id
      end

      context "no galaxy is set" do
        it "raises ArgumentError" do
          lambda {
            system('system1')
          }.should raise_error(ArgumentError)
        end
      end
    end
  end

  describe "#proxied_system" do
    it "creates the specified proxied system" do
      s = proxied_system('system1', 'remote1',
                           :name => 'system1')
      s.should be_an_instance_of(Cosmos::Entities::SolarSystem)
      s.id.should == 'system1'
      s.name.should == 'system1'
      s.proxy_to.should == 'remote1'
      Cosmos::RJR.registry.entity(&with_id(s.id)).should_not be_nil
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

  describe "#asteroid_field" do
    it "creates asteroids at the specified locations" do
      l1 = Motel::Location.new :x => 100, :y => 0, :z => 0
      l2 = Motel::Location.new :x => 200, :y => 0, :z => 0

      asts = nil
      galaxy('ngal1') { |g|
        system('system1') { |s|
          asts = asteroid_field(:locations => [l1,l2], :size => 10, :color => 'aaaaaa') { |as|
            as.size.should == 2
            as.first.location.should == l1
            as.last.location.should  == l2
            as.first.size.should     == 10
            as.last.size.should      == 10
          }
        }
      }

      asts.size.should == 2
      asts.first.location.should == l1
      asts.last.location.should  == l2
      asts.first.size.should     == 10
      asts.last.size.should      == 10
      Cosmos::RJR.registry.entity(&with_id(asts.first.id)).should_not be_nil
      Cosmos::RJR.registry.entity(&with_id(asts.last.id)).should_not be_nil
    end
  end

  describe "#asteroid_belt" do
    it "creates asteroids at locations generated from the specified elliptical path" do
      num = 31 # XXX
      p = 100; e = 0.6 ; d = Motel.random_axis
      path = Motel.elliptical_path(p, e, d)

      asts = nil
      galaxy('ngal1') { |g|
        system('system1') { |s|
          asts = asteroid_belt(:p => p, :e => e, :direction => d) { |as|
            as.size.should == num
            as.all? { |a| a.class == Cosmos::Entities::Asteroid }.should == true
          }
        }
      }

      asts.size.should == num
      asts.all? { |a| a.class == Cosmos::Entities::Asteroid }.should be_true
      # TODO verify asteroids are evenly spaced out on elliptical path & exist on server
    end
  end

  describe "#resource" do
    it "creates a new resource" do
      a = r = nil
      galaxy('ngal1') { |g|
        system('system1') { |s|
          a = asteroid('nast1') { |a|
            r = resource(:material_id => 'gem-ruby', :quantity => 420)
            r.material_id.should == 'gem-ruby'
            r.quantity.should == 420
          }
        }
      }
      wait_for_notify
      r = Cosmos::RJR.registry.entity(&with_id(a.id)).resources.first
      r.material_id.should == 'gem-ruby'
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

  describe "#orbit" do
    it "returns new elliptical movement strategy with the specified params" do
      e = orbit :speed => 0.01
      e.should be_an_instance_of(Motel::MovementStrategies::Elliptical)
      e.speed.should == 0.01
    end

    context "relative_to not specified" do
      it "sets relative_to foci" do
        e = orbit :speed => 0.01
        e.relative_to.should == Motel::MovementStrategies::Elliptical::FOCI
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
      wait_for_notify
      Cosmos::RJR.registry.entity{|es| es.name == 'mn1' }.should_not be_nil
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

  describe "#dock" do
    it "docks ship to station" do
      sh = create(:valid_ship,
                  :location => Motel::Location.new(:coordinates => [0,0,0]))
      st = create(:valid_station, :solar_system => sh.solar_system,
                  :location => Motel::Location.new(:coordinates => [0,0,0]))
      dock sh.id, st.id
      Manufactured::RJR.registry.
                        entity(&with_id(sh.id)).
                        docked_at_id.should == st.id
    end
  end

  describe "#schedule_event" do
    it "creates new periodic missions event" do
      Missions::RJR.registry.stop # stop registry so event doesn't get processed/removed
      e = schedule_event 10, Omega::Server::Event.new(:id => 'event123')
      e.id.should == 'event123-scheduler'
      wait_for_notify
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
      wait_for_notify
      m = Missions::RJR.registry.entity(&with_id('mission123'))
      m.should_not be_nil
      m.title.should == 'test mission'
    end
  end

  describe DSL::Base do
    before(:each) do
      @b = DSL::Base.new
    end

    describe "#rjr_node=" do
      it "sets rjr node on client" do
        @b.rjr_node = @n
        @b.node.rjr_node.should == @n
      end
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
