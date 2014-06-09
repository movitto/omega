/* Omega Embeded Page JS
 *
 * Self contained page which may be embedded into others,
 * eg does not have a corresponding haml template
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega_three"
//= require "vendor/rjr/json"
//= require "vendor/rjr/jrw-0.17.1"
//= require "vendor/jquery.timer"

//= require "omega/version"
//= require "omega/node"
//= require "omega/common"
//= require "config"

//= require "ui/registry"
//= require "ui/canvas"
//= require "ui/effects_player"
//= require "ui/audio_controls"

Omega.Pages.Embeded = function(){
  this.entities       = {};
  this.config         = Omega.Config;
  this.node           = new Omega.Node(this.config);
  this.canvas         = new Omega.UI.Canvas({page: this});
  this.effects_player = new Omega.UI.EffectsPlayer({page: this});
  this.audio_controls = new Omega.UI.AudioControls({page : this});
}

Omega.Pages.Embeded.prototype = {
  wire_up : function(){
    this.canvas.wire_up();
    this.effects_player.wire_up();
    this.audio_controls.wire_up();

    /// audio disabled by default
    //this.audio_controls.toggle();
  },

  start : function(){
    this.effects_player.start();
  },

  setup : function(){
    this.canvas.setup();
  }
}

$.extend(Omega.Pages.Embeded.prototype, new Omega.UI.Registry());
