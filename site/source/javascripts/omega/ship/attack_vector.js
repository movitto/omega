/* Omega Ship Attack Vector Gfx
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

/// TODO use ShaderParticleEmitter for this

Omega.ShipAttackVector = function(config, event_cb){
  if(config && event_cb)
    this.vector = this.init_gfx(config, event_cb);
};

Omega.ShipAttackVector.prototype = {
  clone : function(){
    var avector = new Omega.ShipAttackVector();
    avector.vector = this.vector.clone();
    return avector;
  },

  init_gfx : function(config, event_cb){
    var num_vertices     = 20;
    var particle_texture = Omega.load_ship_particles(config, event_cb)
    var attack_material  =
      new THREE.ParticleBasicMaterial({
        color    : 0xFF0000,
        size     : 20,
        map      : particle_texture,
        blending : THREE.AdditiveBlending,
        transparent: true
      });

    var attack_geo = new THREE.Geometry();
    for(var v = 0; v < num_vertices; v++)
      attack_geo.vertices.push(new THREE.Vector3(0,0,0));

    var attack_vector =
      new THREE.ParticleSystem(attack_geo, attack_material);
    attack_vector.sortParticles = true;

    return attack_vector;
  },

  update : function(){
    var loc = this.omega_entity.location;
    this.vector.position.set(loc.x, loc.y, loc.z);
  },

  set_scale : function(x,y,z){
    this.scalex = x; this.scaley = y; this.scalez = z;
  },

  scale_vector : function(){
    return new THREE.Vector3(this.scalex, this.scaley, this.scalez);
  },

  set_target : function(target){
    var entity = this.omega_entity;
    var loc    = entity.location;

    /// update attack vector properties
    var dist = loc.distance_from(target.location.x,
                                 target.location.y,
                                 target.location.z);

    /// should be signed to preserve direction
    var dx = target.location.x - loc.x;
    var dy = target.location.y - loc.y;
    var dz = target.location.z - loc.z;

    /// 5 unit particle + 55 unit spacer
    this.set_scale(60 / dist * dx,
                   60 / dist * dy,
                   60 / dist * dz);
  },

  run_effects : function(){
    var entity = this.omega_entity;
    var loc    = entity.location;

    for(var p = 0; p < this.vector.geometry.vertices.length; p++){
      var vertex = this.vector.geometry.vertices[p];

      /// 1/750 chance to start moving vertex
      /// increase chance to generate more moving vertices per sec
      if(Math.floor( Math.random() * 750 ) == 1)
        vertex.moving = true;

      if(vertex.moving) vertex.add(this.scale_vector());

      var dx = loc.x + vertex.x;
      var dy = loc.y + vertex.y;
      var dz = loc.z + vertex.z;
      var vertex_dist = entity.attacking.location.distance_from(dx, dy, dz);

      /// FIXME if attack_vector.scale is large enough so that each
      /// hop exceeds 60, this check may be missed alltogether &
      /// particle will contiue to infinity
      if(vertex_dist < 60){
        vertex.set(0,0,0);
        vertex.moving = false;
      }
    }

    this.vector.geometry.verticesNeedUpdate = true;
  }
};
