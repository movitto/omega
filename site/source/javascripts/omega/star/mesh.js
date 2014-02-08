/* Omega Star Mesh
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.StarMesh = function(config, event_cb){
  if(config && event_cb)
    this.tmesh = this.init_gfx(config, event_cb);
  //this.tmesh.omega_obj = this;
};

Omega.StarMesh.prototype = {
  clone : function(){
    var smesh   = new Omega.StarMesh();
    smesh.tmesh = this.tmesh.clone(); 
    return smesh;
  },

  init_gfx : function(config, event_cb){
    var mesh_geo     = Omega.StarGeometry.load();
    var texture_path = config.url_prefix + config.images_path +
                       config.resources.star.texture;
    var texture      = THREE.ImageUtils.loadTexture(texture_path, {}, event_cb);
    var material     = new THREE.MeshBasicMaterial({map : texture});

    var mesh = new THREE.Mesh(mesh_geo, material);
    return mesh;
  }
};

Omega.StarGeometry = {
  load : function(){
    /// each star instance should override radius in the geometry instance
    var radius = 750, segments = 32, rings = 32;
    return new THREE.SphereGeometry(radius, segments, rings);
  }
}
