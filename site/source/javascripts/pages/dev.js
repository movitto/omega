/* Omega Dev Page JS
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/registry"
//= require "ui/canvas"
//= require "ui/effects_player"
//= require "ui/command_tracker"
//= require "omega/gen"

Omega.Pages.Dev = function(){
  this.config  = Omega.Config;
  this.node    = new Omega.Node(this.config);
  this.entities = {};

  this.canvas  = new Omega.UI.Canvas({page: this});
  this.effects_player = new Omega.UI.EffectsPlayer({page: this});
  this.command_tracker= new Omega.UI.CommandTracker({page : this})
};

Omega.Pages.Dev.prototype = {
  wire_up : function(){
    this.canvas.wire_up();
    this.effects_player.wire_up();
  },

  start : function(){
    this.effects_player.start();
  },

  setup : function(){
    var _this = this;
    this.canvas.setup();
    this.canvas.cam.position.set(1500, 1500, 1500);
    this.canvas.focus_on({x:0,y:0,z:0});

    this.custom_operations();

    var light = new THREE.DirectionalLight(0xFFFFFF, 1.0);
    this.canvas.scene.add(light);

    this.canvas.skybox.set(1, this.config, function(){_this.canvas.animate();})
    this.canvas.add(this.canvas.skybox);

    this.canvas.animate();
  },

  custom_operations : function(){
    var system1 = Omega.Gen.solar_system();
    system1.location.set(1000, 0, 1000);
    var system2 = Omega.Gen.solar_system();
    system2.location.set(-1000, 0, -1000);
    system1.add_interconn(system2);
    var galaxy = Omega.Gen.galaxy({children: [system1, system2]});
    this.canvas.set_scene_root(galaxy);
    this.canvas.add(galaxy);
  }
};

$.extend(Omega.Pages.Dev.prototype, new Omega.UI.Registry());

$(document).ready(function(){
  var dev = new Omega.Pages.Dev();
  dev.wire_up();
  dev.setup();
  dev.start();
});
