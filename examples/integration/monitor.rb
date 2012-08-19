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
    Ncurses::Panel.set_panel_userptr(users_panel,  tests_panel)
    Ncurses::Panel.set_panel_userptr(tests_panel,  cosmos_panel)

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

  def refresh(invalidated = nil)
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
        @scroll_distance += 1 unless @scroll_distance > -1
        refresh
      elsif chin == Ncurses::KEY_DOWN
        @scroll_distance -= 1 #unless @scroll_distance < (-1 * self.max_window_text)
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


#RJR::Logger.log_level= ::Logger::INFO

node = RJR::AMQPNode.new :broker => 'localhost', :node_id => 'monitor'

admin = Users::User.new :id => 'admin', :password => 'nimda'
session = node.invoke_request 'omega-queue', 'users::login', admin
node.message_headers['session_id'] = session.id

output = MonitoredOutput.new
registry = Omega::MonitoredRegistry.new(node, output).start

output.handle_input
registry.join
