/* Omega Galaxy Density Wave
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega/galaxy/particles"

Omega.GalaxyDensityWave = function(args){
  if(!args) args = {};
  config   = args['config'];
  event_cb = args['event_cb'];

  this.type  = args['type'];
  this.angle = args['angle'] || 0;
  this.colorStart = args['colorStart'];
  this.colorEnd = args['colorEnd'];

  this.init_gfx(config, event_cb);
};

Omega.GalaxyDensityWave.prototype = {
  properties : {
    maxBuldge : 400,

    'stars' : {
      skew         :    1.6,
      max_radius   :  12500,
      min_radius   :    500,
      count        :   2500,
      max_size     :    275,
      min_size     :    250,
      opacity      :      1,
      max_velocity :  0.003
    },

    'clouds' : {
      skew         :    1.6,
      max_radius   :  12000,
      min_radius   :   1000,
      count        :   350,
      max_size     :   9000,
      min_size     :   5000,
      opacity      :    0.1,
      max_velocity :      0
    }
  },

  _skew : function(p){
    if(p > 0.7 || this.type == 'clouds')
      return this.properties[this.type].skew;
    return this.properties[this.type].skew / 2;
  },

  _radius : function(){
    var max = this.properties[this.type].max_radius;
    var min = this.properties[this.type].min_radius;
    var variance = max - min;
    return Math.random() * variance + min;
  },

  _radiusMax : function(){
    return this.properties[this.type].max_radius;
  },

  _count : function(){
    return this.properties[this.type].count;
  },

  _size : function(){
    var max = this.properties[this.type].max_size;
    var min = this.properties[this.type].min_size;
    var variance = max - min;
    return Math.random() * variance + min;
  },

  _opacity : function(){
    return this.properties[this.type].opacity;
  },

  _color : function(){
    if(this.type == 'stars') return null;
    var start = Omega.convert.hex2rgb(this.colorStart);
    var end   = Omega.convert.hex2rgb(this.colorEnd);
    var val = { r : start.r + Math.random() * (end.r - start.r),
                g : start.g + Math.random() * (end.g - start.g),
                b : start.b + Math.random() * (end.b - start.b) }
    return Omega.convert.rgb2hex(val);
  },

  _velocity : function(){
    return Math.random() * this.properties[this.type].max_velocity;
  },

  _height_for : function(pos, p){
    var neg = (Math.floor(Math.random() * 2) == 0) ? 1 : -1;
    var max = Math.log(1.25/p) * this.properties.maxBuldge;
    return Math.random() * max * neg;
  },

  _position : function(theta, radius, current){
    var p = radius / this._radiusMax();
    var angle = 6.2832 * p;
    var sa = Math.sin(angle);
    var ca = Math.cos(angle);

    var ct  = Math.cos(theta);
    var sst = Math.sin(theta) * this._skew(p);

    var vec = new THREE.Vector3();
    vec.set(
        ca * ct - sa * sst,
        0,
        sa * ct + ca * sst
    ).multiplyScalar( radius );

    var has_current = typeof(current) !== "undefined";
    if(has_current) vec.y = current.y;
    else vec.y = this._height_for(vec, p);

    return vec;
  },

  _material : function(config, event_cb){
    return new THREE.ParticleBasicMaterial({
      size        : this._size(),
      map         : Omega.load_galaxy_particles(config, event_cb, this.type),
      depthWrite  : false,
      transparent : true,
      opacity     : this._opacity(),
      vertexColors: true
    });
  },

  _geometry : function(){
    var particles = new THREE.Geometry();
    particles.colors = [];

    for(var c = 0; c < this._count(); c++){
      var theta         = (c % 360) * Math.PI / 180;
      var radius        = this._radius();
      var particle      = this._position(theta, radius);
      particle.theta    = theta;
      particle.radius   = radius;
      particle.velocity = this._velocity();
      particles.vertices.push(particle);

      particles.colors.push(new THREE.Color(this._color()));
    }

    return particles;
  },

  init_gfx : function(config, event_cb){
    this.particles = new THREE.ParticleSystem(this._geometry(),
                                              this._material(config, event_cb));
  },

  /// rotate mesh
  _rotate : function(){
    this.angle += 0.001;
    if(this.angle >= 2*Math.PI) this.angle = 0;
    var axis = new THREE.Vector3( 0, 1, 0 );
    var matrix = new THREE.Matrix4().makeRotationAxis( axis, this.angle);
    this.particles.rotation.setFromRotationMatrix(matrix);
  },

  /// rotate particles
  /// TODO offload alot these individual particle position/movement calculations
  /// into custom shader
  _rotate_particles : function(){
    for(var c = 0; c < this._count(); c++){
      var particle = this.particles.geometry.vertices[c];
      particle.theta -= particle.velocity;
      if(particle.theta >= 2*Math.PI) particle.theta = 0;
      var pos = this._position(particle.theta, particle.radius, particle);
      particle.set(pos.x, pos.y, pos.z);
    }

    this.particles.geometry.verticesNeedUpdate = true;
  },

  run_effects : function(){
    if(!this.particles) return;
    this._rotate();
    this._rotate_particles();
  },

  components : function(){
    return [this.particles];
  }
};
