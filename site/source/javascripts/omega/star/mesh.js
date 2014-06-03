/* Omega Star Mesh
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

/// TODO just load one 'base' star texture / tint it to star colors
/// TODO dynamic texture / mesh (eg an 'active' star)

//= require "omega/star/geometry"

Omega.StarMesh = function(args){
  if(!args) args = {};
  var type     = args['type'];
  var config   = args['config'];
  var event_cb = args['event_cb'];

  if(config && type) this.init_gfx(type, config, event_cb);
};

Omega.StarMesh.prototype = {
  clone : function(){
    var smesh = new Omega.StarMesh();
    smesh.cp_gfx(this);
    return smesh;
  },

  _texture : function(type, config, event_cb){
    var texture_path = config.url_prefix + config.images_path +
                       config.resources.star.base_texture + type +
                       '.' + config.resources.star.extension;
    return THREE.ImageUtils.loadTexture(texture_path, {}, event_cb);
  },

  _material : function(texture){
    return new THREE.MeshBasicMaterial({map : texture});
  },

  init_gfx : function(type, config, event_cb){
    this.type = type;

    var geo = Omega.StarGeometry.load();
    var mat = this._material(this._texture(type, config, event_cb));

    this.tmesh = new THREE.Mesh(geo, mat);
    this.tmesh.omega_obj = this;
  },

  cp_gfx : function(from){
    this.tmesh = from.tmesh.clone();
    this.tmesh.omega_obj = this;
  }
};

Omega.StarMesh.for_types = function(args){
  var meshes = [];
  var types = Omega.Constraint._get(['star', 'type']);
  for(var t = 0; t < types.length; t++){
    var type = types[t];
    meshes.push(new Omega.StarMesh($.extend({type : type}, args)));
  }
  return meshes;
}

Omega.StarMesh.for_type = function(type, meshes){
  for(var m = 0; m < meshes.length; m++)
    if(meshes[m].type == type)
      return meshes[m];
  return null;
};
