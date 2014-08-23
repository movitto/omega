/* Omega JS Index Page Initializer
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega/callback_handler"

//= require "ui/status_indicator"
//= require "ui/splash"

//= require "pages/index/dialog"
//= require "pages/index/nav"

Omega.Pages.IndexInitializer = {
  init_index : function(){
    this.callback_handler = new Omega.CallbackHandler({page : this})
    this.dialog           = new Omega.Pages.IndexDialog({page : this});
    this.nav              = new Omega.Pages.IndexNav({page : this});
    this.splash           = new Omega.UI.SplashScreen({page : this});
    this.status_indicator = new Omega.UI.StatusIndicator();
  },

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
    this.canvas.append();
  },

  /// switch to fullscreen on ctrl-f or ctrl-F
  /// TODO extract to generic keymapper / configuration mixin, use to map keys to static perspectives
  _wire_up_fullscreen : function(){
    $(document).keypress(function(evnt){
      var F = 70, f = 102;
      if(evnt.ctrlKey == 1 && (evnt.which == F || evnt.which == f))
        Omega.fullscreen.request(document.documentElement);
    });
  },
};
