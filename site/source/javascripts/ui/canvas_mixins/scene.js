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

  ui_props : {
    wpadding : 22,
    hpadding : 26
  },

  /// TODO different constraints depending on scene root type
  cam_props : {
    min_distance :   100,
    max_distance : 50000
  },

  render_stats : true,

  /// Setup Canvas 3D operations
  setup : function(){
    this._setup_stats();
    this._setup_scenes();
    this._setup_renderer();
    this._setup_cams();
    this._setup_components();

    THREEx.WindowResize(this.renderer, this.cam,
                        this.ui_props.wpadding,
                        this.ui_props.hpadding);
  },

  _setup_stats : function(){
    if(this.render_stats){
      this.stats = new Stats();
      this.stats.setMode(0);
      $('#render_stats').append(this.stats.domElement);

    }else{
      this.stats = {update : function(){}};
    }
  },

  _setup_scenes : function(){
    this.scene    = new THREE.Scene();
    this.skyScene = new THREE.Scene();
  },

  descendants : function(){
    return this.scene.getDescendants().concat(this.skyScene.getDescendants());
  },

  _setup_renderer : function(){
    var sw = window.innerWidth  - this.ui_props.wpadding,
        sh = window.innerHeight - this.ui_props.hpadding;

    this.renderer = new THREE.WebGLRenderer({antialias : true,
                                             preserveDrawingBuffer: true});
    this.renderer.setSize(sw, sh);

    this.renderer.autoClear = false;
    this.renderer.setClearColor(0x000000, 0.0);

    this.canvas.append(this.renderer.domElement);
  },

  _setup_cams : function(){
    var sw = window.innerWidth  - this.ui_props.wpadding,
        sh = window.innerHeight - this.ui_props.hpadding;
    var aspect = sw / sh;
    if(isNaN(aspect)) aspect = 1;

    this.cam    = new THREE.PerspectiveCamera(75, aspect, 1, 42000 );
    this.skyCam = new THREE.PerspectiveCamera(75, aspect, 1, 42000 );

    this._setup_cam_controls();
  },

  _setup_cam_controls : function(){
    var _this = this;
    this.cam_controls = new THREE.OrbitControls(this.cam);
    this.cam_controls.minDistance = this.cam_props.min_distance;
    this.cam_controls.maxDistance = this.cam_props.max_distance;;
    this.cam_controls.addEventListener('change', function(){ _this.render(); });
    this.cam_controls.domElement = this.renderer.domElement;
    this.reset_cam();
  },

  _setup_components : function(){
    var _this = this;
    this.skybox.init_gfx();
    this.axis.init_gfx();
    this.star_dust.init_gfx(this.page.config, function(){ _this._init_gfx(); });
  },

  _init_gfx : function(){
    this.animate();
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

    /// apply cam rotations to sky cam (but not translations)
    this.skyCam.rotation.setFromRotationMatrix(
      new THREE.Matrix4().extractRotation(this.cam.matrixWorld ),
      this.skyCam.rotation.order);

    /// invoke 'rendered_in' callbacks on scene descendants
    var children = this.scene.getDescendants();
    for(var c = 0; c < children.length; c++){
      var child = children[c];
      if(child.omega_obj && child.omega_obj.rendered_in)
        child.omega_obj.rendered_in(this, child);
    }

    /// render actual scenes
    this.renderer.render(this.skyScene, this.skyCam);
    this.renderer.render(this.scene, this.cam);

    /// render stats
    this.stats.update();
  }
};
