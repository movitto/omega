/* Omega Solar System Interconnections
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

/// TODO use particle engine for particles

Omega.SolarSystemInterconnMaterial = function(){
  this.material = this.init_gfx();
};

Omega.SolarSystemInterconnMaterial.prototype = {
  init_gfx : function(){
    return new THREE.LineBasicMaterial({ color: 0xF80000 });
  }
}

Omega.SolarSystemInterconnParticleMaterial = function(config, event_cb){
  this.material = this.init_gfx(config, event_cb);
};

Omega.SolarSystemInterconnParticleMaterial.prototype = {
  init_gfx : function(config, event_cb){
    var texture_path =
      config.url_prefix + config.images_path + '/particle.png';

    var texture =
      THREE.ImageUtils.loadTexture(texture_path, {}, event_cb);

    var mat = new THREE.ParticleBasicMaterial({
      color:       0xFF0000,
      size:        50,
      transparent: true,
      depthWrite:  false,
      map:         texture,
      blending:    THREE.AdditiveBlending
    });

    return mat;
  }
};

Omega.SolarSystemInterconnHelpers = {
  _interconn_geo : function(endpoint){
    var geometry = new THREE.Geometry();
    geometry.vertices.push(new THREE.Vector3(this.location.x,
                                             this.location.y,
                                             this.location.z));
    geometry.vertices.push(new THREE.Vector3(endpoint.location.x,
                                             endpoint.location.y,
                                             endpoint.location.z));
    return geometry;
  },

  _interconn_particle_geo : function(){
    var particle_geo = new THREE.Geometry();
    particle_geo.vertices.push(new THREE.Vector3(0,0,0));
    return particle_geo;
  },

  _queue_interconn : function(endpoint){
    if(!this._queued_interconns)
      this._queued_interconns = [];
    this._queued_interconns.push(endpoint);
  },

  unqueue_interconns : function(){
    if(!this._queued_interconns) return;

    for(var i = 0; i < this._queued_interconns.length; i++)
      this.add_interconn(this._queued_interconns[i]);
    this._queued_interconns = null;
  },

  add_interconn: function(endpoint){
    if(this.components.length == 0){
      this._queue_interconn(endpoint);
      return;
    }

    var material = Omega.SolarSystem.gfx.interconn_material.material;
    var geometry = this._interconn_geo(endpoint);
    var line     = new THREE.Line(geometry, material);
    this.components.push(line);

    var particle_geo = this._interconn_particle_geo();
    var particle_mat =
      Omega.SolarSystem.gfx.interconn_particle_material.material;
    var particle_system = new THREE.ParticleSystem(particle_geo, particle_mat);
              
    var loc = this.location;
    particle_system.position.set(loc.x, loc.y, loc.z);

    var eloc = endpoint.location;
    var d  = loc.distance_from(eloc);
    var dx = (eloc.x - loc.x) / d;
    var dy = (eloc.y - loc.y) / d;
    var dz = (eloc.z - loc.z) / d;

    particle_system.sortParticles = true;
    particle_system.ticker        = 0;
    particle_system.ticks         = d / 50;
    particle_system.dx            = dx;
    particle_system.dy            = dy;
    particle_system.dz            = dz;

    this.components.push(particle_system);
    this.interconnections.push(particle_system);
  },

  _interconn_effects : function(){
    for(var i = 0; i < this.interconnections.length; i++){
      var interconn = this.interconnections[i];
      var v         = interconn.geometry.vertices[0];

      v.set(interconn.ticker * interconn.dx * 50,
            interconn.ticker * interconn.dy * 50,
            interconn.ticker * interconn.dz * 50)

      interconn.ticker += 1;
      if(interconn.ticker >= interconn.ticks)
        interconn.ticker = 0;
      interconn.geometry.verticesNeedUpdate = true;
    }
  }
};
