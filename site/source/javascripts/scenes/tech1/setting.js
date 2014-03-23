/* Omega Tech1 Scene Setting
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require 'ui/canvas/axis'
//= require 'ui/canvas/skybox'
//= require 'omega/gen'

Omega.Scenes.Tech1Setting = function(config){
  var star   = Omega.Gen.star();

  var asteroids = [];
  for(var a = 0; a < 10; a++){
    var asteroid = Omega.Gen.asteroid()
    asteroid.location = Omega.Gen.random_loc({min :  -6000,   max : 6000,
                                              min_y : -200, max_y : 200});
    asteroids.push(asteroid);
  }

  this.system = Omega.Gen.solar_system();
  this.system.children = [star].concat(asteroids);

  this.station = Omega.Gen.station();
  this.station.location.set(5000, 0, 5000);

  this.ships = [];
  for(var s = 0; s < 4; s++){
    var type = 'corvette';
    if(s == 0)
      type = 'mining'
    else if(s == 3)
      type = 'transport';

    var ship = Omega.Gen.ship({type : type});
    ship.include_hp_bar    = false;
    ship.include_highlight = false;
    this.ships.push(ship);
  }

  this.ships[0].location.set(3000, 0, 3000);
  var dir0 = this.ships[0].location.direction_to(5000, 0, 5000);
  this.ships[0].location.set_orientation(dir0);
  this.ships[0].location.movement_strategy =
    Omega.Gen.linear_ms({dx: dir0[0], dy: dir0[1], dz: dir0[2], speed: 20});

  this.ships[1].location.set(2200, 0, 2700);
  var dir1 = this.ships[1].location.direction_to(4200, 0, 4700);
  this.ships[1].location.set_orientation(dir1);
  this.ships[1].location.movement_strategy =
    Omega.Gen.linear_ms({dx: dir1[0], dy: dir1[1], dz: dir1[2], speed: 20});

  this.ships[2].location.set(2700, 0, 2200);
  var dir2 = this.ships[2].location.direction_to(4700, 0, 4200);
  this.ships[2].location.set_orientation(dir2);
  this.ships[2].location.movement_strategy =
    Omega.Gen.linear_ms({dx: dir2[0], dy: dir2[1], dz: dir2[2], speed: 20});

  this.ships[3].location.set(2000, 0, 2000);
  var dir3 = this.ships[3].location.direction_to(5000, 0, 5000);
  this.ships[3].location.set_orientation(dir3);
  this.ships[3].location.movement_strategy =
    Omega.Gen.linear_ms({dx: dir3[0], dy: dir3[1], dz: dir3[2], speed: 20});

  this.axis   = new Omega.UI.CanvasAxis();
  this.skybox = new Omega.UI.CanvasSkybox();
};

Omega.Scenes.Tech1Setting.prototype = {
  scene_components : function(){
    return [this.skybox, this.axis, this.station].concat(this.ships);
  }
};
