/* Omega Solar System Plane
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.SolarSystemPlane = function(config, event_cb){
  if(config && event_cb) this.tmesh = this.init_gfx(config, event_cb);
};

Omega.SolarSystemPlane.prototype = {
  clone : function(){
    var plane   = new Omega.SolarSystemPlane();
    plane.tmesh = this.tmesh.clone();
    return plane;
  },

  update : function(){
    var entity = this.omega_entity;
    var loc    = entity.location;
    this.tmesh.position.set(loc.x, loc.y, loc.z);
  },

  _material : function(config, event_cb){
    var texture_path =
      config.url_prefix + config.images_path +
      config.resources.solar_system.material;

    var texture  =
      THREE.ImageUtils.loadTexture(texture_path, {}, event_cb);


    var material =
      new THREE.MeshBasicMaterial({map: texture,
                                   alphaTest: 0.5});
    material.side = THREE.DoubleSide;

    return material;
  },

  _geometry : function(){
    return new THREE.PlaneGeometry(100, 100);
  },

  init_gfx : function(config, event_cb){
    var mesh = new THREE.Mesh(this._geometry(),
                               this._material(config, event_cb));
    mesh.rotation.x = 1.57;
    return mesh;
  }
};
