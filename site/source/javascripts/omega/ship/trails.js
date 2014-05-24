/* Omega Ship Trails Gfx
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.ShipTrails = function(args){
  if(!args) args = {};
  var config   = args['config'];
  var type     = args['type'];
  var event_cb = args['event_cb'];

  if(config && type)
    this.init_particles(config, type, event_cb);
  else
    this.disable_updates();
};

Omega.ShipTrails.prototype = {
  particles_per_second :   200,
  plane                :     7,
  lifespan             :   0.3,
  particle_speed       :     1,

  _particle_velocity : function(){
    if(this.__particle_velocity) return this.__particle_velocity;
    this.__particle_velocity = new THREE.Vector3(0, 0, -this.particle_speed);
    return this.__particle_velocity;
  },

  _particle_group : function(config, event_cb){
    return new SPE.Group({
      texture:    Omega.load_ship_particles(config, event_cb),
      maxAge:     this.lifespan,
      blending:   THREE.AdditiveBlending
    });
  },

  _particle_emitter : function(){
    return new SPE.Emitter({
      positionSpread     : new THREE.Vector3(this.plane, this.plane, 0),
      colorStart         : new THREE.Color('red'),
      colorEnd           : new THREE.Color('yellow'),
      sizeStart          :   20,
      sizeEnd            :   10,
      opacityStart       :    1,
      opacityEnd         :    0,
      velocity           : this._particle_velocity(),
      particlesPerSecond : this.particles_per_second,
      alive              :    0,
    });
  },

  init_particles : function(config, type, event_cb){
    this.config_trails = config.resources.ships[type].trails;
    if(!this.config_trails){
      this.disable_updates();
      return;
    }

    this.clock     = new THREE.Clock();
    this.particles = this._particle_group(config, event_cb);

    for(var t = 0; t < this.config_trails.length; t++){
      /// replace config array w/ vector
      var config_trail = this.config_trails[t];
      if(config_trail.constructor != THREE.Vector3)
        this.config_trails[t] =
          new THREE.Vector3(config_trail[0], config_trail[1], config_trail[2]);

      /// create new emitter add to group
      var emitter = this._particle_emitter();
      this.particles.addEmitter(emitter);
    }
  },

  clone : function(config, type, event_cb){
    return new Omega.ShipTrails({config: config,
                                 type: type,
                                 event_cb: event_cb});
  },

  _update_emitter : function(e){
    var entity        = this.omega_entity;
    var loc           = entity.scene_location();
    var config_trail  = this.config_trails[e];
    var emitter       = this.particles.emitters[e];

    /// keep emitter position in sync w/ location
    emitter.position.set(loc.x, loc.y, loc.z);
    emitter.position.add(config_trail);
    Omega.temp_translate(emitter, loc, function(temitter){
      Omega.rotate_position(temitter, loc.rotation_matrix());
    });

    /// rotate emitter velocity to match location orientation
    emitter.velocity = this._particle_velocity();
    Omega.set_emitter_velocity(emitter, loc.rotation_matrix());
    emitter.velocity.multiplyScalar(this.particle_speed);
  },

  disable_updates : function(){
    this.update = this._disabled_update;
  },

  enable_updates : function(){
    this.update = this._enabled_update;
  },

  _disabled_update : function(){},

  _enabled_update : function(){
    for(var t = 0; t < this.config_trails.length; t++)
      this._update_emitter(t);
  },

  update_state : function(){
    var loc = this.omega_entity.location;
    var stopped   = loc.is_stopped();
    var follow    = loc.is_moving('follow');
    var on_target = !!(loc.movement_strategy) &&
                    loc.movement_strategy.on_target;
    var adjusting = !!(loc.movement_strategy) &&
                    loc.movement_strategy.adjusting_bearing;

    if(stopped || (follow && (on_target || adjusting)))
      this.disable();
    else
      this.enable();
  },

  enable : function(){
    if(!this.particles) return;
    this.enable_updates();
    for(var e = 0; e < this.particles.emitters.length; e++)
      this.particles.emitters[e].alive = true;
  },

  disable : function(){
    if(!this.particles) return;
    this.disable_updates();
    for(var e = 0; e < this.particles.emitters.length; e++){
      this.particles.emitters[e].alive = false;
      this.particles.emitters[e].reset();
    }
  },

  run_effects : function(){
    /// FIXME should implement enable/disable effects similar to updates above
    if(this.particles)
      this.particles.tick(this.clock.getDelta());
  }
};

Omega.ShipTrails.prototype.update = Omega.ShipTrails.prototype._disabled_update;
