/* Omega Star Mesh
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

/// TODO just load one 'base' star texture / tint it to star colors
/// TODO dynamic texture / mesh (eg an 'active' star)

//= require "omega/star/geometry"

Omega.StarMesh = function(args){
  if(!args) args = {};
  var type     = args['type'];
  var event_cb = args['event_cb'];

  if(type) this.init_gfx(type, event_cb);
};

Omega.StarMesh.prototype = {
  clone : function(){
    var smesh = new Omega.StarMesh();
    smesh.cp_gfx(this);
    return smesh;
  },

  _texture : function(type, event_cb){
    var texture_path = Omega.Config.url_prefix + Omega.Config.images_path +
                       Omega.Config.resources.star.base_texture + type +
                       '.' + Omega.Config.resources.star.extension;
    return THREE.ImageUtils.loadTexture(texture_path, {}, event_cb);
  },

  _material : function(texture){
    return new THREE.MeshBasicMaterial({map : texture});
  },

  init_gfx : function(type, event_cb){
    this.type = type;

    var geo = Omega.StarGeometry.load();
    var mat = this._material(this._texture(type, event_cb));

    this.tmesh = new THREE.Mesh(geo, mat);
    this.tmesh.omega_obj = this;
  },

  cp_gfx : function(from){
    this.tmesh = from.tmesh.clone();
    this.tmesh.omega_obj = this;
  }
};
