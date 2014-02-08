/* Omega Galaxy Particles
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.load_galaxy_particles = function(config, event_cb){
  var particle_path =
    config.url_prefix + config.images_path +
    "/smokeparticle.png";

  var texture = 
    THREE.ImageUtils.loadTexture(particle_path, {}, event_cb);

  return texture;
};
