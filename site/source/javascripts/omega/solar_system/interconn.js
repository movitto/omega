/* Omega Solar System Interconnections
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.SolarSystemInterconns = function(){
  this.endpoints = [];
};

Omega.SolarSystemInterconns.prototype = {
  age : 5.0,

  _line_material : function(){
    if(this.__line_material) return this.__line_material;
    this.__line_material = new THREE.LineBasicMaterial({ color: 0xF80000 });
    return this.__line_material;
  },

  _line_geo : function(endpoint){
    var loc  = this.omega_entity.scene_location();
    var eloc = endpoint.scene_location();
    var diff = eloc.sub(loc.coordinates());

    var geometry = new THREE.Geometry();
    geometry.vertices.push(new THREE.Vector3(0,0,0));
    geometry.vertices.push(new THREE.Vector3(diff[0], diff[1], diff[2]));
    return geometry;
  },

  _line : function(endpoint){
    return new THREE.Line(this._line_geo(endpoint), this._line_material());
  },

  _particle_group : function(config, event_cb){
    var path    = config.url_prefix + config.images_path + '/particle.png';
    var texture = THREE.ImageUtils.loadTexture(path, {}, event_cb);

    return new SPE.Group({
      texture:    texture,
      blending:   THREE.AdditiveBlending,
      maxAge:     this.age
    });
  },

  _particle_emitter : function(endpoint){
    var entity = this.omega_entity;
    var loc    = entity.scene_location();

    /// set emitter velocity / particle properties
    var eloc = endpoint.scene_location();
    var dx = (eloc.x - loc.x) / this.age;
    var dy = (eloc.y - loc.y) / this.age;
    var dz = (eloc.z - loc.z) / this.age;
    var velocity = new THREE.Vector3(dx, dy, dz);

    var emitter = new SPE.Emitter({
      position           : loc.vector(),
      velocity           : velocity,
      colorStart         : new THREE.Color(0xFF0000),
      colorEnd           : new THREE.Color(0xFF0000),
      sizeStart          :  250,
      sizeEnd            :  250,
      opacityStart       :    1,
      opacityEnd         :    1,
      particleCount      :    1.0
    });

    return emitter;
  },

  init_gfx : function(config, event_cb){
    this.particles = this._particle_group(config, event_cb);
    this.clock = new THREE.Clock();
  },

  components : function(){
    return [this.particles.mesh];
  },

  _queue : function(endpoint){
    if(!this._queued) this._queued= [];
    this._queued.push(endpoint);
  },

  unqueue : function(){
    if(!this._queued) return;

    for(var i = 0; i < this._queued.length; i++)
      this.add(this._queued[i]);
    this._queued = null;
  },

  add : function(endpoint){
    var entity = this.omega_entity;

    if(!entity.gfx_initialized()){
      this._queue(endpoint);
      return;
    }

    this.endpoints.push(endpoint);
    this.particles.addEmitter(this._particle_emitter(endpoint));
    entity.position_tracker().add(this._line(endpoint));
  },

  run_effects : function(){
    this.particles.tick(this.clock.getDelta());
  },

  update : function(){
    /// TODO refresh emitter from entity & endpoint scene locations
  }
};
