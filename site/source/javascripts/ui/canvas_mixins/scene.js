/* Omega JS Canvas Scene Mixin
 *
 * Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require 'vendor/stats.min'

Omega.UI.CanvasSceneManager = {
  /// Setup Canvas 3D operations
  //
  /// TODO simplify, currently don't need shader scene & bloom pass,
  ///      simplifies alot of things
  setup : function(){
    var _this    = this;

    if(this.render_stats){
      this.stats = new Stats();
      this.stats.setMode(0);
      $('#render_stats').append(this.stats.domElement);

    }else{
      this.stats = {update : function(){}};
    }

    this.scene = new THREE.Scene();
    this.shader_scene = new THREE.Scene();

    /// TODO configurable renderer:
    //this.renderer = new THREE.CanvasRenderer({canvas: });
    this.renderer = new THREE.WebGLRenderer({antialias : true});

    var sw = window.innerWidth  - this.ui_props.wpadding,
        sh = window.innerHeight - this.ui_props.hpadding;
    this.renderer.setSize(sw, sh);

	  this.renderTarget =
      new THREE.WebGLRenderTarget(sw, sh, this.render_params);

    this.composer =
      new THREE.EffectComposer(this.renderer, this.renderTarget);
    this.shader_composer =
      new THREE.EffectComposer(this.renderer, this.renderTarget);

    this.canvas.append(this.renderer.domElement);

    var aspect = sw / sh;
    if(isNaN(aspect)) aspect = 1;

    // TODO configuable camera
    //this.cam = new THREE.OrthographicCamera(-500, 500, 500, -500, -1000, 1000);
    this.cam = new THREE.PerspectiveCamera(75, aspect, 1, 42000 );

    this.shader_cam = this.cam.clone();
    this.shader_cam.position = this.cam.position;
    this.shader_cam.rotation = this.cam.rotation;

    // TODO configurable controls
    //this.cam_controls = new THREE.TrackballControls(cam);
    this.cam_controls = new THREE.OrbitControls(this.cam);
    this.cam_controls.minDistance =   100;
    //this.cam_controls.maxDistance = 14000;
    this.cam_controls.addEventListener('change', function(){ _this.render(); });

    // TODO clear existing passes?
    var render_pass         = new THREE.RenderPass(this.scene, this.cam);
    var shader_render_pass  = new THREE.RenderPass(this.shader_scene, this.shader_cam);
    var bloom_pass          = new THREE.BloomPass(1.25);
    //var film_pass           = new THREE.FilmPass(0.35, 0.95, 2048, false);

    this.blender_pass       = new THREE.ShaderPass(THREE.AdditiveBlendShader, "tDiffuse1" );
    this.blender_pass.uniforms[ 'tDiffuse2' ].value = this.shader_composer.renderTarget2;
    this.blender_pass.renderToScreen = true;

    this.shader_composer.addPass(shader_render_pass);
    this.composer.addPass(render_pass);
    //this.composer.addPass(bloom_pass);
    this.composer.addPass(this.blender_pass);

    this.renderer.autoClear = false;
    this.renderer.setClearColor(0x000000, 0.0);

    this.cam_controls.domElement = this.renderer.domElement;
    this.reset_cam();

    THREEx.WindowResize(this.renderer, this.cam,
                        this.ui_props.wpadding, this.ui_props.hpadding);

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
    this.renderer.clear();
    this.shader_composer.render();
    this.composer.render();
    this.stats.update();
    //this.renderer.render(this.scene, this.cam);
  }
};
