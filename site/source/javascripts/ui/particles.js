/* Omega JS Central Particle Operations
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.UI.Particles = {
  num  : 5,

  all : function(){
    return ['smokeparticle', 'cloudparticle', 'star-particle',
            'particle', 'bullet-particle'];
  },

  _load_texture : function(id, particle_texture, event_cb){
    var path = Omega.Config.url_prefix + Omega.Config.images_path +
               '/' + particle_texture + '.png';
    var texture = THREE.ImageUtils.loadTexture(path, {}, event_cb);
    texture.omega_id = 'particles.' + id;
    return texture;
  },

  load : function(id, event_cb){
    var particles = Omega.UI.Particles.particles = Omega.UI.Particles.particles || {};
    switch(id){
      case 'star_dust'        : return this._load_texture(id, 'smokeparticle',   event_cb);
      case 'galaxy.clouds'    : return this._load_texture(id, 'cloudparticle',   event_cb);
      case 'galaxy.stars'     : return this._load_texture(id, 'star-particle',   event_cb);
      case 'jump_gate'        : return this._load_texture(id, 'particle',        event_cb);
      case 'solar_system'     : return this._load_texture(id, 'particle',        event_cb);
      case 'ship.explosion'   :
      case 'ship.destruction' : return this._load_texture(id, 'smokeparticle',   event_cb);
      case 'ship.smoke'       : return this._load_texture(id, 'cloudparticle',   event_cb);
      case 'ship.trails'      :
      case 'ship.artillery'   :
      case 'ship.missile'     :
      case 'ship'             : return this._load_texture(id, 'particle',        event_cb);
    };
    return null;
  }
};
