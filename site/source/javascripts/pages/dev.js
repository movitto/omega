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

  custom_operations : function(){
  }
};

$.extend(Omega.Pages.Dev.prototype, new Omega.UI.Registry());

$(document).ready(function(){
  var dev = new Omega.Pages.Dev();
  dev.wire_up();
  dev.custom_operations();
  dev.start();
});
