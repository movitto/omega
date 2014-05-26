/* Omega Star Mesh
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega/star/geometry"

Omega.StarMesh = function(args){
  if(!args) args = {};
  var config   = args['config'];
  var event_cb = args['event_cb'];

  if(config) this.init_gfx(config, event_cb);
};

Omega.StarMesh.prototype = {
  clone : function(){
    var smesh = new Omega.StarMesh();
    smesh.cp_gfx(this);
    return smesh;
  },

  _texture : function(config, event_cb){
    var texture_path = config.url_prefix + config.images_path +
                       config.resources.star.texture;
    return THREE.ImageUtils.loadTexture(texture_path, {}, event_cb);
  },

  _material : function(texture){
    return new THREE.MeshBasicMaterial({map : texture});
  },

  init_gfx : function(config, event_cb){
    var geo = Omega.StarGeometry.load();
    var mat = this._material(this._texture(config, event_cb));

    this.tmesh = new THREE.Mesh(geo, mat);
    this.tmesh.omega_obj = this;
  },

  cp_gfx : function(from){
    this.tmesh = from.tmesh.clone();
    this.tmesh.omega_obj = this;
  }
};
