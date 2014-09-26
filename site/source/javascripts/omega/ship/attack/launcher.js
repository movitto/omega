/* Omega Ship Launcher Base
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/canvas/components/has_target"

Omega.ShipAttackLauncher = {
  init_launcher : function(args){
    if(!args) args = {};
    var template = args['template'];

    if(template) this.template = template;

    this.projectiles = [];
  },

  should_launch : function(){
    var now = new Date();
    return this.enabled && (!(this.launched_at) ||
           (now - this.launched_at) > (this.interval * 1000));
  },

  _next_offset : function(){
    if(!this.offsets) return new THREE.Vector3(0, 0, 0)

    if(typeof(this.current_offset) === "undefined" ||
       this.current_offset == this.offsets.length-1)
      this.current_offset = 0;
    else
      this.current_offset += 1;

    var offset  = this.offsets[this.current_offset];
    return new THREE.Vector3().set(offset[0], offset[1], offset[2]);
  },

  _init_projectile : function(){
    var projectile = this.template.clone();
    projectile.set_target(this.target());
    projectile.set_source(this.omega_entity);

    var offset = this._next_offset();
    offset.applyMatrix4(this.omega_entity.location.rotation_matrix());
    projectile.location.add(offset);

    return projectile;
  },

  _add_projectile : function(projectile){
    this.projectiles.push(projectile);

    var _this = this;
    this.omega_entity.update_components(function(){
      var projectile_components = projectile.components();
      for(var c = 0; c < projectile_components.length; c++)
        _this.omega_entity.components.push(projectile_components[c]);
    });
  },

  launch : function(){
    this.launched_at = new Date();
    var projectile   = this._init_projectile();
    this._add_projectile(projectile);
  },

  target : function(){
    return this.omega_entity.attacking;
  },

  update : function(){
    this.target_loc(this.target().scene_location());
    for(var m = 0; m < this.projectiles.length; m++)
      this.projectiles[m].set_target(this.target());
  },

  enable : function(){
    this.enabled = true;
  },

  disable : function(){
    this.enabled = false;
  },

  remove : function(projectile){
    var _this = this;
    this.omega_entity.update_components(function(){
      var projectile_components = projectile.components();
      for(var c = 0; c < projectile_components.length; c++){
        var index = _this.omega_entity.components.indexOf(projectile_components[c]);
        if(index != -1) _this.omega_entity.components.splice(index, 1);
      }
    });

    this.projectiles.splice(this.projectiles.indexOf(projectile), 1);
  },

  run_effects : function(){
    if(this.should_launch()) this.launch();

    for(var m = 0; m < this.projectiles.length; m++){
      var projectile = this.projectiles[m];

      if(this.should_remove(projectile)){
        if(this.should_explode(projectile)) projectile.explode();
        this.remove(projectile);

      }else{
        projectile.move_to_target();
      }
    }
  }
};

$.extend(Omega.ShipAttackLauncher, Omega.UI.HasTarget);
