/* Omega Ship Visited Route Gfx
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.ShipVisitedRoute = function(args){
  if(!args) args = {};
  var config   = args['config'];
  var event_cb = args['event_cb'];
  if(args['line'])
    this.line = args['line'];
  else
    this.init_gfx();
};

Omega.ShipVisitedRoute.prototype = {
  color    : 0xAAAAAA,
  num      : 10,
  min_distance : 100,

  clone : function(){
    return new Omega.ShipVisitedRoute({line : this.line.clone()});
  },

  _geometry : function(){
    if(this.line) return this.line.geometry;
    var geo = new THREE.Geometry({dynamic : true});
    for(var n = 0; n < this.num; n++)
      geo.vertices.push(new THREE.Vector3());
    return geo;
  },

  _material : function(){
    return new THREE.LineBasicMaterial({color: this.color})
  },

  init_gfx : function(){
    this.line = new THREE.Line(this._geometry(),
                               this._material());
  },

  mark_visited : function(){
    var loc = this.omega_entity.scene_location();
    if(this.last_pos){
      var last_distance = loc.distance_from(this.last_pos[0],
                                            this.last_pos[1],
                                            this.last_pos[2]);

      if(last_distance > this.min_distance){
        for(var n = this.num-1; n > 0; n--){
          var prev = this._geometry().vertices[n-1];
          this._geometry().vertices[n].set(prev.x, prev.y, prev.z);
        }
        this._geometry().vertices[0].set(loc.x, loc.y, loc.z);
        this._geometry().verticesNeedUpdate = true;
        this.last_pos = loc.coordinates();
      }
    }else{
      this.last_pos = loc.coordinates();
      for(var n = 0; n < this.num; n++)
        this._geometry().vertices[n].set(loc.x, loc.y, loc.z);
    }
  },

  run_effects : function(){
    this.mark_visited();
  }
};

Omega.ShipTrails.prototype.update = Omega.ShipTrails.prototype._disabled_update;
