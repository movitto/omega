/* Omega Tech2 Scene Setting
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require 'ui/canvas/skybox'
//= require 'omega/gen'

Omega.Scenes.Tech2Setting = function(){
};

Omega.Scenes.Tech2Setting.prototype = {
  _star : function(){
    return Omega.Gen.star();
  },

  _asteroids : function(){
    var asteroids = [];
    for(var a = 0; a < 5; a++){
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

  _base_ship : function(type){
    var ship = Omega.Gen.ship({type : type});
        ship.location = Omega.Gen.random_loc({min :  -6000,   max : 6000,
                                              min_y : -200, max_y : 200});
        ship.location.movement_strategy = Omega.Gen.linear_ms({speed: 75});
        ship.location.set_orientation(ship.location.movement_strategy.dx,
                                      ship.location.movement_strategy.dy,
                                      ship.location.movement_strategy.dz);
    ship.include_hp_bar    = false;
    ship.include_highlight = false;
    return ship;
  },



  _ships : function(){
    var mining   = 3;
    var corvette = 5;

    var ships = [];
    for(var m = 0; m < mining; m++)
      ships.push(this._base_ship('mining'));
    for(var c = 0; c < corvette; c++)
      ships.push(this._base_ship('corvette'));

    return ships;
  },

  load : function(cb){
    var _this = this;
    Omega.Gen.init(function(){
      _this.system = _this._system();
      _this.ships  = _this._ships();
      _this.system.children = [_this._star()].concat(_this._asteroids()).
                                              concat(_this.ships);
      _this.skybox = new Omega.UI.CanvasSkybox();
      cb();
    });
  },
};
