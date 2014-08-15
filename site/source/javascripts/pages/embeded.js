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

//= require "pages/mixins/base"
//= require "pages/mixins/has_registry"
//= require "pages/mixins/has_canvas"
//= require "pages/mixins/has_audio"

//= require "pages/embedded/init"
//= require "pages/embedded/runner"

/// Include Omega in your web page by including embedded.js in your DOM and running:
///   var page = new Omega.Pages.Embedded();
///   page.wire_up().start();
Omega.Pages.Embeded = function(){
  this.init_page();
  this.init_registry();
  this.init_canvas();
  this.init_audio();
}

$.extend(Omega.Pages.Dev.prototype, Omega.Pages.Base);
$.extend(Omega.Pages.Dev.prototype, Omega.Pages.HasRegistry);
$.extend(Omega.Pages.Dev.prototype, Omega.Pages.HasCanvas);
$.extend(Omega.Pages.Dev.prototype, Omega.Pages.HasAudio);

$.extend(Omega.Pages.Dev.prototype, Omega.Pages.EmbeddedInitializer);
$.extend(Omega.Pages.Dev.prototype, Omega.Pages.EmbeddedRunner);
