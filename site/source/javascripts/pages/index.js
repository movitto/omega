/* Omega Index Page JS
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

/// TODO auto-logout on session timeout

//= require "ui/registry"
//= require "ui/canvas_tracker"
//= require "ui/command_tracker"
//= require "ui/session_validator"

//= require "ui/effects_player"
//= require "ui/status_indicator"
//= require "ui/canvas"
//= require "ui/audio_controls"

//= require "ui/pages/index_nav"
//= require "ui/pages/index_dialog"

//= require "ui/splash"

//= require "omega/constraint"

Omega.Pages.Index = function(){
  this.config           = Omega.Config;
  this.node             = new Omega.Node(this.config);
  this.command_tracker  = new Omega.UI.CommandTracker({page : this})
  this.effects_player   = new Omega.UI.EffectsPlayer({page : this});
  this.dialog           = new Omega.UI.IndexDialog({page : this});
  this.nav              = new    Omega.UI.IndexNav({page : this});
  this.canvas           = new       Omega.UI.Canvas({page: this});
  this.status_indicator = new Omega.UI.StatusIndicator({page : this});
  this.audio_controls   = new Omega.UI.AudioControls({page : this});
  this.splash           = new Omega.UI.SplashScreen({page : this});
};

Omega.Pages.Index.prototype = {
  wire_up : function(){
    this.nav.wire_up();
    this.dialog.wire_up();
    this.dialog.follow_node(this.node);
    this.splash.wire_up();
    this.canvas.wire_up();
    this.audio_controls.wire_up();
    this.handle_scene_changes();
    this.status_indicator.follow_node(this.node, 'loading');
    this.effects_player.wire_up();
    this._wire_up_fullscreen();
  },

  /// switch to fullscreen on ctrl-f or ctrl-F
  _wire_up_fullscreen : function(){
    $(document).keypress(function(evnt){
      var F = 70, f = 102;
      if(evnt.ctrlKey == 1 && (evnt.which == F || evnt.which == f))
        Omega.fullscreen.request(document.documentElement);
    });
  },

  /// cleanup index page operations
  unload : function(){
    this.unloading = true;
    this.node.close();
  },

  start : function(){
    if(!this.canvas.detect_webgl()){
      var msg = 'A WebGL capable browser is currently required';
      this.dialog.show_critical_err_dialog('WebGL Required', msg);
      return;
    }

    this.effects_player.start();
    this.splash.start();

    var _this = this;
    if(this._should_autologin()){
      this.autologin(function() { _this._valid_session(); });

    }else{
      this.validate_session(
        function(){ _this._valid_session();   }, // validated
        function(){ _this._invalid_session(); }  // invalid
      );
    }
  },

  _valid_session : function(){
    var _this = this;
    Omega.UI.Loader.load_universe(this, function(){
      Omega.UI.Loader.load_user_entities(_this.session.user_id, _this.node,
        function(entities) {
          _this.process_entities(entities);
          if(_this._should_autoload_root())
            _this.autoload_root();
        });
    });
  },

  _invalid_session : function(){
    var _this = this;
    Omega.UI.Loader.load_universe(this, function(){
      Omega.UI.Loader.load_default_systems(_this,
        function(solar_system) {
          _this.process_system(solar_system);
          /// FIXME should be invoked after we get _all_ default systems
          if(_this._should_autoload_root())
            _this.autoload_root();
        });
    });
  }
};

$.extend(Omega.Pages.Index.prototype, new Omega.UI.Registry());
$.extend(Omega.Pages.Index.prototype, Omega.UI.CanvasTracker);
$.extend(Omega.Pages.Index.prototype, Omega.UI.SessionValidator);

$(document).ready(function(){
  if(Omega.Test) return;

  /// create index page w/ components
  var index = new Omega.Pages.Index();

  /// immediately start preloading missing resources
  Omega.UI.Loader.status_indicator = index.status_indicator;
  Omega.Constraint.load(Omega.Constraint.url(index.config), function(){
    Omega.UI.Loader.preload();
  });

  /// wire up / startup ui
  index.wire_up();
  index.canvas.setup();
  index.start();

  $(window).on('beforeunload', function(){
    index.unload();
  });
});
