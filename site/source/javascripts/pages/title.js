/* Omega Title Page JS
 *
 * Title page used to render pre-arrainged sequences
 * of multimedia content, eg cutscenes
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/registry"
//= require "ui/canvas"
//= require "ui/effects_player"
//= require "ui/audio_controls"
//= require "omega/gen"

//= require_tree "../scenes"

Omega.Pages.Title = function(){
  this.entities       = {};
  this.config         = Omega.Config;
  this.node           = new Omega.Node(this.config);
  this.canvas         = new Omega.UI.Canvas({page: this});
  this.effects_player = new Omega.UI.EffectsPlayer({page: this});
  this.audio_controls = new Omega.UI.AudioControls({page : this});
};

Omega.Pages.Title.prototype = {
  wire_up : function(){
    this.canvas.wire_up();
    this.effects_player.wire_up();
    this.audio_controls.wire_up();

    /// enable audio by default
    this.audio_controls.toggle();
  },

  start : function(){
    this.effects_player.start();
  },

  setup : function(){
    this.canvas.setup();
  },

  play : function(scene){
    scene.run(this);
  }
};

$.extend(Omega.Pages.Title.prototype, new Omega.UI.Registry());

$(document).ready(function(){
  var dev = new Omega.Pages.Title();
  dev.wire_up();
  dev.setup();
  dev.start();

  var intro = new Omega.Scenes.Intro(dev.config);
  dev.play(intro)
});
