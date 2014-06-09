/* Omega Galaxy Particles
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.load_galaxy_particles = function(config, event_cb, particles_id){
  if(typeof(Omega.Galaxy.particles) === 'undefined') Omega.Galaxy.particles = {};
  if(typeof(Omega.Galaxy.particles[particles_id]) !== 'undefined')
    return Omega.Galaxy.particles[particles_id];

  var particle_path = config.url_prefix + config.images_path;
  switch(particles_id){
    case 'clouds':
      particle_path += '/smokeparticle.png';
      break;
    case 'stars':
    default:
      particle_path += "/star-particle.png";
  }

  Omega.Galaxy.particles[particles_id] =
    THREE.ImageUtils.loadTexture(particle_path, {}, event_cb);
  return Omega.Galaxy.particles[particles_id];
};
