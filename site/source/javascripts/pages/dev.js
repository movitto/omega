/* Omega Dev Page JS
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/registry"
//= require "ui/canvas"
//= require "ui/canvas_tracker"
//= require "ui/effects_player"
//= require "ui/command_tracker"
//= require "ui/audio_controls"
//= require "omega/gen"

Omega.Pages.Dev = function(){
  this.node    = new Omega.Node();
  this.entities = {};

  this.canvas  = new Omega.UI.Canvas({page: this});
  this.effects_player = new Omega.UI.EffectsPlayer({page: this});
  this.command_tracker= new Omega.UI.CommandTracker({page : this})
  this.audio_controls = new Omega.UI.AudioControls();
};

Omega.Pages.Dev.prototype = {
  wire_up : function(){
    var _this = this;
    this.canvas.wire_up();
    this.effects_player.wire_up();
    this.audio_controls.wire_up();

    this.canvas.addEventListener('set_scene_root',
      function(change){
        if(change.data.root.json_class == "Cosmos::Entities::SolarSystem")
          _this._scale_system(change.data.root);
      });
  },

  start : function(){
    this.effects_player.start();
  },

  setup : function(){
    var _this = this;
    this.canvas.setup();
    this.canvas.cam.position.set(1500, 1500, 1500);
    this.canvas.focus_on({x:0,y:0,z:0});

    Omega.Gen.init(function(){
      _this.custom_operations();
    });

    var light = new THREE.DirectionalLight(0xFFFFFF, 1.0);
    this.canvas.scene.add(light);

    var bg = Math.floor(Math.random() * Omega._num_backgrounds) + 1;
    this.canvas.skybox.set(bg, function(){_this.canvas.animate();})
    this.canvas.add(this.canvas.skybox, this.canvas.skyScene);
    this.canvas.add(this.canvas.star_dust, this.canvas.skyScene);

    this.canvas.animate();
  },

  custom_operations : function(){
  }
};

$.extend(Omega.Pages.Dev.prototype, new Omega.UI.Registry());
$.extend(Omega.Pages.Dev.prototype, Omega.UI.CanvasTracker);

$(document).ready(function(){
  var dev = new Omega.Pages.Dev();
  dev.wire_up();
  dev.setup();
  dev.start();
});
