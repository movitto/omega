/* Omega Star Halo
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.StarHalo = function(args){
  if(!args) args = {};
  var color    = args['color'];
  var mesh     = args['mesh'];
  var event_cb = args['event_cb'];

  if(color) this.init_gfx(color, event_cb);
  else if(mesh) this.tmesh = mesh;
  this.tmesh.omega_obj = this;
};

Omega.StarHalo.prototype = {
  size      : 1800,

  clone : function(){
    return new Omega.StarHalo({mesh : this.tmesh.clone()});
  },

  _texture : function(event_cb){
    var texture_path = Omega.Config.url_prefix + Omega.Config.images_path +
                       Omega.Config.resources.star.halo_texture;
    var texture = THREE.ImageUtils.loadTexture(texture_path, {}, event_cb);
    texture.omega_id = 'star.halo.material';
    return texture;
  },

  _shift_texture : function(event_cb){
    var texture_path = Omega.Config.url_prefix + Omega.Config.images_path +
                       Omega.Config.resources.star.halo_shift_texture;
    var texture = THREE.ImageUtils.loadTexture(texture_path, {}, event_cb);
    texture.omega_id = 'star.halo_shift.material';
    return texture;
  },

  _uniforms : function(texture, map, color){
    return {texture : { type: "t",  value : texture },
            map     : { type: "t",  value : map     },
            color   : { type: "v4", value : color   },
            time    : { type: "f",  value : 0.0     }};
  },

  _material : function(uniforms){
    var vsh = Omega.get_shader('vertexShaderHalo');
    var fsh = Omega.get_shader('fragmentShaderHalo');
    var mat = new THREE.ShaderMaterial({uniforms       : uniforms,
                                        vertexShader   : vsh,
                                        fragmentShader : fsh,
                                        transparent    : true,
                                        side           : THREE.DoubleSide,
                                        blending       : THREE.AdditiveBlending});
    return mat;
  },

  _geometry : function(){
    return new THREE.PlaneGeometry(1800, 1800, 1, 1);
  },

  init_gfx : function(color, event_cb){
    var geo = this._geometry();
    var tex = this._texture(event_cb);
    var map = this._shift_texture(event_cb);
    var mat = this._material(this._uniforms(tex, map, color));

    this.tmesh = new THREE.Mesh(geo, mat);
  },

  rendered_in : function(canvas, component){
    this.tmesh.lookAt(canvas.cam_world_position());
  }
};
