/* Omega JS Component Generator
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.Gen = {
  next_id : function(){
    if(!Omega.Gen._next_id) Omega.Gen._next_id = 0;
    Omega.Gen._next_id += 1;
    return Omega.Gen._next_id;
  },

  elliptical_ms : function(enrml, opts){
    /// generate major axis such that maj . enrml = 0
    var tx   = Math.random();
    var ty   = Math.random();
    var tz   = Math.random();
    var tn   = Omega.Math.nrml(tx,ty,tz);
    var maj  = Omega.Math.cp(tx,ty,tz,enrml.x,enrml.y,enrml.z)
    var majn = Omega.Math.nrml(maj[0], maj[1], maj[2]);
    majx = majn[0]; majy = majn[1]; majz = majn[2];

    /// rotate maj axis by 1.57 around nrml to get min
    var min = Omega.Math.rot(majx,majy,majz,1.57,
                             enrml.x,enrml.y,enrml.z)
    minn = Omega.Math.nrml(min[0],min[1],min[2]);
    var minx = minn[0]; var miny = minn[1]; var minz = minn[2];

    return $.extend({dmajx : majx, dmajy : majy, dmajz : majz,
                     dminx : minx, dminy : miny, dminz : minz},
                     opts);
  },

  asteroid_belt : function(ms){
    var locs  = [];
    var path  = Omega.Math.elliptical_path(ms);
    var nlocs = Math.floor(path.length / 30);
    for(var l = 0; l < 30; l++){
      var pp  = path[nlocs * l];
      locs.push(Omega.Gen.loc_from_coords(pp));
    }

    return Omega.Gen.asteroid_field(ui, locs);
  },

  asteroid_field : function(locations){
    var asteroids = [];
    for(var l = 0; l < locations.length; l++){
      var ast = new Omega.Asteroid({id : 'ast' + l,
                  location : locations[l]});
      asteroids.push(ast);
    }
    return asteroids;
  },

  ship : function(opts){
    if(!opts) opts = {};
    if(!opts.id) opts.id = 'ship' + this.next_id();
    if(!opts.location)
      opts.location = new Omega.Location();
    if(!opts.location.x) opts.location.x = 0;
    if(!opts.location.y) opts.location.y = 0;
    if(!opts.location.z) opts.location.z = 0;
    if(!opts.location.orientation_x) opts.location.orientation_x = 0;
    if(!opts.location.orientation_y) opts.location.orientation_y = 0;
    if(!opts.location.orientation_z) opts.location.orientation_z = 1;
    if(!opts.location.movement_strategy)
      opts.location.movement_strategy =
        {json_class : 'Motel::MovementStrategies::Stopped'};

    return new Omega.Ship(opts);
  },

  station : function(opts){
    if(!opts) opts = {};
    if(!opts.id) opts.id = 'station' + this.next_id();
    if(!opts.location)
      opts.location = new Omega.Location();
    if(!opts.location.x) opts.location.x = 0;
    if(!opts.location.y) opts.location.y = 0;
    if(!opts.location.z) opts.location.z = 0;
    if(!opts.location.orientation_x) opts.location.orientation_x = 0;
    if(!opts.location.orientation_y) opts.location.orientation_y = 0;
    if(!opts.location.orientation_z) opts.location.orientation_z = 1;
    if(!opts.location.movement_strategy)
      opts.location.movement_strategy =
        {json_class : 'Motel::MovementStrategies::Stopped'};

    return new Omega.Station(opts);
  }
};
