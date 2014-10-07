/* Omega Dev Page JS
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "pages/mixins/base"
//= require "pages/mixins/has_registry"
//= require "pages/mixins/has_canvas"
//= require "pages/mixins/has_audio"

//= require "pages/mixins/scene_tracker"
//= require "pages/mixins/tracks_cam"

//= require "pages/dev/init"
//= require "pages/dev/runner"

Omega.Pages.Dev = function(){
  this.init_page();
  this.init_registry();
  this.init_canvas();
  this.init_audio();
};

Omega.Pages.Dev.prototype = {
  custom_operations : function(){
    /// add custom logic here
  }
};

$.extend(Omega.Pages.Dev.prototype, Omega.Pages.Base);
$.extend(Omega.Pages.Dev.prototype, Omega.Pages.HasRegistry);
$.extend(Omega.Pages.Dev.prototype, Omega.Pages.HasCanvas);
$.extend(Omega.Pages.Dev.prototype, Omega.Pages.HasAudio);

$.extend(Omega.Pages.Dev.prototype, Omega.Pages.SceneTracker);
$.extend(Omega.Pages.Dev.prototype, Omega.Pages.TracksCam);

$.extend(Omega.Pages.Dev.prototype, Omega.Pages.DevInitializer);
$.extend(Omega.Pages.Dev.prototype, Omega.Pages.DevRunner);

$(document).ready(function(){
  new Omega.Pages.Dev().wire_up().start();
});
