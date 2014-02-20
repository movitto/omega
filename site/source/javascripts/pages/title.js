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

//= require "vendor/purl"

//= require_tree "../scenes"

Omega.Pages.Title = function(){
  this.entities       = {};
  this.config         = Omega.Config;
  this.node           = new Omega.Node(this.config);
  this.canvas         = new Omega.UI.Canvas({page: this});
  this.effects_player = new Omega.UI.EffectsPlayer({page: this});
  this.audio_controls = new Omega.UI.AudioControls({page : this});

  var intro = {id    : 'intro',
               text  : 'Intro',
               scene : new Omega.Scenes.Intro(this.config)};
  this.cutscenes = [intro];
};

Omega.Pages.Title.prototype = {
  cutscene_control : function(){
    return $('#cutscene_control');
  },

  cutscene_menu : function(){
    return $('#cutscene_menu');
  },

  scene_id : function(){
    var url = $.url(window.location);
    return url.param('autoplay');
  },

  wire_up : function(){
    this.canvas.wire_up();
    this.effects_player.wire_up();
    this.audio_controls.wire_up();

    /// enable audio by default
    this.audio_controls.toggle();

    var _this = this;
    this.cutscene_control().on('click', function(){
      _this.cutscene_menu().toggle();
    });

    this.cutscene_menu().on('click', '.cutscene_menu_item',
      function(evnt){
        var cutscene = $(evnt.currentTarget).data('cutscene');
        _this.play(cutscene.scene);
      });
  },

  start : function(){
    this.effects_player.start();

    /// play scene specified in url
    var scene_id = this.scene_id();
    if(scene_id){
      for(var s = 0; s < this.cutscenes.length; s++){
        var cutscene = this.cutscenes[s];
        if(cutscene.id == scene_id){
          this.play(cutscene.scene);
          break;
        }
      }
    }
  },

  setup : function(){
    this.canvas.setup();

    /// add cuscenes to menu
    for(var c = 0; c < this.cutscenes.length; c++){
      var cutscene  = this.cutscenes[c];
      var menu_item = $("<div>", {class : 'cutscene_menu_item',
                                  text  :  cutscene.text});
      menu_item.data('cutscene', cutscene);
      this.cutscene_menu().append(menu_item);
    }
  },

  play : function(scene){
    if(this.current_scene)
      this.current_scene.stop(this);
    this.current_scene = scene;
    scene.run(this);
  }
};

$.extend(Omega.Pages.Title.prototype, new Omega.UI.Registry());

$(document).ready(function(){
  var dev = new Omega.Pages.Title();
  dev.wire_up();
  dev.setup();
  dev.start();
});
