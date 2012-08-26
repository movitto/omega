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

  PANEL_WIDTH   = 95
  PANEL_HEIGHT  = 40
  PANEL_PADDING = 5

  def initialize
    # config
    @show_asteroids = false
    @show_resources = false
    @scroll_distance = 0

    @scr = Ncurses.initscr();
    Ncurses.start_color();
    Ncurses.cbreak();
    Ncurses.noecho();
    Ncurses.nodelay(@scr, true);
    Ncurses.keypad(@scr, true);

    Ncurses.init_pair(1, Ncurses::COLOR_BLACK, Ncurses::COLOR_BLUE);
    Ncurses.init_pair(2, Ncurses::COLOR_BLACK, Ncurses::COLOR_WHITE);
    Ncurses.init_pair(3, Ncurses::COLOR_RED,   Ncurses::COLOR_WHITE);
    Ncurses.init_pair(4, Ncurses::COLOR_GREEN, Ncurses::COLOR_WHITE);
    @scr.bkgd(Ncurses.COLOR_PAIR(1));

    @tests_win = Ncurses::WINDOW.new(PANEL_HEIGHT, PANEL_WIDTH, 1, 1)
    @tests_win.bkgd(Ncurses.COLOR_PAIR(2))
    @tests_win.keypad(TRUE)

    @manu_win = Ncurses::WINDOW.new(PANEL_HEIGHT, PANEL_WIDTH, 1, 1)
    @manu_win.bkgd(Ncurses.COLOR_PAIR(2))
    @manu_win.keypad(TRUE)

    @users_win = Ncurses::WINDOW.new(PANEL_HEIGHT, PANEL_WIDTH, 1, 1)
    @users_win.bkgd(Ncurses.COLOR_PAIR(2))
    @users_win.keypad(TRUE)

    @cosmos_win = Ncurses::WINDOW.new(PANEL_HEIGHT, PANEL_WIDTH, 1, 1)
    @cosmos_win.bkgd(Ncurses.COLOR_PAIR(2))
    @cosmos_win.keypad(TRUE)

    @controls_win = Ncurses::WINDOW.new(10, 50, PANEL_HEIGHT * 2 / 3, PANEL_WIDTH + 10)
    @controls_win.bkgd(Ncurses.COLOR_PAIR(2))

    tests_panel  = Ncurses::Panel.new_panel(@tests_win)
    users_panel  = Ncurses::Panel.new_panel(@users_win)
    manu_panel   = Ncurses::Panel.new_panel(@manu_win)
    cosmos_panel = Ncurses::Panel.new_panel(@cosmos_win)
    Ncurses::Panel.set_panel_userptr(cosmos_panel, users_panel)
    Ncurses::Panel.set_panel_userptr(users_panel,  manu_panel)
    Ncurses::Panel.set_panel_userptr(manu_panel,  tests_panel)
    Ncurses::Panel.set_panel_userptr(tests_panel,  cosmos_panel)

    controls_panel = Ncurses::Panel.new_panel(@controls_win)

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

  def run_tests
    @tests    = {}
    @registry.users.each { |id,u|
      unless Omega::MonitoredUser::SYSTEM_USERS.include?(id)
        @tests[:user_has_alliance] ||= []
        if u.alliances.size > 0 && u.alliances.first.id == "#{u.id}-alliance"
          @tests[:user_has_alliance] << {:entity => u.server_user, :message => "has user alliance", :success => true}
        else
          @tests[:user_has_alliance] << {:entity => u.server_user, :message => "should have user alliance", :success => false}
        end

        @registry.galaxies.each { |gid, g|
          g.solar_systems.each { |sys|
            @tests[:system_frigate] ||= []
            @tests[:system_station] ||= []
            sys_ships    = u.ships.select { |sid,s| s.solar_system.name == sys.name }
            sys_frigates = u.ships.select { |sid,s| s.solar_system.name == sys.name &&
                                                    s.id =~ /#{u.id}-frigate-ship.*/ }
            sys_stations = u.stations.select { |sid,s| s.solar_system.name == sys.name &&
                                                       s.id =~ /#{u.id}-manufacturing-station.*/ }

            if sys_ships.size > 0
              if sys_frigates.size == 0
                @tests[:system_frigate] << {:entity => sys, :message => "system with #{u.id}'s ships does not have frigate", :success => false }

              elsif sys_frigates.size > 1
                @tests[:system_frigate] << {:entity => sys, :message => "system with has multiple frigates for user #{u.id}", :success => false }

              else
                @tests[:system_frigate] << {:entity => sys, :message => "system with #{u.id}'s ships has frigate", :success => true }

              end

              if sys_stations.size == 0
                @tests[:system_station] << {:entity => sys, :message => "system with #{u.id}'s ships does not have a station", :success => false }

              elsif sys_stations.size > 1
                @tests[:system_station] << {:entity => sys, :message => "system with has multiple stations for user #{u.id}", :success => false }

              else
                @tests[:system_station] << {:entity => sys, :message => "system with #{u.id}'s ships has a station", :success => true }
              end

            end
          }
        }

        #is_mining = !u.ships.find { |i,s| s.mining }.nil?
        u.ships.each { |sid,sh|
          # ensure each system only has one frigate
          if sh.id =~ /.*-frigate-ship.*/
            @tests[:frigate_movement] ||= []
            if sh.location.movement_strategy.is_a?(Motel::MovementStrategies::Stopped)
              if sh.cargo_quantity > 0
                @tests[:frigate_movement] << {:entity => sh.server_ship, :message => "should be moving", :success => false}
              else
                @tests[:frigate_movement] << {:entity => sh.server_ship, :message => "is stopped", :success => true}
              end

            elsif sh.location.movement_strategy.is_a?(Motel::MovementStrategies::Linear)
              @tests[:frigate_movement] << {:entity => sh.server_ship, :message => "is moving", :success => true}

            else
              @tests[:frigate_movement] << {:entity => sh.server_ship, :message => "has invalid movement strategy", :success => false}

            end

          # ensure miners are moving or mining
          elsif sh.id =~ /.*-mining-ship.*/
            @tests[:mining_moving_or_signaling] ||= []
            if sh.mining || sh.location.movement_strategy.is_a?(Motel::MovementStrategies::Linear) ||
               (sh.cargo_quantity + sh.mining_quantity) >= sh.cargo_capacity
              @tests[:mining_moving_or_signaling] << {:entity => sh.server_ship, :message => "miner moving, mining, or signaling", :success => true }
            else
              @tests[:mining_moving_or_signaling] << {:entity => sh.server_ship, :message => "miner not moving, mining, or signaling", :success => false }
            end

          # ensure corvettes are moving / attacking
          elsif sh.id =~ /.*-corvette-ship.*/
            @tests[:corvette_movement] ||= []
            if sh.location.movement_strategy.is_a?(Motel::MovementStrategies::Follow)
              @tests[:corvette_movement] << {:entity => sh.server_ship, :message => "corvette has follow movement strategy", :success => true}
            else
              @tests[:corvette_movement] << {:entity => sh.server_ship, :message => "corvette should be following a miner", :success => false}
            end

            # TODO ensure that if within attacking distance of enemy, is attacking
          end
        }

        u.stations.each { |sid,st|
          if st.id =~ /.*-manufacturing-station.*/
            min  = (Manufactured::Ship.construction_cost(:frigate) + Manufactured::Station.construction_cost(:manufacturing))
            mina = (Manufactured::Ship.construction_cost(:mining)  + Manufactured::Ship.construction_cost(:corvette))
            min  = mina if mina < min

            @tests[:station_using_resources] ||= []
            if st.cargo_quantity >= min
              @tests[:station_using_resources] << {:entity => st.server_station, :message => "station not using resources properly", :success => false}
            else
              @tests[:station_using_resources] << {:entity => st.server_station, :message => "station using resources properly", :success => true}
            end
          end
        }
      end
    }
  end

  def refresh(invalidated = nil)
    run_tests
    title_str = ["Cosmos", "Users", "Manufactured", "Tests"]
    write_title  =
      lambda { |win, b|
        title_str.each { |ts|
          win.attron(Ncurses::A_UNDERLINE)
          win.attron(Ncurses::A_BOLD)  if b == ts
          win.addstr(ts)
          win.attroff(Ncurses::A_BOLD) if b == ts
          win.attroff(Ncurses::A_UNDERLINE)
          win.addstr('|') unless ts == title_str.last
        }
      }

    @cosmos_win.clear
    @cosmos_win.box(0, 0)
    @cosmos_win.move(1,1)
    write_title.call(@cosmos_win, "Cosmos")

    @users_win.clear
    @users_win.box(0, 0)
    @users_win.move(1,1)
    write_title.call(@users_win, "Users")

    @manu_win.clear
    @manu_win.box(0, 0)
    @manu_win.move(1,1)
    write_title.call(@manu_win, "Manufactured")

    @tests_win.clear
    @tests_win.box(0, 0)
    @tests_win.move(1,1)
    write_title.call(@tests_win, "Tests")

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
        if @show_resources
          s.resources.each { |rsid,q|
            @manu_win.move(scrolled_distance(subcounter), 6)
            @manu_win.addstr("#{q} of #{rsid}")
            subcounter += 1
          }
        end
      }

      u.stations.each { |sid,s|
        @manu_win.move(scrolled_distance(subcounter), 2)
        @manu_win.addstr("- #{s.server_station.id} (station)".truncate(PANEL_WIDTH - 10)) unless outside_boundry?(subcounter)
        subcounter += 1
        @manu_win.move(scrolled_distance(subcounter), 4)
        @manu_win.addstr("@ #{s.server_station.location}") unless outside_boundry?(subcounter)
        subcounter += 1
        if @show_resources
          s.resources.each { |rsid,q|
            @manu_win.move(scrolled_distance(subcounter), 6)
            @manu_win.addstr("#{q} of #{rsid}")
            subcounter += 1
          }
        end
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
        if @show_asteroids
          s.asteroids.each { |a|
            @cosmos_win.move(scrolled_distance(counter), 4)
            @cosmos_win.addstr("Asteroid: #{a.name.truncate(PANEL_WIDTH - 20)}") unless outside_boundry?(counter)
            counter += 1
            # TODO!
            if @show_resources
            end
          }
        end
      }
      counter += 1
    }

    counter = 2
    @tests.each { |i,ta|
      @tests_win.move(scrolled_distance(counter), 2)
      @tests_win.addstr(i.to_s) unless outside_boundry?(counter)
      counter += 1

      ta.each { |test|
        str = test[:success] ? "success " : "failed "
        str += "#{test[:entity]} #{test[:message]}"
        color = test[:success] ? Ncurses::COLOR_PAIR(4) : Ncurses::COLOR_PAIR(3)
        @tests_win.move(scrolled_distance(counter), 3)
        @tests_win.attron(color)
        @tests_win.addstr(str.truncate(PANEL_WIDTH - 10)) unless outside_boundry?(counter)
        @tests_win.attroff(color)
        counter += 1
      }
    }

    @controls_win.clear
    @controls_win.box(0, 0)
    @controls_win.move(1,1)
    @controls_win.attron(Ncurses::A_BOLD)
    @controls_win.addstr("Controls")
    @controls_win.attroff(Ncurses::A_BOLD)
    @controls_win.move(2,1)
    @controls_win.addstr("TAB to browse through the panels")
    @controls_win.move(3,1)
    @controls_win.addstr("Arrows to scroll")
    @controls_win.move(4,1)
    @controls_win.addstr("Q to exit");
    if @current_panel.window == @cosmos_win
      @controls_win.move(5,1)
      @controls_win.addstr("A to toggle asteroids")
      @controls_win.move(6,1)
      @controls_win.addstr("R to toggle resources")
    elsif @current_panel.window == @manu_win
      @controls_win.move(5,1)
      @controls_win.addstr("R to toggle resources")
    end

    @current_panel.window.move(0,0)
    Ncurses::Panel.update_panels
    Ncurses.doupdate
  end

  def handle_input
    @terminate = false
    until @terminate
      chin = @cosmos_win.getch
      if chin == 'q'.ord
        @registry.stop
      elsif chin == 'a'.ord
        @show_asteroids = !@show_asteroids
      elsif chin == 'r'.ord
        @show_resources = !@show_resources
      elsif chin == "\t"[0].ord
        @scroll_distance = 0
        @current_panel = Ncurses::Panel.panel_userptr(@current_panel)
        Ncurses::Panel.top_panel(@current_panel)
      elsif chin == Ncurses::KEY_UP
        @scroll_distance += 1 unless @scroll_distance > -1
      elsif chin == Ncurses::KEY_DOWN
        @scroll_distance -= 1 #unless @scroll_distance < (-1 * self.max_window_text)
      end
      refresh
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

# reset the terminal to defaults & exit
exec("reset")
