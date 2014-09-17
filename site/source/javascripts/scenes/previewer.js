/* Omega Previewer Scene
 *
 * Previous Various Entities.
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "scenes/previewer/setting"

Omega.Scenes.Previewer = function(){
  this.setting = new Omega.Scenes.PreviewerSetting();
};

Omega.Scenes.Previewer.prototype = {
  id : 'previewer',

  /// orbit distance
  distance : 500,

  /// number of seconds to orbit a ship in flyby mode
  interval : 5,

  /// setup scene controls
  setup_controls : function(page){
    var _this = this;

    var input = $('<input>', {id      : '#flyby',
                              type    : 'checkbox',
                              checked : true,
                              style   : 'margin-right: 10px'});
    input.on('click', function(e){
      _this.toggle_flyby(page, this.checked);
    });

    page.scene_controls().append(input);
    page.scene_controls().append('Fly By');
  },

  /// toggle camera fly by
  toggle_flyby : function(page, enabled){
    if(enabled)
      this.flyby_timer.play();
    else{
      this.flyby_timer.stop();
      this._stop_orbiting(page);
    }
  },

  /// setup scene components
  _setup_scene : function(page){
    page.canvas.set_scene_root(this.setting.system);
    page.canvas.add(this.setting.skybox, page.canvas.skyScene);
    this.setting.skybox.set(2, Omega.UI.Canvas.trigger_animation(page.canvas));

    page.canvas.scene.add(this.setting.light);
  },

  /// create flyby timer
  _create_timer : function(page){
    var _this = this;
    this.flyby_timer = $.timer(function(){
      if(_this._should_cycle()){
        _this._stop_orbiting(page);
        _this.entity = _this._next_entity();
      }else if(!_this.orbiting){
        if(_this._near_entity(page) && _this._facing_entity(page))
          _this._start_orbiting(page);
        else{
          _this._nav_to_entity(page);
          if(!_this._facing_entity(page))
            _this._face_entity(page);
        }
      }

      page.canvas.cam_controls.update();
    }, 10, false);
  },

  /// return bool indicating if we should cycle entities
  _should_cycle : function(){
    return typeof(this.entity_index) === "undefined" ||
           (this.orbiting && this.clock.getElapsedTime() > this.interval);
  },

  /// start orbiting entity
  _start_orbiting : function(page){
    this.orbiting = true;
    this.clock = new THREE.Clock();
    page.canvas.cam_controls.autoRotate = true;
    page.canvas.cam_controls.autoRotateSpeed = -3.0;
  },

  /// stop oribing entity
  _stop_orbiting : function(page){
    this.orbiting = false;
    page.canvas.cam_controls.autoRotate = false;
  },

  /// return bool indicating if we're near selected entity
  _near_entity : function(page){
    return this.entity.scene_location().distance_from(page.canvas.cam.position) <= this.distance;
  },

  /// navigate camera to vicinity of entity
  _nav_to_entity : function(page){
    var dir = this.entity.scene_location().direction_to(page.canvas.cam.position);
    var transition = new THREE.Vector3(dir[0] * 50, dir[1] * 50, dir[2] * 50);
    page.canvas.cam.position.sub(transition);
  },

  /// return bool indicating if cam is facing entity
  _facing_entity : function(page){
    var tolerance = this.distance / 10;

    return Math.abs(page.canvas.cam_controls.target.x - this.entity.scene_location().x) < tolerance &&
           Math.abs(page.canvas.cam_controls.target.y - this.entity.scene_location().y) < tolerance &&
           Math.abs(page.canvas.cam_controls.target.z - this.entity.scene_location().z) < tolerance;
  },

  /// face entity
  _face_entity : function(page){
    var dir = this.entity.scene_location().direction_to(page.canvas.cam_controls.target);
    page.canvas.cam_controls.target.add(new THREE.Vector3(-dir[0] * 100, -dir[1] * 100, -dir[2] * 100));
  },

  /// retrieve next entity
  _next_entity : function(){
    if(typeof(this.entity_index) === "undefined" ||
       this.entity_index >= this.setting.entities.length)
      this.entity_index = 0;

    var entity = this.setting.entities[this.entity_index];
    this.entity_index += 1;
    return entity;
  },

  /// run scene
  run : function(page){
    this.setup_controls(page);

    var _this = this;
    this.setting.load(function(){
      _this._setup_scene(page);
      _this._create_timer(page);
      _this.flyby_timer.play();
    });
  },

  /// stop scene
  stop : function(page){
    if(this.flyby_timer) this.flyby_timer.stop();
    page.canvas.clear();
  }
};
