#!/usr/bin/ruby
# monitors the integration framework for status / errors
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
#
# to use rbcurse (currently not used):
#   $ export RUBY_FFI_NCURSES_LIB=/lib64/libncursesw.so.5.9

require 'rubygems'
require 'ncursesw'
require 'singleton'
require 'active_support/core_ext/string/filters'
require 'omega'

class MonitoredGalaxy
  attr_accessor :server_galaxy

  def initialize(node, server_galaxy)
    @node = node
    @server_galaxy = server_galaxy
  end

  def refresh
    @server_galaxy.solar_systems.each { |sys|
      sys.asteroids.each { |ast|
        #@node.invoke_request('omega-queue', 'cosmos::get_resources', ...)
      }
    }
  end
end

class MonitoredShip
  attr_accessor :server_ship

  def initialize(server_ship)
    @server_ship = server_ship
  end
end

class MonitoredStation
  attr_accessor :server_station

  def initialize(server_station)
    @server_station = server_station
  end
end

class MonitoredUser
  attr_accessor :server_user
  attr_accessor :ships
  attr_accessor :stations

  def initialize(node, server_user)
    @node = node
    @server_user = server_user
    @ships    = {}
    @stations = {}
  end

  def <<(entity)
    if entity.is_a?(MonitoredShip)
      @ships[entity.server_ship.id] = entity
    elsif entity.is_a?(MonitoredStation)
      @stations[entity.server_station.id] = entity
    end
  end

  def refresh
    user_ships = @node.invoke_request('omega-queue', 'manufactured::get_entities',
                                      'of_type',     'Manufactured::Ship',
                                      'owned_by',     @server_user.id)
    user_stats = @node.invoke_request('omega-queue', 'manufactured::get_entities',
                                      'of_type',     'Manufactured::Station',
                                      'owned_by',     @server_user.id)

    user_ships.each { |sh|
      self << MonitoredShip.new(sh)
    }

    user_stats.each { |st|
      self << MonitoredStation.new(st)
    }
  end

end

# currently uses ncurses to render output
class MonitoredOutput
  attr_accessor :registry

  PANEL_WIDTH   = 42
  PANEL_HEIGHT  = 30
  PANEL_PADDING = 5

  def initialize
    @scroll_distance = 0

    @scr = Ncurses.initscr();
    #Ncurses.start_color();
    Ncurses.cbreak();
    Ncurses.noecho();
    Ncurses.nodelay(@scr, true);
    Ncurses.keypad(@scr, true);

    @cosmos_win = Ncurses::WINDOW.new(PANEL_HEIGHT, PANEL_WIDTH, 1, 1)
    @cosmos_win.bkgd(Ncurses.COLOR_PAIR(3))
    @cosmos_win.keypad(TRUE)
    @cosmos_win.scrollok(TRUE)

    @manu_win = Ncurses::WINDOW.new(PANEL_HEIGHT, PANEL_WIDTH, 1, PANEL_WIDTH + PANEL_PADDING)
    @manu_win.bkgd(Ncurses.COLOR_PAIR(3))
    @manu_win.keypad(TRUE)

    @users_win = Ncurses::WINDOW.new(PANEL_HEIGHT, PANEL_WIDTH, 1, (PANEL_WIDTH + PANEL_PADDING) * 2)
    @users_win.bkgd(Ncurses.COLOR_PAIR(3))
    @users_win.keypad(TRUE)

    @tests_win = Ncurses::WINDOW.new(PANEL_HEIGHT, PANEL_WIDTH, 1, (PANEL_WIDTH + PANEL_PADDING) * 3)
    @tests_win.bkgd(Ncurses.COLOR_PAIR(3))
    @tests_win.keypad(TRUE)

    cosmos_panel = Ncurses::Panel.new_panel(@cosmos_win)
    manu_panel = Ncurses::Panel.new_panel(@manu_win)
    users_panel = Ncurses::Panel.new_panel(@users_win)
    tests_panel = Ncurses::Panel.new_panel(@tests_win)
    @panels = [cosmos_panel, manu_panel, users_panel]
    @panels = [cosmos_panel, manu_panel, tests_panel]
    Ncurses::Panel.set_panel_userptr(cosmos_panel, manu_panel)
    Ncurses::Panel.set_panel_userptr(manu_panel,   users_panel)
    Ncurses::Panel.set_panel_userptr(users_panel,   tests_panel)
    Ncurses::Panel.set_panel_userptr(tests_panel,   cosmos_panel)

    @current_panel = cosmos_panel
    Ncurses::Panel.top_panel(@current_panel)
    Ncurses::Panel.update_panels

    #@windows = [@cosmos_win, @manu_win]
    #@windows.each { |w| w.wrefresh }
  end

  def outside_boundry?(distance)
    nd = distance + @scroll_distance + 3
    return nd < 5 || nd > (PANEL_HEIGHT + 1)
  end

  def scrolled_distance(distance)
    return distance + @scroll_distance
  end

  def refresh
    @cosmos_win.clear
    @cosmos_win.box(0, 0)
    @cosmos_win.move(1,1)
    @cosmos_win.addstr("Cosmos")

    @users_win.clear
    @users_win.box(0, 0)
    @users_win.move(1,1)
    @users_win.addstr("Users")

    @manu_win.clear
    @manu_win.box(0, 0)
    @manu_win.move(1,1)
    @manu_win.addstr("Manufactured")

    @tests_win.clear
    @tests_win.box(0, 0)
    @tests_win.move(1,1)
    @tests_win.addstr("Tests")

    counter = 2
    subcounter = 2
    @registry.users.each { |id,u|
      @users_win.move(scrolled_distance(counter), 2)
      @users_win.addstr("- #{u.server_user.id}") unless outside_boundry?(counter)
      u.ships.each { |sid,s|
        @manu_win.move(scrolled_distance(subcounter), 2)
        @manu_win.addstr("- #{s.server_ship.id} (ship)".truncate(PANEL_WIDTH - 10))  unless outside_boundry?(subcounter)
        subcounter += 1
        @manu_win.move(scrolled_distance(subcounter), 4)
        @manu_win.addstr("@ #{s.server_ship.location}") unless outside_boundry?(subcounter)
        subcounter += 1
      }

      u.stations.each { |sid,s|
        @manu_win.move(scrolled_distance(subcounter), 2)
        @manu_win.addstr("- #{s.server_station.id} (station)".truncate(PANEL_WIDTH - 10)) unless outside_boundry?(subcounter)
        subcounter += 1
        @manu_win.move(scrolled_distance(subcounter), 4)
        @manu_win.addstr("@ #{s.server_station.location}") unless outside_boundry?(subcounter)
        subcounter += 1
      }
      counter += 1
    }

    counter = 2
    @registry.galaxies.each { |name,g|
      @cosmos_win.move(scrolled_distance(counter), 2)
      @cosmos_win.addstr("Galaxy: #{g.server_galaxy.name}") unless outside_boundry?(counter)
      counter += 1
      g.server_galaxy.solar_systems.each { |s|
        @cosmos_win.move(scrolled_distance(counter), 3)
        @cosmos_win.addstr("System: #{s.name}") unless outside_boundry?(counter)
        counter += 1

        @cosmos_win.move(scrolled_distance(counter), 4)
        @cosmos_win.addstr("Star: #{s.star.name}") if s.star && !outside_boundry?(counter)
        counter += 1
        s.planets.each { |p|
          @cosmos_win.move(scrolled_distance(counter), 4)
          @cosmos_win.addstr("Planet: #{p.name}") unless outside_boundry?(counter)
          counter += 1
          @cosmos_win.move(scrolled_distance(counter), 5)
          @cosmos_win.addstr("@ #{p.location}") unless outside_boundry?(counter)
          counter += 1

          #p.moons.each { |m|
          #  @cosmos_win.move(scrolled_distance(counter), 5)
          #  @cosmos_win.addstr("Moon: #{m.name}")
          #  counter += 1
          #}
        }
        s.asteroids.each { |a|
          @cosmos_win.move(scrolled_distance(counter), 4)
          @cosmos_win.addstr("Asteroid: #{a.name.truncate(PANEL_WIDTH - 20)}") unless outside_boundry?(counter)
          counter += 1
        }
      }
      counter += 1
    }
    #@current_panel.window.scrl @scroll_distance
    Ncurses::Panel.update_panels
  end

  def handle_input
    @terminate = false
    until @terminate
      chin = @cosmos_win.getch
      if chin == 'q'.ord
        @registry.stop
      elsif chin == "\t"[0].ord
        @current_panel = Ncurses::Panel.panel_userptr(@current_panel)
        Ncurses::Panel.top_panel(@current_panel)
        Ncurses::Panel.update_panels
        Ncurses.doupdate
      elsif chin == Ncurses::KEY_UP
        @scroll_distance += 1
        refresh
      elsif chin == Ncurses::KEY_DOWN
        @scroll_distance -= 1
        refresh
      end
    end
    return self
  end

  def stop
    @terminate = true
    return self
  end

  def close
    Ncurses.echo()
    Ncurses.nocbreak()
    Ncurses.nl()
    Ncurses.endwin();
    return self
  end
end


class MonitoredRegistry
  attr_accessor :galaxies
  attr_accessor :users
  attr_accessor :tests

  def initialize(node, output)
    @node = node
    @galaxies = {}
    @users    = {}
    @tests    = {}
    @output   = output
    @output.registry = self
  end

  def <<(entity)
    if entity.is_a?(MonitoredUser)
      @users[entity.server_user.id] = entity
    elsif entity.is_a?(MonitoredGalaxy)
      @galaxies[entity.server_galaxy.name] = entity
    end
  end

  def run_tests
  end

  def refresh
    @node.invoke_request('omega-queue', 'users::get_entities', 'of_type', 'Users::User').each { |u|
      mu = MonitoredUser.new(@node, u)
      self << mu
      mu.refresh
    }

    @node.invoke_request('omega-queue', 'cosmos::get_entities', 'of_type', 'galaxy').each { |g|
      mg = MonitoredGalaxy.new(@node, g)
      self << mg
      mg.refresh
    }

    run_tests

    @output.refresh
  end

  def start
    @terminate = false
    @run_thread = Thread.new {
      until @terminate
        refresh
        sleep 3
      end
    }
    return self
  end

  def stop
    @terminate = true
    @output.stop.close
    return self
  end

  def join
    puts "Terminating run cycle..."
    @run_thread.join
    return self
  end
end

#RJR::Logger.log_level= ::Logger::INFO

node = RJR::AMQPNode.new :broker => 'localhost', :node_id => 'monitor'

admin = Users::User.new :id => 'admin', :password => 'nimda'
session = node.invoke_request 'omega-queue', 'users::login', admin
node.message_headers['session_id'] = session.id

output = MonitoredOutput.new
registry = MonitoredRegistry.new(node, output).start

output.handle_input
registry.join
