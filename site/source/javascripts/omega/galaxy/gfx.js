/* Omega Galaxy Graphics
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

///////////////////////////////////////// high level operations

Omega.load_galaxy_gfx = function(config, event_cb){
  var gfx = {};
  Omega.Galaxy.gfx = gfx;

  gfx.density_wave = new Omega.GalaxyDensityWave(config, event_cb);
};

Omega.init_galaxy_gfx = function(config, galaxy, event_cb){
  galaxy.density_wave = Omega.Galaxy.gfx.density_wave;//.clone(); // TODO
  galaxy.density_wave.mesh.rotation.set(1.57,0,0);

  galaxy.components = [galaxy.density_wave.mesh];
  galaxy.clock = new THREE.Clock();
};

///////////////////////////////////////// initializers

Omega.load_galaxy_particles = function(config, event_cb){
  var particle_path = config.url_prefix + config.images_path + "/smokeparticle.png";
  return THREE.ImageUtils.loadTexture(particle_path, {}, event_cb);
};

Omega.GalaxyDensityWave = function(config, event_cb){
  var ptexture = Omega.load_galaxy_particles(config, event_cb);
  var particleGroup = new ShaderParticleGroup({
    texture: ptexture,
    maxAge: 2,
    fadeFactor :  20.0,
    blending: THREE.AdditiveBlending
  });

  var particleEmitter =
    new ShaderParticleEmitter({
      type           : 'spiral',
      spiralSkew     : 1.4,
      spiralRotation : 1.4,
      position     : new THREE.Vector3(0, 0, 0),
      radius       : 1000,
      radiusSpread : 2000,
      radiusScale  :  150,
      speed        :  50,
      colorStart   : new THREE.Color('yellow'),
      colorEnd     : new THREE.Color('white'),
      size         : 1000,
      //sizeSpread : 1,
      sizeEnd      : 100,
      opacityStart : 1,
      opacityEnd   : 0,
      particlesPerSecond: 5000,
    });

  // Add the emitter to the group.
  particleGroup.addEmitter( particleEmitter );

  $.extend(this, particleGroup);
}

///////////////////////////////////////// other

/// Also gets mixed into the Galaxy Module
Omega.GalaxyEffectRunner = {
  run_effects : function(){
    this.density_wave.tick(this.clock.getDelta());
  }
};
