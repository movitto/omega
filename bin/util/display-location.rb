# use rubygame to display all of a location's children
#
# Flags:
#  -h --help
#  -d --db-config
#  -i --location-id
#
# Copyright (C) 2009 Mohammed Morsi <movitto@yahoo.com>
# See COPYING for the License of this software

require 'rubygems'
require 'optparse'
require 'rubygame'
require 'motel'

include Rubygame
include Rubygame::Events
include Rubygame::EventActions
include Rubygame::EventTriggers

include Motel
include Motel::Models

# ScreenManager manages a singleton Rubygame::Screen
class ScreenManager
  
  # get the rubygame screen. if screen is not defined, 
  # optional width height may be given to initialize
  def self.screen(size = [900,600])
    unless defined? @@screen
      @@screen = Rubygame::Screen.new size, 0, [Rubygame::HWSURFACE, Rubygame::DOUBLEBUF]
      @@screen.title = "Location Viewer"
    end
    @@screen
  end

  # draw the screen
  def self.draw
    screen.fill( :black )

    # draw border
    screen.draw_line([BORDER_WIDTH, BORDER_WIDTH], 
                     [BORDER_WIDTH, screen.h - BORDER_WIDTH],
                     :white)
    screen.draw_line([BORDER_WIDTH, BORDER_WIDTH], 
                     [screen.w - BORDER_WIDTH, BORDER_WIDTH],
                     :white)
    screen.draw_line([screen.w - BORDER_WIDTH, BORDER_WIDTH],
                     [screen.w - BORDER_WIDTH, screen.h - BORDER_WIDTH],
                     :white)
    screen.draw_line([BORDER_WIDTH, screen.h - BORDER_WIDTH],
                     [screen.w - BORDER_WIDTH, screen.h - BORDER_WIDTH],
                     :white)

    # draw axis
    screen.draw_line([BORDER_WIDTH + screen_width / 2,BORDER_WIDTH],
                     [BORDER_WIDTH + screen_width / 2, screen.h - BORDER_WIDTH],
                     :white)
    screen.draw_line([BORDER_WIDTH, BORDER_WIDTH + screen_height / 2],
                     [screen.w - BORDER_WIDTH, BORDER_WIDTH + screen_height / 2],
                     :white)
  end

  # set to the border to appear on all edges 
  # of the screen in pixels
  BORDER_WIDTH = 25

  # get screen width
  def self.screen_width
     screen.w - BORDER_WIDTH * 2
  end

  # get screen height
  def self.screen_height
     screen.h -  BORDER_WIDTH * 2
  end

  # get quadrant width
  def self.quadrant_width
     screen.w/2 - BORDER_WIDTH
  end

  # get quadrant height
  def self.quadrant_height
     screen.h/2 - BORDER_WIDTH
  end

  # get the screen x coordinate of the center
  def self.x_center
    quadrant_width + BORDER_WIDTH 
  end

  # get the screen y coordinate of the center
  def self.y_center
    quadrant_height + BORDER_WIDTH 
  end
end

# locations manager manages a collection of locations
class LocationsManager

  # add location to be taken into consideration during calculations
  def self.add_location_manager(lm)
    @@location_managers = [] unless defined? @@location_managers
    @@location_managers.push lm unless @@location_managers.include? lm
  end

  # grab the list of location managers
  def self.location_managers
    @@location_managers
  end

  # find location with the furthest coodinates
  def self.find_furthest_coordinates
    fx = fy = fz = 0
    @@location_managers.each { |lm|
       l = lm.location

       #tfd = Math.sqrt(l.x ** 2 + l.y ** 2 + l.z ** 2)
       fx = l.x.abs if l.x.abs > fx
       fy = l.y.abs if l.y.abs > fy
       fz = l.z.abs if l.z.abs > fz
    }
    return fx, fy, fz
  end

  # adjust the coordinates specified by location
  def self.adjust_coordinates(location)
    fx, fy, fz = find_furthest_coordinates
    w_scale = ScreenManager.quadrant_width / fx.abs
    h_scale = ScreenManager.quadrant_height / fy.abs
    w_scale = 1 if w_scale.nan? || w_scale.infinite?
    h_scale = 1 if h_scale.nan? || h_scale.infinite?

    scaled_adj_coordinates = (location.x * w_scale), (location.y * h_scale)
    screen_adj_coordinates = (ScreenManager.x_center + scaled_adj_coordinates[0]), 
                             (ScreenManager.y_center - scaled_adj_coordinates[1])
    return screen_adj_coordinates
  end

end

# manages a single location
class LocationManager
    #include Sprites::Sprite

    attr_reader :location

   def initialize(location)
      @location = location
   end

   def draw
      coordinates = LocationsManager.adjust_coordinates(@location)
      color = location.id % 2 == 1 ? :red : :blue
      ScreenManager.screen.draw_line([ScreenManager.x_center,ScreenManager.y_center], coordinates, color)
      ScreenManager.screen.draw_circle_s(coordinates, 10, color)
   end
end

class Game
   include EventHandler::HasEventHandler

    def initialize
       @queue = Rubygame::EventQueue.new
       @queue.enable_new_style_events

       @clock = Rubygame::Clock.new
       @clock.target_framerate = 30
       @clock.calibrate
       @clock.enable_tick_events

        make_magic_hooks(  {
          :escape => :quit,
          :q => :quit,
          QuitRequested => :quit
        })
    end

    # Quit the game
    def quit
      puts "Quitting!"
      throw :quit
    end
 
    def run
      catch(:quit) do
       loop do
        step
       end
      end
    end

    def step
       ScreenManager.draw
       @queue.fetch_sdl_events
       @queue << @clock.tick

        @queue.each do |ev|
           handle(ev)
        end

       LocationsManager.location_managers.each { |lm| lm.draw }
       ScreenManager.screen.update
    end

end

def main()
  db_conf = location_id = nil

  # setup cmd line options
  opts = OptionParser.new do |opts|
    opts.on("-h", "--help", "Print help message") do
       puts opts
       exit
    end
    opts.on("-d", "--db-conf [path]", "Motel DB Conf File") do |path|
       db_conf = path
    end
    opts.on("-l", "--location-id [id]", "ID of location to display") do |id|
       location_id = id.to_i
    end
  end

  # parse cmd line
  begin
    opts.parse!(ARGV)
  rescue OptionParser::InvalidOption
    puts opts
    exit
  end

  db_conf     = ENV['MOTEL_DB_CONF']     if db_conf.nil?
  if db_conf.nil? || location_id.nil?
    puts "both db config and location id needed"
    exit
  end

  Conf.setup( :db_conf     => db_conf,
             :env         => "production",
             :log_level   => ::Logger::FATAL) # FATAL ERROR WARN INFO DEBUG


  game = Game.new

  parent = Location.find(location_id)
  parent.children.each { |child|
#if child.entity_type == "Asteroid"
puts "c #{child}"
    LocationsManager.add_location_manager LocationManager.new(child)
#end
  }

  game.run
  Rubygame.quit()
end

begin
main()
rescue Exception => e
 puts "#{e} #{e.backtrace.join("\n")}"
end
