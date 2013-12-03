/* Omega JS Canvas UI Component
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/dialog"

Omega.UI.Canvas = function(parameters){
  this.controls         = new Omega.UI.Canvas.Controls({canvas: this});
  this.dialog           = new Omega.UI.Canvas.Dialog({canvas: this});
  this.entity_container = new Omega.UI.Canvas.EntityContainer();
  this.skybox           = new Omega.UI.Canvas.Skybox({canvas: this});
  this.axis             = new Omega.UI.Canvas.Axis();
  this.canvas           = $('#omega_canvas');
  this.root             = null;
  this.entities         = [];

  /// need handle to page the canvas is on to
  /// - lookup missions
  /// - access entity config
  this.page = null

  $.extend(this, parameters);
};

Omega.UI.Canvas.prototype = {
  wire_up : function(){
    var _this = this;
    this.canvas.off('click'); /// <- needed ?
    this.canvas.click(function(evnt) { _this._canvas_clicked(evnt); })

    this.controls.wire_up();
    this.dialog.wire_up();
    this.entity_container.wire_up();
  },

  render_params : {
	  minFilter     : THREE.LinearFilter,
    magFilter     : THREE.LinearFilter,
    format        : THREE.RGBFormat,
    stencilBuffer : false
  },

  setup : function(){
    var _this   = this;
    var padding = 10;

    this.scene = new THREE.Scene();
    this.shader_scene = new THREE.Scene();

    /// TODO configurable renderer:
    //this.renderer = new THREE.CanvasRenderer({canvas: });
    this.renderer = new THREE.WebGLRenderer({antialias : true});

    var sw = window.innerWidth  - padding,
        sh = window.innerHeight - padding;
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
    this.composer.addPass(bloom_pass);
    this.composer.addPass(this.blender_pass);

    this.renderer.autoClear = false;
    this.renderer.setClearColor(0x000000, 0.0);

    this.cam_controls.domElement = this.renderer.domElement;
    this.cam_controls.object.position.set(0,500,500);
    this.cam_controls.target.set(0,0,0);
    this.cam_controls.update();

    THREEx.WindowResize(this.renderer, this.cam, padding);

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
        if(entity.has_details) this.entity_container.show(entity);
        if(entity.clicked_in) this.entity.clicked_in(this);
        entity.dispatchEvent({type: 'click'});
      }
    }
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
  },

  // Set the scene root entity
  set_scene_root : function(root){
    var old_root = this.root;
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
    var _this = this;
    entity.init_gfx(this.page.config, function(evnt){ _this.animate(); });

    for(var cc = 0; cc < entity.components.length; cc++)
      this.scene.add(entity.components[cc]);
    for(var cc = 0; cc < entity.shader_components.length; cc++)
      this.shader_scene.add(entity.shader_components[cc]);

    this.entities.push(entity.id);
  },

  // Remove specified entity from scene
  remove : function(entity){
    for(var cc = 0; cc < entity.components.length; cc++)
      this.scene.remove(entity.components[cc]);
    for(var cc = 0; cc < entity.shader_components.length; cc++)
      this.shader_scene.remove(entity.shader_components[cc]);

    var index = this.entities.indexOf(entity.id);
    if(index != -1) this.entities.splice(index, 1);
  },

  // Remove entity from scene, invoke callback, readd entity to scene
  reload : function(entity, cb){
    this.remove(entity);
    if(cb) cb(entity);
    this.add(entity);
    //this.animate(); // TODO or elsewhere?
  },

  // Clear entities from the scene
  clear : function(){
    this.root = null;
    this.entities = [];
    this._listeners = []; /// clear three.js event listeners (XXX hacky, figure out better way)
    var scene_components        = this.scene.getDescendants();
    var shader_scene_components = this.shader_scene.getDescendants();

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

Omega.UI.Canvas.Controls = function(parameters){
  this.locations_list   = new Omega.UI.Canvas.Controls.List({  div_id : '#locations_list' });
  this.entities_list    = new Omega.UI.Canvas.Controls.List({  div_id : '#entities_list'  });
  this.controls         = $('#canvas_controls');
  this.missions_button  = $('#missions_button');
  this.cam_reset        = $('#cam_reset');
  this.toggle_axis      = $('#toggle_axis input')

  /// need handle to canvas to
  /// - set scene
  /// - set camera target
  /// - reset camera
  /// - add/remove axis from canvas
  this.canvas = null;

  $.extend(this, parameters);

  /// TODO sort locations list
};

Omega.UI.Canvas.Controls.prototype = {
  wire_up : function(){
    var _this = this;

    this.locations_list.component().on('click', 'li',
      function(evnt){
        var item = $(evnt.currentTarget).data('item');
        _this.canvas.set_scene_root(item);
      })

    this.entities_list.component().on('click', 'li',
      function(evnt){
        var item = $(evnt.currentTarget).data('item');
        _this.canvas.set_scene_root(item.solar_system);
        _this.canvas.focus_on(item.location);
      })

    this.missions_button.on('click',
      function(evnt){
        _this._missions_button_click();
      });

    this.toggle_axis.on('click',
      function(evnt){
        if($(evnt.currentTarget).is(':checked'))
          _this.canvas.add(_this.canvas.axis);
        else
          _this.canvas.remove(_this.canvas.axis);
        _this.canvas.animate();
      });
    this.toggle_axis.attr('checked', false);

    this.locations_list.wire_up();
    this.entities_list.wire_up();
  },

  _missions_button_click : function(){
    var _this = this;
    var node  = this.canvas.page.node;
    Omega.Mission.all(node, function(result){ _this.canvas.dialog.show_missions_dialog(result); });
  }
}

Omega.UI.Canvas.Controls.List = function(parameters){
  this.div_id = null;
  $.extend(this, parameters)
};

Omega.UI.Canvas.Controls.List.prototype = {
  wire_up : function(){
    /// FIXME if div_id not set on init,
    /// these will be invalid (also in other components)
    /// (implement setter for div_id?)
    var _this = this;
    this.component().on('mouseenter', function(evnt){ _this.show(); });
    this.component().on('mouseleave', function(evnt){ _this.hide(); });
  },

  component : function(){
    return $(this.div_id);
  },

  list : function(){
    return $(this.component().children('ul')[0]);
  },

  children : function(){
    return this.list().children('li');
  },

  // Add new item to list.
  // Item should specify id, text, data
  add : function(item){
    var element = $('<li/>', {text: item['text']});
    element.data('id', item['id']);
    element.data('item', item['data']);
    this.list().append(element);
  },

  show : function(){
    this.list().show();
  },

  hide : function(){
    this.list().hide();
  }
};

Omega.UI.Canvas.Dialog = function(parameters){
  /// need handle to canvas to
  /// - lookup missions
  this.canvas = null;

  $.extend(this, parameters);

  this.assign_mission = $('.assign_mission');
};

Omega.UI.Canvas.Dialog.prototype = {
  wire_up : function(){
    /// wire up assign_mission click events
/// FIXME as w/ lists above if children are added after
/// wire_up is invoked (or if dialog is hidden during?)
/// they won't pickup handlers
    var _this = this;
    this.component().off('click', '.assign_mission'); // <- XXX needed?
    this.component().
      on('click', '.assign_mission',
         function(evnt) {
           _this._assign_button_click(evnt);
         });
  },

  _assign_button_click : function(evnt){
    var _this = this;
    var node  = this.canvas.page.node;
    var user  = this.canvas.page.session.user_id;

    var mission = $(evnt.currentTarget).data('mission');
    mission.assign_to(user, node, function(res){ _this._assign_mission_clicked(res); })
  },

  show_missions_dialog : function(response){
    var missions   = [];
    var unassigned = [];
    var victorious = [];
    var failed     = [];
    var current    = null;

    if(response.result){
      var current_user = this.canvas.page.session.user_id;
      missions   = response.result;
      unassigned = $.grep(missions, function(m) { return m.unassigned(); });
      assigned   = $.grep(missions, function(m) {
                                     return m.assigned_to(current_user); });
      victorious = $.grep(assigned, function(m) {   return m.victorious; });
      failed     = $.grep(assigned, function(m) {       return m.failed; });
      current    = $.grep(assigned, function(m) {
                                     return !m.victorious && !m.failed; })[0];
    }

    this.hide();
    if(current) this.show_assigned_mission_dialog(current);
    else this.show_missions_list_dialog(unassigned, victorious, failed);
    this.show();
  },

  show_assigned_mission_dialog : function(mission){
    this.title  = 'Assigned Mission';
    this.div_id = '#assigned_mission_dialog';
    $('#assigned_mission_title').html('<b>'+mission.title+'</b>');
    $('#assigned_mission_description').html(mission.description);
    $('#assigned_mission_assigned_time').html('<b>Assigned</b>: '+ mission.assigned_time);
    $('#assigned_mission_expires').html('<b>Expires</b>: '+ mission.expires());
    // TODO cancel mission button?
  },

  show_missions_list_dialog : function(unassigned, victorious, failed){
    this.title  = 'Missions';
    this.div_id = '#missions_dialog';

    $('#missions_list').html('');
    for(var m = 0; m < unassigned.length; m++){
      var mission      = unassigned[m];
      var assign_link = $('<span/>', 
        {'class': 'assign_mission', 
          text:   'assign' });
      assign_link.data('mission', mission);
      $('#missions_list').append(mission.title);
      $('#missions_list').append(assign_link);
      $('#missions_list').append('<br/>');
    }

    var completed_text = '(Victorious: ' + victorious.length +
                         ' / Failed: ' + failed.length +')';
    $('#completed_missions').html(completed_text);
  },

  _assign_mission_clicked : function(response){
    this.hide();
    if(response.error){
      this.title = 'Could not assign mission';
      this.div_id = '#mission_assignment_failed_dialog';
      $('#mission_assignment_error').html(response.error.message);
      this.show();
    }
  }
};

$.extend(Omega.UI.Canvas.Dialog.prototype,
         new Omega.UI.Dialog());

Omega.UI.Canvas.EntityContainer = function(parameters){
  this.entity = null;

  /// need handle to canvas to
  /// - access page to lookup entity data
  /// - refresh entities in scene
  this.canvas = null;

  $.extend(this, parameters);
};

Omega.UI.Canvas.EntityContainer.prototype = {
  div_id      : '#omega_entity_container',
  close_id    : '#entity_container_close',
  contents_id : '#entity_container_contents',

  wire_up : function(){
    var _this = this;
    $(this.close_id).on('click',
      function(evnt){
        _this.hide();
      });

    this.hide();
  },

  hide : function(){
    if(this.entity && this.entity.unselected)
      this.entity.unselected(this.canvas.page);

    this.entity = null;
    $(this.div_id).hide();
  },

  show : function(entity){
    this.hide(); // clears / unselects previous entity if any
    this.entity = entity;

    var _this = this;
    if(entity.retrieve_details)
      entity.retrieve_details(this.canvas.page, function(details){
        _this.append(details);
      });

    if(entity.selected) entity.selected(this.canvas.page);
    $(this.div_id).show();
  },

  append : function(text){
    $(this.contents_id).append(text);
  },

  refresh : function(){
    if(this.entity) this.show(this.entity);
  }
};

Omega.UI.Canvas.Skybox = function(parameters){
  this.components        = [];
  this.shader_components = [];

  /// need handle to canvas to:
  /// - access config
  this.canvas = null;

  $.extend(this, parameters);
};

Omega.UI.Canvas.Skybox.prototype = {
  load_gfx : function(){
    if(typeof(Omega.UI.Canvas.Skybox.gfx) !== 'undefined') return;
    Omega.UI.Canvas.Skybox.gfx = {};

    var size = 32768;
    var geo  = new THREE.CubeGeometry(size, size, size, 7, 7, 7);

    var shader = $.extend(true, {}, THREE.ShaderLib["cube"]); // deep copy needed
    var material = new THREE.ShaderMaterial({
      fragmentShader : shader.fragmentShader,
      vertexShader   : shader.vertexShader,
      uniforms       : shader.uniforms,
      depthWrite     : false,
      side           : THREE.BackSide
    });

    Omega.UI.Canvas.Skybox.gfx.mesh = new THREE.Mesh(geo, material);
  },

  init_gfx : function(){
    if(this.components.length > 0) return;
    this.load_gfx();

    /// just reference it, assuming we're only going to need the one skybox
    this.mesh = Omega.UI.Canvas.Skybox.gfx.mesh;
    this.components = [this.mesh];
  },

  set: function(bg){
    var format = 'png';
    var config = this.canvas.page.config;
    var path   = config.url_prefix + config.images_path + '/skybox/' + bg + '/';
    var materials = [
      path + 'px.' + format, path + 'nx.' + format,
      path + 'pz.' + format, path + 'nz.' + format,
      path + 'py.' + format, path + 'ny.' + format
    ];

    this.mesh.material.uniforms["tCube"].value = THREE.ImageUtils.loadTextureCube(materials);
  }
};

Omega.UI.Canvas.Axis = function(parameters){
  this.size = 750;
  this.components = [];
  this.shader_components = [];
  $.extend(this, parameters);
};

Omega.UI.Canvas.Axis.prototype = {
  load_gfx : function(){
    if(typeof(Omega.UI.Canvas.Axis.gfx) !== 'undefined') return;
    Omega.UI.Canvas.Axis.gfx = {
      xy : this._new_axis(this._new_v(-this.size, 0, 0), this._new_v(this.size, 0, 0), 0xFF0000),
      yz : this._new_axis(this._new_v(0, -this.size, 0), this._new_v(0, this.size, 0), 0x00FF00),
      xz : this._new_axis(this._new_v(0, 0, -this.size), this._new_v(0, 0, this.size), 0x0000FF)
    };
  },

  init_gfx : function(){
    if(this.components.length > 0) return;
    this.load_gfx();

    /// just reference it, assuming we're only going to need the one axis
    for(var a in Omega.UI.Canvas.Axis.gfx)
      this.components.push(Omega.UI.Canvas.Axis.gfx[a]);
  },

  _new_v : function(x,y,z){
    return new THREE.Vector3(x,y,z);
  },

  _new_axis : function(p1, p2, color){
    var geo = new THREE.Geometry();
    var mat = new THREE.LineBasicMaterial({color: color, lineWidth: 1});
    geo.vertices.push(p1, p2);
    return new THREE.Line(geo, mat);
  }
};
