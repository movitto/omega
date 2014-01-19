/* Omega JS Canvas Stardust Scene Component
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.UI.CanvasStarDust = function(parameters){
  this.components = [];
  this.shader_components = [];
  $.extend(this, parameters);
};

Omega.UI.CanvasStarDust.prototype = {
  id : 'star_dust',
  size : 10000,

  load_gfx : function(config, event_cb){
    if(typeof(Omega.UI.CanvasStarDust.gfx) !== 'undefined') return;

    var particle_path = config.url_prefix + config.images_path + "/smokeparticle.png";
    var particleGroup = new ShaderParticleGroup({
      texture: THREE.ImageUtils.loadTexture(particle_path),
      maxAge: 2,
      blending: THREE.AdditiveBlending
    });

    var particleEmitter =
      new ShaderParticleEmitter({
        positionSpread: new THREE.Vector3(this.size, this.size, this.size),
        acceleration:   new THREE.Vector3(0, 0, 10),
        velocity:       new THREE.Vector3(0, 0, 10),
        colorStart:     new THREE.Color('white'),
        colorEnd:       new THREE.Color('white'),
        sizeStart:          50,
        sizeEnd:           150,
        opacityStart:        0,
        opacityMiddle:       1,
        opacityEnd:          0,
        particlesPerSecond: 50
    });

    // Add the emitter to the group.
    particleGroup.addEmitter( particleEmitter );

    Omega.UI.CanvasStarDust.gfx = {
      group   : particleGroup,
      emitter : particleEmitter
    };
  },

  init_gfx : function(config, event_cb){
    if(this.components.length > 0) return;
    this.load_gfx(config, event_cb);

    /// just reference it, assuming we're only going to need the one instance
    this.components.push(Omega.UI.CanvasStarDust.gfx.group.mesh);

    this.clock = new THREE.Clock();
  },

  run_effects : function(){
    Omega.UI.CanvasStarDust.gfx.group.tick(this.clock.getDelta());
  }
};

THREE.EventDispatcher.prototype.apply( Omega.UI.CanvasStarDust.prototype );
