/* Omega Dev Page JS
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/canvas"
//= require "ui/effects_player"

Omega.Pages.Dev = function(){
  this.config  = Omega.Config;
  this.node    = new Omega.Node(this.config);
  this.canvas  = new Omega.UI.Canvas({page: this});
  this.effects_player = new Omega.UI.EffectsPlayer({page: this});
};

Omega.Pages.Dev.prototype = {
  wire_up : function(){
    this.canvas.wire_up();
    this.effects_player.wire_up();
  },

  custom_operations : function(){
    var star_loc = new Omega.Location({x:0,y:0,z:0});
    var star   = new Omega.Star({location: star_loc});

    var ms  = {e : 0, p : 500, speed: 1.57,
               dmajx: 0, dmajy : 1, dmajz : 0,
               dminx: 0, dminy : 0, dminz : 1};
    var loc = {id : 42, movement_strategy : ms};
    var pl  = new Omega.Planet({location : loc});

    var children = [star, pl];
    var system = new Omega.SolarSystem({children: children});

    this.effects_player.start();
    this.canvas.setup();
    this.canvas.set_scene_root(system);
this.canvas.add(this.canvas.skybox);
this.canvas.skybox.set('galaxy2')

    this.canvas.animate();
  }
};

$(document).ready(function(){
  var dev = new Omega.Pages.Dev();
  dev.wire_up();
  dev.custom_operations();
});
