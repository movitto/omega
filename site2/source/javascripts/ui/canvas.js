/* Omega JS Canvas UI Component
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.UI.Canvas = function(parameters){
  this.controls         = new Omega.UI.Canvas.Controls({canvas: this});
  this.dialog           = new Omega.UI.Canvas.Dialog({canvas: this});
  this.entity_container = new Omega.UI.Canvas.EntityContainer();
  this.canvas           = $('#omega_canvas');

  /// need handle to page canvas is on to
  /// - lookup missions
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
    //this.entity_container.wire_up();
  },

  render_params : {
	  minFilter     : THREE.LinearFilter,
    magFilter     : THREE.LinearFilter,
    format        : THREE.RGBFormat,
    stencilBuffer : false
  },

  setup : function(){
    this.scene = new THREE.Scene();
    this.shader_scene = new THREE.Scene();

    /// TODO configurable renderer:
    //this.renderer = new THREE.CanvasRenderer({canvas: });
    this.renderer = new THREE.WebGLRenderer({antialias : true});

    var sw = window.innerWidth,
        sh = window.innerHeight;
    this.renderer.setSize(sw, sh);

	  this.renderTarget =
      new THREE.WebGLRenderTarget(sw, sh, this.render_params);

    this.composer =
      new THREE.EffectComposer(this.renderer, this.renderTarget);
    this.shader_composer =
      new THREE.EffectComposer(this.renderer, this.renderTarget);

    this.canvas.append(this.renderer.domElement);

    var width  = this.canvas.width;
    var height = this.canvas.height;
    var aspect = width / height;
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

    // TODO wire up controls

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
    this.renderer.setClearColorHex(0x000000, 0.0);
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
      entity.dispatchEvent({type: 'click'});
    }
  },

  // Request animation frame
  animate : function(){
    var _this = this;
    requestAnimationFrame(function() { _this.render(); });
  },

  // Render scene
  render : function(){
    this.shader_composer.render();
    this.composer.render();
  },

  // Set the scene root entity
  set_scene_root : function(root){
    var children = root.children;
    for(var c = 0; c < children.length; c++)
      this.add(children[c]);
    this.animate();
  },

  // Focus the scene camera on the specified location
  focus_on : function(loc){
    this.cam_controls.target.set(loc.x,loc.y,loc.z);
    this.cam_controls.update();
  },

  // Add specified entity to scene
  add : function(entity){
    for(var cc = 0; cc < entity.components.length; cc++)
      this.scene.add(entity.components[cc]);
    for(var cc = 0; cc < entity.shader_components.length; cc++)
      this.shader_scene.add(entity.shader_components[cc]);
  },

  // Clear entities from the scene
  clear : function(){
    var scene_components        = this.scene.getDescendants();
    var shader_scene_components = this.shader_scene.getDescendants();

    for(var c = 0; c < scene_components.length; c++)
      this.scene.remove(scene_components[c]);
    for(var c = 0; c < shader_scene_components.length; c++)
      this.shader_scene.remove(shader_scene_components[c]);
  }
};

Omega.UI.Canvas.Controls = function(parameters){
  this.locations_list   = new Omega.UI.Canvas.Controls.List({  div_id : '#locations_list' });
  this.entities_list    = new Omega.UI.Canvas.Controls.List({  div_id : '#entities_list'  });
  this.missions_button  = new Omega.UI.Canvas.Controls.Button({div_id : '#missions_button'});
  this.cam_reset_button = new Omega.UI.Canvas.Controls.Button({div_id : '#cam_reset'      });

  /// need handle to canvas to
  /// - set scene
  /// - set camera target
  /// - reset camera
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

    this.missions_button.component().on('click',
      function(evnt){
        _this._missions_button_click();
      });

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

Omega.UI.Canvas.Controls.Button = function(parameters){
  this.div_id = null;
  $.extend(this, parameters);
};

Omega.UI.Canvas.Controls.Button.prototype = {
  component : function(){
    return $(this.div_id);
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

Omega.UI.Canvas.EntityContainer = function(){
  this.div_id = '#entity_container';
};
