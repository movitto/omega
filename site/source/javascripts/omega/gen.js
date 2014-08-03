/* Omega JS Entity Generator
 *
 * Provides helpers to easily generate new Omega JS Entities
 * with default parameters.
 *
 * Developer may override any entity initialization parameter
 * via an arg to the method call and a new instance of the
 * JS entity will be returned.
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega/constraint"

Omega.Gen = {
  init : function(cb){
    Omega.Constraint.load(Omega.Constraint.url(), cb);
  },

  next_id : function(){
    if(!Omega.Gen._next_id) Omega.Gen._next_id = 0;
    Omega.Gen._next_id += 1;
    return Omega.Gen._next_id;
  },

  user : function(opts){
    if(!opts) opts = {};
    if(!opts.id) opts.id = 'user' + this.next_id();
    return new Omega.User(opts);
  },

  random_loc : function(opts){
    if(!opts) opts = {};
    var minx = opts['min_x'] || opts['min'] || 0;
    var miny = opts['min_y'] || opts['min'] || 0;
    var minz = opts['min_z'] || opts['min'] || 0;
    var maxx = opts['max_x'] || opts['max'] || 1;
    var maxy = opts['max_y'] || opts['max'] || 1;
    var maxz = opts['max_z'] || opts['max'] || 1;

    var x = Math.random() * (maxx - minx) - maxx;
    var y = Math.random() * (maxy - miny) - maxy;
    var z = Math.random() * (maxz - minz) - maxz;

    return new Omega.Location({x: x, y: y, z: z});
  },

  random_vector : function(){
    return Omega.Math.nrml(Math.random(), Math.random(), Math.random());
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

  asteroid_belt : function(opts){
    if(!opts)     opts     = {};
    if(!opts.num) opts.num = 30;
    if(!opts.ms)  opts.ms  = this.orbit_ms({'for' : 'asteroid_belt'});

    var locs  = [];
    var ms    = opts.ms;
    var num   = opts.num;
    var path  = Omega.Math.elliptical_path(ms);
    var scale = Math.floor(path.length / num);
    for(var l = 0; l < num; l++)
      locs.push(new Omega.Location().set(path[scale * l]));

    return Omega.Gen.asteroid_field(locs);
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

  asteroid : function(opts){
    if(!opts)    opts = {};
    if(!opts.id) opts.id = 'ast' + this.next_id();
    if(!opts.location){
      var loc = Omega.Constraint.gen('asteroid', 'position');
          loc = Omega.Constraint.rand_invert(loc);
      opts.location = new Omega.Location(loc);
    }

    return new Omega.Asteroid(opts);
  },

  jump_gate : function(opts){
    if(!opts) opts = {};
    if(!opts.id) opts.id = 'jg' + this.next_id();
    if(!opts.trigger_distance) opts.trigger_distance = 300;
    if(!opts.location){
      var loc = Omega.Constraint.gen('system_entity', 'position');
          loc = Omega.Constraint.rand_invert(loc);
      opts.location = new Omega.Location(loc);
    }

    return new Omega.JumpGate(opts);
  },

  ship : function(opts){
    if(!opts) opts = {};
    if(!opts.id) opts.id = 'ship' + this.next_id();
    if(!opts.type) opts.type = 'corvette';
    if(!opts.hp) opts.hp = 10;
    if(!opts.max_hp) opts.max_hp = 10;
    if(!opts.location){
      var loc = Omega.Constraint.gen('system_entity', 'position');
          loc = Omega.Constraint.rand_invert(loc);
      opts.location = new Omega.Location(loc);
      opts.location.set_orientation(0,0,1);
      opts.location.movement_strategy =
        {json_class : 'Motel::MovementStrategies::Stopped'}
    }

    return new Omega.Ship(opts);
  },

  station : function(opts){
    if(!opts) opts = {};
    if(!opts.id) opts.id = 'station' + this.next_id();
    if(!opts.type) opts.type = 'manufacturing';
    if(!opts.location){
      var loc = Omega.Constraint.gen('system_entity', 'position');
          loc = Omega.Constraint.rand_invert(loc);
      opts.location = new Omega.Location(loc);
      opts.location.movement_strategy =
        {json_class : 'Motel::MovementStrategies::Stopped'}
    }

    return new Omega.Station(opts);
  },

  linear_ms : function(opts){
    var dir = this.random_vector();
    var ms  = {json_class : 'Motel::MovementStrategies::Linear',
               speed : 1, dx : dir[0], dy : dir[1], dz : dir[2]};
    $.extend(ms, opts);
    return ms;
  },

  stopped_ms : function(opts){
    var ms = {json_class : 'Motel::MovementStrategies::Stopped'};
    $.extend(ms, opts);
    return ms;
  },

  galaxy : function(opts){
    if(!opts) opts = {};
    if(!opts.id) opts.id = 'galaxy' + this.next_id();

    if(!opts.location){
      opts.location = new Omega.Location({x:0,y:0,z:0});
    }

    return new Omega.Galaxy(opts);
  },

  solar_system : function(opts){
    if(!opts) opts = {};
    if(!opts.id) opts.id = 'system' + this.next_id();
    if(!opts.location){
      var loc = Omega.Constraint.gen('system', 'position');
          loc = Omega.Constraint.rand_invert(loc);
      opts.location = new Omega.Location(loc);
    }

    return new Omega.SolarSystem(opts);
  },

  orbit_ms : function(opts){
    if(!opts) opts = {};

    var ms = {e : 0, p : 10, speed: 1.57,
              dmajx: 1, dmajy : 0, dmajz : 0,
              dminx: 0, dminy : 0, dminz : 1};

    if(opts['for']){
      var entity = opts['for'];
      var e = Omega.Constraint.gen(entity, 'e');
      if(e) opts.e = e;

      var p = Omega.Constraint.gen(entity, 'p');
      if(p) opts.p = p;

      var speed = Omega.Constraint.gen(entity, 'speed');
      if(speed) opts.speed = speed;
    }

    $.extend(ms, opts);
    return ms;
  },

  planet : function(opts){
    if(!opts) opts = {};
    if(!opts.id) opts.id = 'planet' + this.next_id();
    if(!opts.size) opts.size = Omega.Constraint.gen('planet', 'size');
    if(!opts.type) opts.type = Math.floor(Omega.Constraint.gen('planet', 'type'));
    if(!opts.location){
      var loc_opts = {x: 0, y: 0, z: 0};
      opts.location = new Omega.Location(loc_opts);

      var orientation = Omega.Constraint.gen('planet', 'orientation');
          orientation = Omega.Constraint.rand_invert(orientation);
          orientation = Omega.Math.nrml(orientation.x,
                                        orientation.y,
                                        orientation.z);
          opts.location.set_orientation(orientation[0],
                                        orientation[1],
                                        orientation[2]);
    }
    if(!opts.location.movement_strategy)
      opts.location.movement_strategy = this.orbit_ms({'for' : 'planet'});

    return new Omega.Planet(opts);
  },

  star : function(opts){
    if(!opts) opts = {};
    if(!opts.id) opts.id = 'star' + this.next_id();
    if(!opts.size) opts.size = Omega.Constraint.gen('star', 'size');
    if(!opts.type) opts.type = Omega.Constraint.gen('star', 'type');

    if(!opts.location){
      var loc_opts = {x: 0, y: 0, z: 0, movement_strategy:
                     {json_class : 'Motel::MovementStrategies::Stopped'}};
      opts.location = new Omega.Location(loc_opts);
    }

    return new Omega.Star(opts);
  },

  /// emits a specified command via the cmd tracker
  command : function(){
    var args = Array.prototype.slice.call(arguments);
    var cmd_tracker = args.shift();
    var evnt = args.shift();

    cmd_tracker._msg_received(evnt, args)
  },

  Commands : {
    changed_strategy : function(cmd_tracker, loc){
      Omega.Gen.command(cmd_tracker, 'motel::changed_strategy', loc);
    },

    attacked : function(cmd_tracker, attacker, defender){
      Omega.Gen.command(cmd_tracker, 'manufactured::event_occurred',
                        'attacked', attacker, defender);
    },

    attacked_stop : function(cmd_tracker, attacker, defender){
      Omega.Gen.command(cmd_tracker, 'manufactured::event_occurred',
                        'attacked_stop', attacker, defender);
    },

    defended : function(cmd_tracker, defender, attacker){
      Omega.Gen.command(cmd_tracker, 'manufactured::event_occurred',
                        'defended', defender, attacker);
    },

    defended_stop : function(cmd_tracker, defender, attacker){
      Omega.Gen.command(cmd_tracker, 'manufactured::event_occurred',
                        'defended_stop', defender, attacker);
    },

    destroyed_by : function(cmd_tracker, defender, attacker){
      Omega.Gen.command(cmd_tracker, 'manufactured::event_occurred',
                        'destroyed_by', defender, attacker);
    },

    resource_collected : function(cmd_tracker, ship, resource, quantity){
      Omega.Gen.command(cmd_tracker, 'manufactured::event_occurred',
                        'resource_collected', ship, resource, quantity);
    },

    mining_stopped : function(cmd_tracker, ship, resource, reason){
      Omega.Gen.command(cmd_tracker, 'manufactured::event_occurred',
                        'mining_stopped', ship, resource, reason);
    }
  }
};
