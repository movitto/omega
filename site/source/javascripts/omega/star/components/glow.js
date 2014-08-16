/* Omega Star Glow
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega/star/components/geometry"

Omega.StarGlow = function(args){
  if(!args) args = {}
  this.tglow = args['glow'] || this.init_gfx();
  //tglow.omega_obj = this;
};

Omega.StarGlow.prototype = {
  clone : function(){
    return new Omega.StarGlow({glow: this.tglow.clone()});
  },

  _shader : function(){
    var vertex_shader   = Omega.get_shader('vertexShaderStar');
    var fragment_shader = Omega.get_shader('fragmentShaderStar');
    return new THREE.ShaderMaterial({
      uniforms: {
        "c":   { type: "f", value: 0.4 },
        "p":   { type: "f", value: 2.0 },
        "r":   { type: "f", value: 0.0 },
        "g":   { type: "f", value: 0.0 },
        "b":   { type: "f", value: 0.0 }
      },
      vertexShader: vertex_shader,
      fragmentShader: fragment_shader,
      side: THREE.BackSide,
      blending: THREE.AdditiveBlending,
      transparent: true
    });
  },

  set_color : function(color){
    var r = ((color >> 16) & 255) / 255;
    var g = ((color >> 8) & 255) / 255;
    var b = (color & 255) / 255;

    this.tglow.material.uniforms.r.value = r;
    this.tglow.material.uniforms.g.value = g;
    this.tglow.material.uniforms.b.value = b;
  },

  init_gfx : function(){
    var smesh_geo = Omega.StarGeometry.load();
    var shader    = this._shader();

    var glow = new THREE.Mesh(smesh_geo, shader);
    glow.scale.set(1.2, 1.2, 1.2);
    return glow;
  }
};
