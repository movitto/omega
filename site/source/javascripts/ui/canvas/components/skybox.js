/* Omega JS Canvas Skybox Scene Component
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.UI.CanvasSkybox = function(parameters){
  this.components        = [];
  this.shader_components = [];
  $.extend(this, parameters);
};

Omega.UI.CanvasSkybox.prototype = {
  id : 'canvas_skybox',
  size : 32768,

  load_gfx : function(){
    if(typeof(Omega.UI.CanvasSkybox.gfx) !== 'undefined') return;
    Omega.UI.CanvasSkybox.gfx = {};

    var geo  = new THREE.CubeGeometry(this.size, this.size, this.size, 7, 7, 7);

    var shader = $.extend(true, {}, THREE.ShaderLib["cube"]); // deep copy needed
    var material = new THREE.ShaderMaterial({
      fragmentShader : shader.fragmentShader,
      vertexShader   : shader.vertexShader,
      uniforms       : shader.uniforms,
      depthWrite     : false,
      side           : THREE.BackSide
    });

    Omega.UI.CanvasSkybox.gfx.mesh = new THREE.Mesh(geo, material);
  },

  init_gfx : function(){
    if(this.components.length > 0) return;
    this.load_gfx();

    /// just reference it, assuming we're only going to need the one skybox
    this.mesh = Omega.UI.CanvasSkybox.gfx.mesh;
    this.components = [this.mesh];
  },

  set: function(bg, event_cb){
    var format = 'png';
    var path   = Omega.Config.url_prefix + Omega.Config.images_path + '/skybox/skybox' + bg + '/';
    var materials = [
      path + 'px.' + format, path + 'nx.' + format,
      path + 'pz.' + format, path + 'nz.' + format,
      path + 'py.' + format, path + 'ny.' + format
    ];

    this.mesh.material.uniforms["tCube"].value =
      THREE.ImageUtils.loadTextureCube(materials, {}, event_cb);
  },

  scene_components : function(){
    return this.components;
  },

  has_effects : function(){ return false; },
  scale_position : function(){}
};

THREE.EventDispatcher.prototype.apply( Omega.UI.CanvasSkybox.prototype );
