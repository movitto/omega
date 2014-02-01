/* Omega Ship Trails Gfx
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

/// TODO use particle emitter for this

Omega.ShipTrails = function(config, type, event_cb){
  /// omega trails
  if(config && type && event_cb)
    this.otrails = this.init_trails(config, type, event_cb);
  else
    this.otrails = [];
};

Omega.ShipTrails.prototype = {
  trail_props : {
    plane : 3, lifespan : 100
  },

  init_trails : function(config, type, event_cb){
    var trails = config.resources.ships[type].trails;
    var otrails = [];
    if(trails){
      var trail_props      = this.trail_props;
      var particle_texture = Omega.load_ship_particles(config, event_cb)
  
      var trail_material = new THREE.ParticleBasicMaterial({
        color: 0xFFFFFF, size: 20, map: particle_texture,
        blending: THREE.AdditiveBlending, transparent: true });
  
      for(var l = 0; l < trails.length; l++){
        var trail = trails[l];
        var geo   = new THREE.Geometry();
  
        var plane    = trail_props.plane;
        var lifespan = trail_props.lifespan;
        for(var i = 0; i < plane; ++i){
          for(var j = 0; j < plane; ++j){
            var pv = new THREE.Vector3(i, j, 0);
            pv.velocity = Math.random() / 3;
            pv.lifespan = Math.random() * lifespan;
            if(i >= plane / 4 && i <= 3 * plane / 4 &&
               j >= plane / 4 && j <= 3 * plane / 4 ){
                 pv.lifespan *= 2;
            }
            pv.olifespan = pv.lifespan;
            geo.vertices.push(pv)
          }
        }
  
        var otrail = new THREE.ParticleSystem(geo, trail_material);
        otrail.position.set(trail[0], trail[1], trail[2]);
        otrail.base_position = trail;
        otrail.sortParticles = true;
        otrails.push(otrail);
      }
    }
    return otrails;
  },

  clone : function(){
    var strails = new Omega.ShipTrails();
    for(var t = 0; t < this.otrails.length; t++){
      var trail = this.otrails[t].clone();
      trail.base_position = this.otrails[t].base_position;
      strails.otrails.push(trail);
    }
    return strails;
  },

  update : function(){
    var entity = this.omega_entity;
    var loc    = entity.location;

    /// update trails position and orientation
    for(var t = 0; t < this.otrails.length; t++){
      var trail = this.otrails[t];

      var bp  = trail.base_position;
      var bpv = new THREE.Vector3(bp[0], bp[1], bp[2]);

      trail.position.set(loc.x, loc.y, loc.z);
      trail.position.add(bpv);

      if(entity.mesh) Omega.set_rotation(trail, entity.mesh.base_rotation);

      Omega.set_rotation(trail, loc.rotation_matrix());
      Omega.temp_translate(trail, loc, function(ttrail){
        Omega.rotate_position(ttrail, loc.rotation_matrix());
      });
    }
  },

  run_effects : function(){
    var trail_props      = this.trail_props;

    // animate trails
    var plane    = trail_props.plane,
        lifespan = trail_props.lifespan;
    for(var t = 0; t < this.otrails.length; t++){
      var trail = this.otrails[t];
      var p = plane*plane;
      while(p--){
        var pv = trail.geometry.vertices[p]
        pv.z -= pv.velocity;
        pv.lifespan -= 1;
        if(pv.lifespan < 0){
          pv.z = 0;
          pv.lifespan = pv.olifespan;
        }
      }
      trail.geometry.verticesNeedUpdate = true;
    }
  }
};
