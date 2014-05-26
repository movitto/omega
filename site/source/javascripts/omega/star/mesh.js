/* Omega Star Mesh
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega/star/geometry"

Omega.StarMesh = function(args){
  if(!args) args = {};
  var type     = args['type'];
  var config   = args['config'];
  var event_cb = args['event_cb'];

  if(config && type) this.init_gfx(type, config, event_cb);
};

Omega.StarMesh.prototype = {
  /// TODO support more granular / 'blended' types
  types : ['0000FF', '00FF00', 'FF0000'],

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
  for(var t = 0; t < Omega.StarMesh.prototype.types.length; t++){
    var type = Omega.StarMesh.prototype.types[t];
    meshes.push(new Omega.StarMesh($.extend({type : type}, args)));
  }
  return meshes;
}

Omega.StarMesh.for_type = function(type, meshes){
  var rgb = parseInt(type, 16);
  var r = (rgb >> 16) & 255;
  var g = (rgb >> 8) & 255;
  var b = rgb & 255;

  var strongest = 'FF0000';
  if(g > r && g > b)
    strongest = '00FF00';
  else if(b > r && b > g)
    strongest = '0000FF';

  for(var m = 0; m < meshes.length; m++){
    if(meshes[m].type == strongest)
      return meshes[m];
  }

  return null;
};
