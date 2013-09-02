/* Omega Javascript Canvas Entities
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/canvas_components"

/* Wraps a few canvas related components in the ui
 */
function CanvasContainer(args){
  this.canvas              = new Canvas();

  this.entity_container    = new EntityContainer();

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

  this.div_id         = '#omega_canvas';
  this.toggle_control_id = '#toggle_canvas';
  this.scene      = nargs['scene'] ||  new Scene(nargs);
  this.select_box = new SelectBox(nargs);
  this.subcomponents.push(this.scene)
  this.subcomponents.push(this.select_box)

  this.canvas_component = function(){
    if(this._canvas_component == null)
      this._canvas_component = $(this.div_id + ' canvas');
    return this._canvas_component;
  };

  // if current page does not have a canvas, return
  if(this.component().length == 0) return;

  //TODO (also w/ page resize)
  //this.width  = $omega_config.canvas_width;
  //this.height = $omega_config.canvas_height;
  this.width  = $(document).width()  - this.component().offset().left - 50;
  this.height = $(document).height() - this.component().offset().top  - 50;
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

  // XXX need to trigger mouse movement events on canvas itself, not
  // the container as that should respond to resize events,
  // temporarily store and set to canvas to wire up callbacks before restoring
  var old_component = this.component;
  this.component    = this.canvas_component;

  // delegate move movement events to select box
  var delegate_to_select = function(c, e){
    e.target = this.select_box.component()[0];
    this.select_box.component().trigger(e);
    // TODO if select box not active & hovering over a component,
    // invoke a callback (entity.hovered_in(scene))
  }
  this.on('mousemove', delegate_to_select);
  this.on('mousedown', delegate_to_select);
  this.on('mouseup', delegate_to_select);

  this.component    = old_component;
}

/* Scene containing entities to render and renderer
 */
function Scene(args){
  /////////////////////////////////////// public data
  $.extend(this, new UIComponent(args));
  var _this = this;

  this.div_id = null;
  this.entities = {};
  this.root = null;

  this._scene    = new THREE.Scene();

  var nargs   = $.extend({scene : this}, args);
  this.canvas = nargs['canvas'];

  //this.selection = new SceneSelection(nargs);
  this.camera = new Camera(nargs);
  this.skybox = new Skybox(nargs);
  this.axis   = new Axis(nargs);
  this.grid   = new Grid(nargs);
  this.subcomponents.push(this.camera)
  this.subcomponents.push(this.axis)
  this.subcomponents.push(this.grid)

  // setup a timer to run particle subsystems
  this.particle_timer =
    $.timer(function(){
      for(var c in _this._scene.__objects){
        var obj = _this._scene.__objects[c];
        if(obj.update_particles)
          obj.update_particles();
      }
      _this.animate();
    }, 250, false);

  if(Scene.renderer == null){
    // TODO configurable renderer
    //Scene.renderer = new THREE.CanvasRenderer({canvas: _canvas});
    Scene.renderer = new THREE.WebGLRenderer();
  }
  this.renderer = Scene.renderer;
  this.canvas.component().append(this.renderer.domElement);

  /* override set size to map canvas resizing to renderer resizing
   */
  this.set_size = function(w, h){
    this.renderer.setSize(w, h);
    this.camera.set_size(w, h);
    this.camera.reset();
  }

  /* Add specified entity to scene
   *
   * Entities added need to extend the Entity and CanvasComponent
   * interfaces to be able to be added to the scene
   */
  this.add_entity = function(entity){
    this.entities[entity.id] = entity;
    for(var comp in entity.components)
      this.add_component(entity.components[comp]);
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

    for(var comp in entity.components)
      this.remove_component(entity.components[comp]);
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

  /* Add specified component to backend three.js scene
   *
   * XXX would like to remove this or mark private
   */
  this.add_component = function(component){
    this._scene.add(component);
  }

  /* Remove specified component from backend three.js scene
   *
   * XXX would like to remove this or mark private
   */
  this.remove_component = function(component){
    this._scene.remove(component);
  }

  /* Set root entity of the scene.
   */
  this.set = function(entity){
    this.root = entity;

    var children = entity.children();
    for(var child in children){
      child = children[child];
      if(child)
        this.add_entity(child);
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
    var intersects = ray.intersectObjects(this._scene.__objects);

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

  /* return 2d page coordinates of 3d coordinate in scene
   * currently unused
   */
  //this.page_coordinate = function(x, y, z){
  //  // http://zachberry.com/blog/tracking-3d-objects-in-2d-with-three-js/
  //  var p, v, percX, percY, left, top;
  //  var projector = new THREE.Projector();
  //  p = new THREE.Vector3(x, y, z);
  //  v = projector.projectVector(p, this.camera._camera);
  //  percX = (v.x + 1) / 2;
  //  percY = (-v.y + 1) / 2;
  //  left = percX * this.canvas.width;
  //  top  = percY * this.canvas.height;

  //  return [left, top];
  //}

  /* unselect entity specified by id entity
   */
  this.unselect = function(entity_id){
    var entity = this.entities[entity_id];
    if(entity == null) return;
    entity.unselected_in(this);
    entity.raise_event('unselected', this);
  }

  /* Request animation frame
   */
  this.animate = function(){
    requestAnimationFrame(this.render);
  }

  /* Internal helper to render scene.
   *
   * !private shouldn't be called by end user!
   */
  var _this = this;
  this.render = function(){
    _this.renderer.render(_this._scene, _this.camera._camera);
  }

  /* Return the position of the backend scene
   *
   * XXX camera requries access to scene position
   */
  this.position = function(){
    return this._scene.position;
  }

// FIXME: temp hack to create a global light so all lambert materials
//        render properly. Add a better lighting system in the future
var light = new THREE.AmbientLight(0xFFFFFF);
this._scene.add(light);
}

/* Instantiate and return a new Camera
 */
function Camera(args){
  /////////////////////////////////////// public data
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

  var _width  = this.scene.canvas.width;
  var _height = this.scene.canvas.height;

  // private initializer
  var new_cam = function(){
    return new THREE.PerspectiveCamera(75, _width / _height, 1, 42000 );
    // new THREE.OrthographicCamera(-500, 500, 500, -500, -1000, 1000);
  }

  this._camera = new_cam();
  var looking_at = null;

  /////////////////////////////////////// public methods

  /* Set the size of the camera
   */
  this.set_size = function(width, height){
    _width = width; _height = height
    this._camera = new_cam();
  }

  /* Set camera to its default position
   */
  this.reset = function(){
    var z = (20 * Math.sqrt(_width) + 20 * Math.sqrt(_height));
    this.position({x : 0, y : 0, z : z});
    this.focus(this.scene.position());
    this.scene.animate();
  }

  /* Set/get the point the camera is looking at
   */
  this.focus = function(focus){
    if(looking_at == null){
      var pos = this.scene.position();
      looking_at = {x : pos.x, y : pos.y, z : pos.z};
    }
    if(focus != null){
      if(typeof focus.x !== "undefined")
        looking_at.x = focus.x;
      if(typeof focus.y !== "undefined")
        looking_at.y = focus.y;
      if(typeof focus.z !== "undefined")
        looking_at.z = focus.z;
    }
    this._camera.lookAt(looking_at);
    return looking_at;
  }

  /* Set/get the camera position.
   *
   * Takes option position param to set camera position
   * before returning current camera position.
   */
  this.position = function(position){
    if(typeof position !== "undefined"){
      if(typeof position.x !== "undefined")
        this._camera.position.x = position.x;

      if(typeof position.y !== "undefined")
        this._camera.position.y = position.y;

      if(typeof position.z !== "undefined")
        this._camera.position.z = position.z;
    }

    return {x : this._camera.position.x,
            y : this._camera.position.y,
            z : this._camera.position.z};
  }

  /* Zoom the Camera the specified distance from its
   * current position along the axis indicated by its focus
   */
  this.zoom = function(distance){
    var focus = this.focus();

    var x = this._camera.position.x,
        y = this._camera.position.y,
        z = this._camera.position.z;
    var dx = x - focus.x,
        dy = y - focus.y,
        dz = z - focus.z;
    var dist  = Math.sqrt(Math.pow(dx, 2) + Math.pow(dy, 2) + Math.pow(dz, 2));
    var phi = Math.atan2(dx,dz);
    var theta   = Math.acos(dy/dist);

    if((dist + distance) <= 0) return;
    dist += distance;

    dz = dist * Math.sin(theta) * Math.cos(phi);
    dx = dist * Math.sin(theta) * Math.sin(phi);
    dy = dist * Math.cos(theta);

    this._camera.position.x = dx + focus.x;
    this._camera.position.y = dy + focus.y;
    this._camera.position.z = dz + focus.z;

    this.focus();
  }

  /* Rotate the camera using a spherical coordiante system.
   * Specify the number of theta and phi degrees to rotate
   * the camera from its current position
   */
  this.rotate = function(theta_distance, phi_distance){
    var focus = this.focus();

    var x = this._camera.position.x,
        y = this._camera.position.y,
        z = this._camera.position.z;
    var dx = x - focus.x,
        dy = y - focus.y,
        dz = z - focus.z;
    var dist  = Math.sqrt(Math.pow(dx, 2) + Math.pow(dy, 2) + Math.pow(dz, 2));
    var phi = Math.atan2(dx,dz);
    var theta   = Math.acos(dy/dist);

    theta += theta_distance;
    phi   += phi_distance;

    // prevent camera from going too far up / down
    if(theta < 0.5)
      theta = 0.5;
    else if(theta > (Math.PI - 0.5))
      theta = Math.PI - 0.5;

    dz = dist * Math.sin(theta) * Math.cos(phi);
    dx = dist * Math.sin(theta) * Math.sin(phi);
    dy = dist * Math.cos(theta);

    this._camera.position.x = dx + focus.x;
    this._camera.position.y = dy + focus.y;
    this._camera.position.z = dz + focus.z;

    this.focus();
  }

  // Pan the camera along its own X/Y axis
  this.pan = function(x, y){
    var pos   = this.position();
    var focus = this.focus();

    var mat = this._camera.matrix;
    this._camera.position.x += mat.elements[0] * x;
    this._camera.position.y += mat.elements[1] * x;
    this._camera.position.z += mat.elements[2] * x;
    this._camera.position.x += mat.elements[4] * y;
    this._camera.position.y += mat.elements[5] * y;
    this._camera.position.z += mat.elements[6] * y;

    var npos   = this.position();
    this.focus({x : focus.x + (npos.x - pos.x),
                y : focus.y + (npos.y - pos.y),
                z : focus.z + (npos.z - pos.z)});
  }

  /* Wire up the camera to the page
   *
   * @overrideed
   */
  this.old_wire_up = this.wire_up;
  this.wire_up = function(){
    this.old_wire_up();

    if(jQuery.fn.mousehold){
      var _cam = this;

      $(this.control_ids['reset']).click(function(e){
        _cam.reset();
      });

      $(this.control_ids['pan_right']).click(function(e){
        _cam.pan(50, 0);
        _cam.scene.animate();
      });

      $(this.control_ids['pan_right']).mousehold(function(e, ctr){
        _cam.pan(50, 0);
        _cam.scene.animate();
      });

      $(this.control_ids['pan_left']).click(function(e){
        _cam.pan(-50, 0);
        _cam.scene.animate();
      });

      $(this.control_ids['pan_left']).mousehold(function(e, ctr){
        _cam.pan(-50, 0);
        _cam.scene.animate();
      });

      $(this.control_ids['pan_up']).click(function(e){
        _cam.pan(0, 50);
        _cam.scene.animate();
      });

      $(this.control_ids['pan_up']).mousehold(function(e, ctr){
        _cam.pan(0, 50);
        _cam.scene.animate();
      });

      $(this.control_ids['pan_down']).click(function(e){
        _cam.pan(0, -50);
        _cam.scene.animate();
      });

      $(this.control_ids['pan_down']).mousehold(function(e, ctr){
        _cam.pan(0, -50);
        _cam.scene.animate();
      });

      $(this.control_ids['rotate_right']).click(function(e){
        _cam.rotate(0.0, 0.2);
        _cam.scene.animate();
      });

      $(this.control_ids['rotate_right']).mousehold(function(e, ctr){
        _cam.rotate(0.0, 0.2);
        _cam.scene.animate();
      });

      $(this.control_ids['rotate_left']).click(function(e){
        _cam.rotate(0.0, -0.2);
        _cam.scene.animate();
      });

      $(this.control_ids['rotate_left']).mousehold(function(e, ctr){
        _cam.rotate(0.0, -0.2);
        _cam.scene.animate();
      });

      $(this.control_ids['rotate_up']).click(function(e){
        _cam.rotate(-0.2, 0.0);
        _cam.scene.animate();
      });

      $(this.control_ids['rotate_up']).mousehold(function(e, ctr){
        _cam.rotate(-0.2, 0.0);
        _cam.scene.animate();
      });

      $(this.control_ids['rotate_down']).click(function(e){
        _cam.rotate(0.2, 0.0);
        _cam.scene.animate();
      });

      $(this.control_ids['rotate_down']).mousehold(function(e, ctr){
        _cam.rotate(0.2, 0.0);
        _cam.scene.animate();
      });

      $(this.control_ids['zoom_out']).click(function(e){
        _cam.zoom(20);
        _cam.scene.animate();
      });

      $(this.control_ids['zoom_out']).mousehold(function(e, ctr){
        _cam.zoom(20);
        _cam.scene.animate();
      });

      $(this.control_ids['zoom_in']).click(function(e){
        _cam.zoom(-20);
        _cam.scene.animate();
      });

      $(this.control_ids['zoom_in']).mousehold(function(e, ctr){
        _cam.zoom(-20);
        _cam.scene.animate();
      });
    }
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
    for(var component in this.components){
      this.scene.remove_component(this.components[component]);
    }
    showing = false;
    this.toggle_canvas().attr(':checked', false)
  }

  /* Show the Component in the scene
   */
  this.sshow = function(){
    showing = true;
    this.toggle_canvas().attr(':checked', true)
    for(var component in this.components){
      this.scene.add_component(this.components[component]);
    }
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
  }
}

