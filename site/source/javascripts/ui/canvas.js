/* Omega Javascript Canvas Entities
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/canvas_components"

//= require 'vendor/three/OrbitControls'
//= require 'vendor/three/TrackballControls'

/* Wraps a few canvas related components in the ui
 */
function CanvasContainer(args){
  //this.width  = $omega_config.canvas_width;
  //this.height = $omega_config.canvas_height;
  var width  = $(document).width()  - 50;
  var height = $(document).height() - 150;
  this.canvas = new Canvas({width: width, height: height});

  this.entity_container = new EntityContainer();

  this.locations_list =
    new EntitiesContainer({div_id : '#locations_list'});
  this.locations_list.list.sort =
    function(a,b){ return a.item.json_class > b.item.json_class };

  this.entities_list  =
    new EntitiesContainer({div_id : '#entities_list'});
  this.entities_list.list.sort =
    function(a,b){ return a.item.json_class < b.item.json_class };

  this.missions_button     = new UIComponent();
  this.missions_button.div_id = '#missions_button';

  this.hide = function(){
    this.locations_list.hide();
    this.entities_list.hide();
    this.missions_button.hide();
    this.entity_container.hide();
  }

  this.show = function(){
    this.locations_list.show();
    this.entities_list.show();
    this.missions_button.show();
  }

  return this;
}

/* Canvas through which entities may be rendered
 */
function Canvas(args){
  $.extend(this, new UIComponent(args));
  var nargs       = $.extend({canvas : this}, args);

  this.div_id            = '#omega_canvas';
  this.toggle_control_id = '#toggle_canvas';

  this.scene      = nargs['scene'] ||  new Scene(nargs);
  this.subcomponents.push(this.scene)

  this.canvas_component = function(){
    if(this._canvas_component == null)
      this._canvas_component = $(this.div_id + ' canvas');
    return this._canvas_component;
  };

  // if current page does not have a canvas, return
  if(this.component().length == 0) return;

  this.scene.set_size(this.width, this.height);

  this.on('show', function(c){ this.toggle_control().html('Hide'); });
  this.on('hide', function(c){ this.toggle_control().html('Show'); });

  this.on('resize', function(c, e){
    this.width  = this.component().width() - 3;
    this.height = this.component().height() - 5;
    this.scene.set_size(this.width, this.height);
    this.scene.animate();
  });

  this.on('click', function(c, e){
    var coords = this.click_coords(e.pageX, e.pageY)
    var x = coords[0]; var y = coords[1];
    this.scene.clicked(x, y)
  });
}

/* Scene containing entities to render and renderer
 */
function Scene(args){
  var _this = this;
  $.extend(this, new UIComponent(args));
  var nargs   = $.extend({scene : this}, args);
  this.canvas = nargs['canvas'];

  this.div_id = null;
  this.root = null;
  this.entities = {};

  /* Request animation frame
   *
   * Needs to be available early, so defined here
   */
  this.animate = function(){
    requestAnimationFrame(_this.render);
  }

  /* Internal helper to render scene.
   *
   * Needs to be available early, so defined here
   * !private shouldn't be called by end user!
   */
  this.render = function(){
    //_this.renderer.render(_this._scene, _this.camera._camera);
    _this._shader_composer.render();
    _this._composer.render();

    //_this.camera.controls.update();
  }

  /////////////////////////////////////// three.js init

  // create new three js scene
  this._scene    = new THREE.Scene();

  /// additional scene for shader
  this._shader_scene = new THREE.Scene();

  // initialize global renderer / composers
  if(Scene.renderer == null){
    /// TODO configurable renderer
    //Scene.renderer = new THREE.CanvasRenderer({canvas: _canvas});
    Scene.renderer = new THREE.WebGLRenderer({antialias : true});

    var sw = window.innerWidth, sh = window.innerHeight;
    Scene.renderer.setSize(sw, sh);

    var renderTargetParameters =
	  	{ minFilter: THREE.LinearFilter, magFilter: THREE.LinearFilter, 
	  	  format: THREE.RGBFormat, stencilBuffer: false };
	  Scene._rendererTarget = new THREE.WebGLRenderTarget(sw, sh, renderTargetParameters);

    Scene._composer = new THREE.EffectComposer(Scene.renderer, Scene._rendererTarget)
    Scene._shader_composer = new THREE.EffectComposer(Scene.renderer, Scene._rendererTarget)
  }

  // add to page
  if(this.canvas) this.canvas.component().append(Scene.renderer.domElement);

  // assign as local properties for convenience
  this.renderer = Scene.renderer;
  this._composer = Scene._composer;
  this._shader_composer = Scene._shader_composer;

  // used to render various scene
  this.camera = new Camera(nargs);
  this.subcomponents.push(this.camera)

  // various components available for use in every scene
  this.skybox = new Skybox(nargs);
  this.axis   = new Axis(nargs);
  this.grid   = new Grid(nargs);
  this.subcomponents.push(this.axis)
  this.subcomponents.push(this.grid)

  // add render passes to composers
  /// FIXME remove previously registered
  this._composer.addPass(new THREE.RenderPass(this._scene, this.camera._camera))
  this._shader_composer.addPass(new THREE.RenderPass(this._shader_scene, this.camera._shader_camera))

  // add a few more effect passes, combine composers, and render to screen
  if(Scene.effectBlend == null){
    Scene.bloomPass = new THREE.BloomPass(1.25);
    //Scene.effectFilm = new THREE.FilmPass(0.35, 0.95, 2048, false);
    Scene._composer.addPass(Scene.bloomPass)
    //Scene._composer.addPass(Scene.effectFilm)

    Scene.effectBlend = new THREE.ShaderPass( THREE.AdditiveBlendShader, "tDiffuse1" );
	  Scene.effectBlend.uniforms[ 'tDiffuse2' ].value = Scene._shader_composer.renderTarget2;
	  Scene.effectBlend.renderToScreen = true;
	  Scene._composer.addPass( Scene.effectBlend )

    Scene.renderer.autoClear = false;
    Scene.renderer.setClearColorHex(0x000000, 0.0);
  }

  // set camera to its original position
  this.camera.reset();

  /////////////////////////////////////// public methods

  /* override set size to map canvas resizing to renderer resizing
   */
  this.set_size = function(w, h){
    this.renderer.setSize(w, h);
    this.camera.set_size(w, h);
  }

  /* Add specified entity to scene
   *
   * Entities added need to extend the Entity and CanvasComponent
   * interfaces to be able to be added to the scene
   */
  this.add_entity = function(entity){
    this.entities[entity.id] = entity;
    for(var comp = 0; comp < entity.components.length; comp++)
      this.add_component(entity.components[comp]);
    for(var comp = 0; comp < entity.shader_components.length; comp++)
      this.add_shader_component(entity.shader_components[comp]);
    entity.added_to(this);
  }

  /* Only add entity if not present
   */
  this.add_new_entity = function(entity){
    var oentity = this.entities[entity.id];
    if(oentity) return;
    this.add_entity(entity);
  }

  /* Remove the entity specifed by entity_id from the scene.
   */
  this.remove_entity = function(entity_id){
    var entity = this.entities[entity_id];
    if(entity == null) return;

    for(var comp = 0; comp < entity.components.length; comp++)
      this.remove_component(entity.components[comp]);
    for(var comp = 0; comp < entity.shader_components.length; comp++)
      this.remove_shader_component(entity.shader_components[comp]);
    entity.removed_from(this);
  }

  /* Remove / readd entity to scene.
   *
   * Takes an optional callback to be invoked between
   * removing of entity and adding of entity so that
   * entity may be adjusted if necessary (components added/removed)
   */
  this.reload_entity = function(entity, cb){
    var oentity = this.entities[entity.id];
    if(!oentity) return;

    this.remove_entity(entity.id);
    if(cb) cb.apply(null, [this, entity])
    this.add_entity(entity);
    this.animate();
  }

  /* Return boolean indicating current scene
   * has the specified entity
   */
  this.has = function(entity_id){
    return this.entities[entity_id] != null;
  }

  /* Clear all entities tracked by scene
   */
  this.clear_entities = function(){
    for(var entity_id in this.entities){
      this.remove_entity(entity_id);
    }
    this.entities = [];
  }

  /* Return objects in the scene
   */
  this.objects = function(){
    return this._scene.__objects;
  }

  /* Add specified component to backend three.js scene
   *
   * XXX would like to remove this or mark private
   */
  this.add_component = function(component){
    this._scene.add(component);
  }

  /* Add specified component to backend three.js shader scene
   *
   * XXX would like to remove this or mark private
   */
  this.add_shader_component = function(component){
    this._shader_scene.add(component);
  }

  /* Remove specified component from backend three.js scene
   *
   * XXX would like to remove this or mark private
   */
  this.remove_component = function(component){
    this._scene.remove(component);
  }

  /* Remove specified component from backend three.js shader scene
   *
   * XXX would like to remove this or mark private
   */
  this.remove_shader_component = function(component){
    this._shader_scene.remove(component);
  }

  /* Set root entity of the scene.
   */
  this.set = function(entity){
    this.root = entity;

    var children = entity.children();
    for(var child = 0; child < children.length; child++){
      ch = children[child];
      if(ch)
        this.add_entity(ch);
    }

    this.raise_event('set', entity);
    this.animate();
  }

  /* Return root entity of the scene
   */
  this.get = function(){
    return this.root;
  }

  /* Refresh entities in the current scene
   */
  this.refresh = function(){
    this.set(this.root);
  }

  /* handle canvas clicked event
   */
  this.clicked = function(x, y){
    var clicked_on_entity = false;

    var projector = new THREE.Projector();
    var ray = projector.pickingRay(new THREE.Vector3(x, y, 0.5),
                                   this.camera._camera);
    var intersects = ray.intersectObjects(this.objects());

    if(intersects.length > 0){
      var entities = this.get().children();
      for(var entity in entities){
        entity = entities[entity];
        if(entity.clickable_obj == intersects[0].object){
          clicked_on_entity = true;
          entity.clicked_in(this);
          entity.raise_event('click', this);
          break;
        }
      }
    }

    //if(!clicked_on_entity) controls.clicked_space(x, y);
  }

  /* unselect entity specified by id entity
   */
  this.unselect = function(entity_id){
    var entity = this.entities[entity_id];
    if(entity == null) return;
    entity.unselected_in(this);
    entity.raise_event('unselected', this);
  }

  /* Return the position of the backend scene
   *
   * XXX camera requries access to scene position
   */
  this.position = function(){
    return this._scene.position;
  }
}

/* Instantiate and return a new Camera
 */
function Camera(args){
  /////////////////////////////////////// public data
  var _this = this;
  $.extend(this, new UIComponent(args));

  this.scene = args['scene'];

  this.div_id = '#camera_controls';
  this.control_ids = { reset        : '#cam_reset',
                       pan_right    : '#cam_pan_right',
                       pan_left     : '#cam_pan_left',
                       pan_up       : '#cam_pan_up',
                       pan_down     : '#cam_pan_down',
                       rotate_right : '#cam_rotate_right',
                       rotate_left  : '#cam_rotate_left',
                       rotate_up    : '#cam_rotate_up',
                       rotate_down  : '#cam_rotate_down',
                       zoom_in      : '#cam_zoom_in',
                       zoom_out     : '#cam_zoom_out' };

  /////////////////////////////////////// private data

  if(this.scene.canvas){
    var _width  = this.scene.canvas.width;
    var _height = this.scene.canvas.height;
  }

  /// private initializers
  var new_cam = function(){
    var aspect = _width / _height;
    if(isNaN(aspect)) aspect = 1;
    return new THREE.PerspectiveCamera(75, aspect, 1, 42000 );
    //return new THREE.OrthographicCamera(-500, 500, 500, -500, -1000, 1000);
  }

  var new_controls = function(cam){
    //return new THREE.TrackballControls(cam);
    return new THREE.OrbitControls(cam);
  }

  /// primary scene camera
  this._camera = new_cam();

  /// additional camera for shader
  this._shader_camera = new_cam();
  this._shader_camera.position = this._camera.position;
  this._shader_camera.rotation = this._camera.rotation;

  /// camera controls
  this.controls = new_controls(this._camera);
  this.controls.addEventListener('change', this.scene.render);
  $('#cam_reset').live('click', function(){ _this.reset(); })
  $('#cam_reset').on('mousedown', stop_prop);

  /////////////////////////////////////// public methods

  /* focus the camera on specified target
   */
  this.focus = function(location){
    this.controls.target.set(location.x,location.y,location.z);
    this.controls.update();
  }

  /* Set the size of the camera
   */
  this.set_size = function(width, height){
    _width = width; _height = height
    var aspect = _width / _height;
    if(isNaN(aspect)) aspect = 1;
    this._camera.aspect = this._shader_camera.aspect = aspect;
    this._camera.updateProjectionMatrix();
    this._shader_camera.updateProjectionMatrix();
  }

  /* Set camera to its default position
   */
  this.reset = function(){
    //this.controls.domElement = Scene.renderer.domElement; // XXX need for main, breaks dev

    this.controls.object.position.set(0,3000,3000)
    this.controls.target.set(0,0,0);

    this.controls.update();
    //this.scene.animate();
  }
}

/* Canvas component base class
 *
 * Imposes no additional restrictions on subclasses, though
 * they may add items to the 'components' array to automatically
 * load canvas elements.
 *
 * Subclasses may define the 'toggle_canvas_id' proerty to reference
 * a checkable page element controlling the display of the
 * component in the scene specified by the 'scene' property
 */
function CanvasComponent(args){
  $.extend(this, new EventTracker());

  var showing = false;

  if(args)
    this.scene = args['scene'];

  this.components = [];
  this.shader_components = [];

  /* Return toggle canvas page component
   */
  this.toggle_canvas = function(){
    if(this._toggle_canvas == null)
      this._toggle_canvas = $(this.toggle_canvas_id)
    return this._toggle_canvas;
  }

  /* Return boolean indicating if component is showing
   */
  this.is_showing = function(){
    return showing;
  }

  /* Hide the Component in the scene
   */
  this.shide = function(){
    for(var component = 0; component < this.components.length; component++){
      this.scene.remove_component(this.components[component]);
    }
    for(var component = 0; component < this.shader_components.length; component++){
      this.scene.remove_shader_component(this.shader_components[component]);
    }
    showing = false;
    this.toggle_canvas().attr(':checked', false)
  }

  /* Show the Component in the scene
   */
  this.sshow = function(){
    showing = true;
    this.toggle_canvas().attr(':checked', true)
    for(var component = 0; component < this.components.length; component++)
      this.scene.add_component(this.components[component]);
    for(var component = 0; component < this.shader_components.length; component++)
      this.scene.add_shader_component(this.shader_components[component]);
  }

  /* Toggle showing/hiding the component in the scene based
   * on checked attribute of the toggle_canvas input
   */
  this.stoggle = function(){
    var to_toggle = this.toggle_canvas();
    if(to_toggle){
      if(to_toggle.is(':checked'))
        this.sshow();
      else
        this.shide();
    }
    this.scene.animate();
  }

  /* Wire up the canvas controls
   */
  this.cwire_up = function(){
    // wire up canvas controls
    var comp = this;
    this.toggle_canvas().live('click', function(e){ comp.stoggle(); });
    this.toggle_canvas().attr('checked', false);

    // XXX ensure clicks don't propagate to canvas
    this.toggle_canvas().on('mousedown',  stop_prop);
  }
}


////////////////////////////// a few helper shaders from various locations

/// from http://stemkoski.github.io/Three.js/js/shaders/AdditiveBlendShader.js
THREE.AdditiveBlendShader = {

	uniforms: {
	
		"tDiffuse1": { type: "t", value: null },
		"tDiffuse2": { type: "t", value: null }
	},

	vertexShader: [

		"varying vec2 vUv;",

		"void main() {",

			"vUv = uv;",
			"gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );",

		"}"

	].join("\n"),

	fragmentShader: [

		"uniform sampler2D tDiffuse1;",
		"uniform sampler2D tDiffuse2;",

		"varying vec2 vUv;",

		"void main() {",

			"vec4 texel1 = texture2D( tDiffuse1, vUv );",
			"vec4 texel2 = texture2D( tDiffuse2, vUv );",
			"gl_FragColor = texel1 + texel2;",
		"}"

	].join("\n")

};
