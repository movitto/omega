/* Omega JS Canvas Scene Mixin
 *
 * Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require 'vendor/stats.min'

Omega.UI.CanvasSceneManager = {
  render_params : {
	  minFilter     : THREE.LinearFilter,
    magFilter     : THREE.LinearFilter,
    format        : THREE.RGBFormat,
    stencilBuffer : false
  },

  render_stats : true,

  /// init Canvas 3D operations
  init_gl : function(){
    if(!this.detect_webgl()) return;

    this._init_stats();
    this._init_scenes();
    this._init_renderer();
    this._init_cams();
    this._init_components();
    return this;
  },

  detect_webgl : function(){
    return Detector.webgl;
  },

  _init_stats : function(){
    if(this.render_stats){
      this.stats = new Stats();
      this.stats.setMode(0);

    }else{
      this.stats = {update : function(){}};
    }
  },

  _init_scenes : function(){
    this.scene    = new THREE.Scene();
    this.skyScene = new THREE.Scene();

    this.scene.omega_id    = 'scene';
    this.skyScene.omega_id = 'sky';
  },

  descendants : function(){
    return this.scene.getDescendants().concat(this.skyScene.getDescendants());
  },

  _init_renderer : function(){
    var sw = window.innerWidth;
        sh = window.innerHeight;

    this.renderer = new THREE.WebGLRenderer({antialias : true,
                                             preserveDrawingBuffer: true});
    this.renderer.setSize(sw, sh);

    this.renderer.autoClear = false;
    this.renderer.setClearColor(0x000000, 0.0);
  },

  _init_cams : function(){
    var sw = window.innerWidth;
        sh = window.innerHeight;
    var aspect = sw / sh;
    if(isNaN(aspect)) aspect = 1;

    this.cam    = new THREE.PerspectiveCamera(75, aspect, 1, 500000 );
    this.skyCam = new THREE.PerspectiveCamera(75, aspect, 1,   1000 );

    /// tie scene / sky camera rotation
    this.skyCam.quaternion = this.cam.quaternion;

    this._init_cam_controls();
  },

  _init_cam_controls : function(){
    var _this = this;
    this.cam_controls = new THREE.OrbitControls(this.cam);
    this.cam_controls.minDistance = Omega.Config.cam.distance.min;
    this.cam_controls.maxDistance = Omega.Config.cam.distance.max;
    this.cam_controls.addEventListener('change', function(){ _this.render(); });
    this.cam_controls.domElement = this.renderer.domElement;
    this.reset_cam();
  },

  _init_components : function(){
    var _this = this;
    this.skybox.init_gfx();
    this.axis.init_gfx();
    this.star_dust.init_gfx(function(){ _this._init_gfx(); });
  },

  _init_gfx : function(){
    this.animate();
  },

  /// append canvas components to page
  append : function(){
    if(this.render_stats) $('#render_stats').append(this.stats.domElement);

    this.canvas.append(this.renderer.domElement);

    THREEx.WindowResize(this.renderer, this.cam);

    return this;
  },

  // Request animation frame
  animate : function(){
    var _this = this;
    requestAnimationFrame(function() { _this.render(); });
    this._detect_hover();
  },

  // Render scene (used internally, no need to invoke manually)
  render : function(){
    /// clear renderer
    this.renderer.clear();

    /// invoke 'rendered_in' callbacks on scene descendants
    for(var c = 0; c < this.rendered_in.length; c++){
      var child = this.rendered_in[c];
      child.omega_obj.rendered_in(this, child);
    }

    /// render actual scenes
    this.renderer.render(this.skyScene, this.skyCam);
    this.renderer.render(this.scene, this.cam);

    /// render stats
    this.stats.update();
  }
};
