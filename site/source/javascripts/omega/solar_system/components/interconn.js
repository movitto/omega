/* Omega Solar System Interconnections
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/particles"

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

  _texture : function(event_cb){
    if(this.__texture) return this.__texture;
    return Omega.UI.Particles.load('solar_system', event_cb);
  },

  _particle_group : function(){
    return new SPE.Group({
      texture  : this._texture(),
      blending : THREE.AdditiveBlending,
      maxAge   : this.age
    });
  },

  _particle_emitter : function(endpoint){
    var entity = this.omega_entity;
    var loc    = entity.scene_location();


    /// set emitter velocity / particle properties
    var eloc = endpoint.scene_location();
    var distance = loc.distance_from(eloc);
    var speed = distance / this.age;

    var dx = (eloc.x - loc.x) / distance * speed;
    var dy = (eloc.y - loc.y) / distance * speed;
    var dz = (eloc.z - loc.z) / distance * speed;
    var velocity = new THREE.Vector3(dx, dy, dz);

    var emitter = new SPE.Emitter({
      velocity      : velocity,
      colorStart    : new THREE.Color(0xFF0000),
      colorEnd      : new THREE.Color(0xFF0000),
      sizeStart     :  250,
      sizeEnd       :  250,
      opacityStart  :    1,
      opacityEnd    :    1,
      particleCount :    1.0
    });

    return emitter;
  },

  load_gfx : function(event_cb){
    this._texture(event_cb);
  },

  init_gfx : function(){
    this.particles = this._particle_group();
    this.clock = new THREE.Clock();
  },

  component : function(){
    return this.particles.mesh;
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
  }
};
