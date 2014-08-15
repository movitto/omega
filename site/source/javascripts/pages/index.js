/* Omega Index Page JS
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

/// TODO auto-logout on session timeout

//= require "pages/mixins/base"
//= require "pages/mixins/has_registry"
//= require "pages/mixins/has_canvas"
//= require "pages/mixins/has_audio"

//= require "pages/mixins/event_handler"
//= require "pages/mixins/scene_tracker"

//= require "pages/mixins/validates_session"
//= require "pages/mixins/autologin"
//= require "pages/mixins/root_autoloader"

//= require "pages/index/init"
//= require "pages/index/runner"
//= require "pages/index/session"
//= require "pages/index/entity_processor"
//= require "pages/index/unload"

//= require "omega/constraint"

Omega.Pages.Index = function(){
  this.init_page();
  this.init_registry();
  this.init_canvas();
  this.init_audio();
  this.init_index();
};

$.extend(Omega.Pages.Index.prototype, Omega.Pages.Base);
$.extend(Omega.Pages.Index.prototype, Omega.Pages.HasRegistry);
$.extend(Omega.Pages.Index.prototype, Omega.Pages.HasCanvas);
$.extend(Omega.Pages.Index.prototype, Omega.Pages.HasAudio);

$.extend(Omega.Pages.Index.prototype, Omega.Pages.EventHandler);
$.extend(Omega.Pages.Index.prototype, Omega.Pages.SceneTracker);

$.extend(Omega.Pages.Index.prototype, Omega.Pages.ValidatesSession);
$.extend(Omega.Pages.Index.prototype, Omega.Pages.Autologin);
$.extend(Omega.Pages.Index.prototype, Omega.Pages.RootAutoloader);

$.extend(Omega.Pages.Index.prototype, Omega.Pages.IndexInitializer);
$.extend(Omega.Pages.Index.prototype, Omega.Pages.IndexRunner);
$.extend(Omega.Pages.Index.prototype, Omega.Pages.IndexSession);
$.extend(Omega.Pages.Index.prototype, Omega.Pages.IndexEntityProcessor);
$.extend(Omega.Pages.Index.prototype, Omega.Pages.IndexUnloader);

$(document).ready(function(){
  if(Omega.Test) return;

  /// create index page w/ components
  var index = new Omega.Pages.Index();

  /// immediately start preloading missing resources
  Omega.UI.Loader.status_indicator = index.status_indicator;
  Omega.Constraint.load(Omega.Constraint.url(), function(){
    Omega.UI.Loader.preload();
  });

  /// wire up / startup ui
  index.wire_up();
  index.start();

  $(window).on('beforeunload', function(){
    index.unload();
  });
});
