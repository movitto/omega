/* Omega JS Canvas Stardust Scene Component
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/particles"

Omega.UI.CanvasStarDust = function(parameters){
  this.components = [];
  $.extend(this, parameters);
};

Omega.UI.CanvasStarDust.prototype = {
  id : 'star_dust',
  size : 1000,

  _particle_group : function(event_cb){
    return new SPE.Group({
      texture  : Omega.UI.Particles.load('star_dust', event_cb),
      maxAge   : 2,
      blending : THREE.AdditiveBlending
    });
  },

  _particle_emitter : function(){
    return new SPE.Emitter({
      positionSpread : new THREE.Vector3(this.size, this.size, this.size),
      acceleration   : new THREE.Vector3(0, 0, 0),
      velocity       : new THREE.Vector3(0, 0, 0),
      colorStart     : new THREE.Color('white'),
      colorEnd       : new THREE.Color('white'),
      sizeStart      :    7,
      sizeEnd        :   10,
      opacityStart   :    0,
      opacityMiddle  :    1,
      opacityEnd     :    0,
      particleCount  : 1000 });
  },

  load_gfx : function(event_cb){
    if(typeof(Omega.UI.CanvasStarDust.gfx) !== 'undefined') return;

    this.particles = this._particle_group(event_cb);
    var emitter = this._particle_emitter();
    this.particles.addEmitter(emitter);
  },

  init_gfx : function(event_cb){
    if(this.components.length > 0) return;
    this.load_gfx(event_cb);

    /// just reference it, assuming we're only going to need the one instance
    this.components.push(this.particles.mesh);

    this.clock = new THREE.Clock();
  },

  scene_components : function(){
    return this.components;
  },

  has_effects : function(){ return true; },

  run_effects : function(){
    this.particles.tick(this.clock.getDelta());
  },

  scale_position : function(){},
  scale_size : function(){}
};

THREE.EventDispatcher.prototype.apply( Omega.UI.CanvasStarDust.prototype );
