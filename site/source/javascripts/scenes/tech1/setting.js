/* Omega Tech1 Scene Setting
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require 'ui/canvas/axis'
//= require 'ui/canvas/skybox'
//= require 'omega/gen'

Omega.Scenes.Tech1Setting = function(){
};

Omega.Scenes.Tech1Setting.prototype = {
  _star : function(){
    return Omega.Gen.star();
  },

  _asteroids : function(){
    var asteroids = [];
    for(var a = 0; a < 10; a++){
      var asteroid = Omega.Gen.asteroid()
      asteroid.location = Omega.Gen.random_loc({min :  -6000,   max : 6000,
                                                min_y : -200, max_y : 200});
      asteroids.push(asteroid);
    }
    return asteroids;
  },

  _system : function(){
    return Omega.Gen.solar_system();
  },

  _station : function(){
    var station = Omega.Gen.station();
    station.location.set(5000, 0, 5000);
    return station;
  },

  _base_ship : function(type){
    var ship = Omega.Gen.ship({type : type});
    ship.include_hp_bar    = false;
    ship.include_highlight = false;
    return ship;
  },

  _ship1 : function(){
    var ship = this._base_ship('mining');
    ship.location.set(3000, 0, 3000);

    var dir = ship.location.direction_to(5000, 0, 5000);
    ship.location.set_orientation(dir);

    var ms = Omega.Gen.linear_ms({dx: dir[0], dy: dir[1],
                                  dz: dir[2], speed: 20});
    ship.location.movement_strategy = ms;

    return ship;
  },

  _ship2 : function(){
    var ship = this._base_ship('corvette');
    ship.location.set(2200, 0, 2700);

    var dir = ship.location.direction_to(4200, 0, 4700);
    ship.location.set_orientation(dir);

    var ms = Omega.Gen.linear_ms({dx: dir[0], dy: dir[1],
                                  dz: dir[2], speed: 20});
    ship.location.movement_strategy = ms;

    return ship;
  },

  _ship3 : function(){
    var ship = this._base_ship('corvette');
    ship.location.set(2700, 0, 2200);

    var dir = ship.location.direction_to(4700, 0, 4200);
    ship.location.set_orientation(dir);

    var ms = Omega.Gen.linear_ms({dx: dir[0], dy: dir[1],
                                  dz: dir[2], speed: 20});
    ship.location.movement_strategy = ms;

    return ship;
  },

  _ship4 : function(){
    var ship = this._base_ship('transport');
    ship.location.set(2000, 0, 2000);

    var dir = ship.location.direction_to(5000, 0, 5000);
    ship.location.set_orientation(dir);

    var ms = Omega.Gen.linear_ms({dx: dir[0], dy: dir[1],
                                  dz: dir[2], speed: 20});
    ship.location.movement_strategy = ms;

    return ship;
  },

  _ships : function(){
    return [this._ship1(), this._ship2(), this._ship3(), this._ship4()];
  },

  load : function(cb){
    var _this = this;
    Omega.Gen.init(function(){
      _this.system = _this._system();
      _this.system.children = [_this._star()].concat(_this._asteroids());

      _this.station = _this._station();
      _this.ships   = _this._ships();

      _this.axis   = new Omega.UI.CanvasAxis();
      _this.skybox = new Omega.UI.CanvasSkybox();
      cb();
    });
  },

  scene_components : function(){
    /// skybox should be added to skyscene
    return [this.axis, this.station].concat(this.ships);
  }
};
