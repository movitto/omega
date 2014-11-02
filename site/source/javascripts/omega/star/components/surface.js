/* Omega Star Surface
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.StarSurface = function(args){
  if(!args) args = {};
  var color    = args['color'];
  var mesh     = args['mesh'];
  var event_cb = args['event_cb'];

  if(color) this.init_gfx(color, event_cb);
  else if(mesh) this.tmesh = mesh;
  this.tmesh.omega_obj = this;
};

Omega.StarSurface.prototype = {
  size      : 15000,
  segments  : 32,
  rings     : 32,

  clone : function(){
    return new Omega.StarSurface({mesh : this.tmesh.clone()});
  },

  _texture : function(event_cb){
    var texture_path = Omega.Config.url_prefix + Omega.Config.images_path +
                       Omega.Config.resources.star.surface_texture;
    var texture = THREE.ImageUtils.loadTexture(texture_path, {}, event_cb);
    texture.omega_id = 'star.surface.material';
    return texture;
  },

  _uniforms : function(texture, color){
    return {texture : { type: "t",  value : texture },
            color   : { type: "v4", value : color   },
            time    : { type: "f",  value : 0.0     }};
  },

  _material : function(uniforms){
    var vsh = Omega.get_shader('vertexShaderSurface');
    var fsh = Omega.get_shader('fragmentShaderSurface');
    return new THREE.ShaderMaterial({uniforms       : uniforms,
                                     vertexShader   : vsh,
                                     fragmentShader : fsh});
  },

  _geometry : function(){
    return new THREE.SphereGeometry(this.size, this.segments, this.rings);
  },

  init_gfx : function(color, event_cb){
    var geo = this._geometry();
    var tex = this._texture(event_cb)
    var mat = this._material(this._uniforms(tex, color));

    this.tmesh = new THREE.Mesh(geo, mat);
  }
};
