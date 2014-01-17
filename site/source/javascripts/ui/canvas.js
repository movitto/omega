/* Omega JS Canvas UI Component
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/canvas/dialog"
//= require "ui/canvas/controls"
//= require "ui/canvas/entity_container"
//= require "ui/canvas/skybox"
//= require "ui/canvas/axis"

Omega.UI.Canvas = function(parameters){
  this.controls         = new Omega.UI.CanvasControls({canvas: this});
  this.dialog           = new Omega.UI.CanvasDialog({canvas: this});
  this.entity_container = new Omega.UI.CanvasEntityContainer({canvas : this});
  this.skybox           = new Omega.UI.CanvasSkybox({canvas: this});
  this.axis             = new Omega.UI.CanvasAxis();
  this.canvas           = $('#omega_canvas');
  this.root             = null;
  this.entities         = [];

  /// need handle to page the canvas is on to
  /// - lookup missions
  /// - access entity config
  this.page = null;

  $.extend(this, parameters);
};

Omega.UI.Canvas.prototype = {
  wire_up : function(){
    var _this = this;
    this.canvas.off('mousedown mouseup mouseleave mouseout'); /// <- needed ?

    /// mouseup / down must occur within 1/2 second
    /// to be registered as a click
    /// TODO selection box
    var click_duration = 500, timestamp = null;
    this.canvas.mousedown(function(evnt){ timestamp = new Date();});
    this.canvas.mouseup(function(evnt) {
      if(new Date() - timestamp < click_duration){
        timestamp = null;
        _this._canvas_clicked(evnt);
      }
    })

    this.canvas.on('mouseleave', function(){ /// XXX resulting in a mouseout event
      //_this.canvas.trigger('mouseup');
      var evnt = document.createEvent('MouseEvents');
      evnt.initMouseEvent('mouseup', 1, 1, window, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, null);
      _this.cam_controls.domElement.dispatchEvent(evnt);
    });

    this.controls.wire_up();
    this.entity_container.wire_up();
  },

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

  /// TODO simplify, currently don't need shader scene & bloom pass, simplifies alot of things
  setup : function(){
    var _this    = this;

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
    this.cam_controls.maxDistance = 14000;
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
  },

  _canvas_clicked : function(evnt){
    // map page coords to canvas scene coords
    var x = Math.floor(evnt.pageX - this.canvas.offset().left);
    var y = Math.floor(evnt.pageY - this.canvas.offset().top);
        x =   x / this.canvas.width() * 2 - 1;
        y = - y / this.canvas.height() * 2 + 1;

    var projector = new THREE.Projector();
    var ray = projector.pickingRay(new THREE.Vector3(x, y, 0.5), this.cam);
    var intersects = ray.intersectObjects(this.scene.getDescendants());

    if(intersects.length > 0){
      var entity = intersects[0].object.omega_entity;
      if(entity){
        switch (evnt.which){
          case 1: //Left click
            this._clicked_entity(entity);
            break;
          case 3: //Right click
            this._rclicked_entity(entity);
            break;
          case 4: //Middle click
            break;
        }
      }
    }
  },

  _clicked_entity : function(entity){
    if(entity.has_details) this.entity_container.show(entity);
    if(entity.clicked_in) entity.clicked_in(this);
    entity.dispatchEvent({type: 'click'});
  },

  _rclicked_entity : function(entity){
    var selected = this.entity_container.entity;
    if (selected) {
      if(selected.context_action) selected.context_action(entity, this.page);
      entity.dispatchEvent({type: 'rclick'});
    }
  },

  // Reset camera to original position
  reset_cam : function(){
    var default_position = this.page.config.cam.position;
    var default_target   = this.page.config.cam.target;

    this.cam_controls.object.position.set(default_position[0],
                                          default_position[1],
                                          default_position[2]);
    this.cam_controls.target.set(default_target[0],
                                 default_target[1],
                                 default_target[2]);
    this.cam_controls.update();
  },

  // Request animation frame
  animate : function(){
    var _this = this;
    requestAnimationFrame(function() { _this.render(); });
  },

  // Render scene
  render : function(){
    this.renderer.clear();
    this.shader_composer.render();
    this.composer.render();
    //this.renderer.render(this.scene, this.cam);
  },

  // Set the scene root entity
  set_scene_root : function(root){
    var old_root = this.root;
    this.clear();
    this.root    = root;
    var children = root.children;
    for(var c = 0; c < children.length; c++)
      this.add(children[c]);
    this.animate();
    this.dispatchEvent({type: 'set_scene_root',
                        data: {root: root, old_root: old_root}});
  },

  /// Return bool indicating if scene is set to the specified root
  is_root : function(entity_id){
    return this.root != null && this.root.id == entity_id;
  },

  // Focus the scene camera on the specified location
  focus_on : function(loc){
    this.cam_controls.target.set(loc.x,loc.y,loc.z);
    this.cam_controls.update();
  },

  // Add specified entity to scene
  add : function(entity){
    /// XXX hacky but works for now:
    var _this = this;
    entity.sceneReload = function(evnt) { 
      if(entity.mesh == evnt.data && _this.has(entity.id))
        _this.reload(entity);
    };
    entity.addEventListener('loaded_mesh', entity.sceneReload);

    entity.init_gfx(this.page.config, function(evnt){ _this.animate(); });
    for(var cc = 0; cc < entity.components.length; cc++)
      this.scene.add(entity.components[cc]);
    for(var cc = 0; cc < entity.shader_components.length; cc++)
      this.shader_scene.add(entity.shader_components[cc]);

    if(this.page.effects_player)
      this.page.effects_player.add(entity);
    this.entities.push(entity.id);
  },

  // Remove specified entity from scene
  remove : function(entity){
    for(var cc = 0; cc < entity.components.length; cc++)
      this.scene.remove(entity.components[cc]);
    for(var cc = 0; cc < entity.shader_components.length; cc++)
      this.shader_scene.remove(entity.shader_components[cc]);

    /// remove event listener
    entity.removeEventListener('loaded_mesh', entity.sceneReload);

    if(this.page.effects_player)
      this.page.effects_player.remove(entity.id);
    var index = this.entities.indexOf(entity.id);
    if(index != -1) this.entities.splice(index, 1);
  },

  // Remove entity from scene, invoke callback, readd entity to scene
  reload : function(entity, cb){
    var in_scene = this.has(entity.id);
    this.remove(entity);
    if(cb) cb(entity);
    if(in_scene) this.add(entity);
  },

  // Clear entities from the scene
  clear : function(){
    this.root = null;
    this.entities = [];
    var scene_components =
      this.scene ? this.scene.getDescendants() : [];
    var shader_scene_components =
      this.shader_scene ? this.shader_scene.getDescendants() : [];

    for(var c = 0; c < scene_components.length; c++)
      this.scene.remove(scene_components[c]);
    for(var c = 0; c < shader_scene_components.length; c++)
      this.shader_scene.remove(shader_scene_components[c]);
  },

  /// return bool indicating if canvas has entity
  has : function(entity_id){
    return this.entities.indexOf(entity_id) != -1;
  }
};

THREE.EventDispatcher.prototype.apply( Omega.UI.Canvas.prototype );
