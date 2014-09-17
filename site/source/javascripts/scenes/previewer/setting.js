/* Omega Previewer Scene Setting
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require 'ui/canvas/components/skybox'
//= require 'omega/gen'

Omega.Scenes.PreviewerSetting = function(){
};

Omega.Scenes.PreviewerSetting.prototype = {
  /// distance between entities
  distance : 500,

  _ships : function(){
    var i = 1;
    var ships = [];
    for(var s in Omega.Config.resources.ships){
      var loc  = new Omega.Location();
      var ship = new Omega.Ship({type: s, location : loc});

      var n = i % 2 == 0 ? 1 : -1;
      loc.set(i * n * this.distance, 0, 0);
      loc.set_orientation(0, 0, 1);
      i += 1;

      ships.push(ship);
    }
    return ships;
  },

  _stations : function(){
    var i = 1;
    var stations = [];
    for(var s in Omega.Config.resources.stations){
      var loc     = new Omega.Location();
      var station = new Omega.Station({type: s, location : loc});

      var n = i % 2 == 0 ? 1 : -1;
      loc.set(i * n * this.distance, this.distance * 2, -this.distance);
      loc.set_orientation(0, 0, 1);
      i += 1;

      stations.push(station);
    }
    return stations;
  },

  _entities : function(){
    return this._ships().concat(this._stations());
  },

  _system : function(){
    return Omega.Gen.solar_system();
  },

  _light : function(){
    return new THREE.AmbientLight( 0x404040 );
  },

  load : function(cb){
    var _this = this;
    Omega.Gen.init(function(){
      _this.system    = _this._system();
      _this.light     = _this._light();
      _this.entities  = _this._entities();
      _this.system.children = _this.entities;
      _this.skybox = new Omega.UI.CanvasSkybox();
      cb();
    });
  },
};
