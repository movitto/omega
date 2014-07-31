/* Omega Ship Particles
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.load_ship_particles = function(config, event_cb, particles_id){
  if(!particles_id) particles_id = 'default';
  if(typeof(Omega.Ship.particles)     === 'undefined') Omega.Ship.particles = {};
  if(typeof(Omega.Ship.particles[particles_id]) !== 'undefined')
    return Omega.Ship.particles[particles_id];

  var particle_path = config.url_prefix + config.images_path;
  switch(particles_id){
    case 'explosion':
    case 'destruction':
      particle_path += '/smokeparticle.png';
      break;
    case 'smoke':
      particle_path += '/cloudparticle.png';
      break;
    case 'artillery':
    case 'trails':
    case 'missile':
      particle_path += '/bullet-particle.png';
      break;
    default:
      particle_path += '/particle.png';
  }

  Omega.Ship.particles[particles_id] =
    THREE.ImageUtils.loadTexture(particle_path, {}, event_cb);
  return Omega.Ship.particles[particles_id];
};

