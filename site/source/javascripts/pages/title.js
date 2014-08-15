/* Omega Title Page JS
 *
 * Title page used to render pre-arrainged sequences
 * of multimedia content, eg cutscenes
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "pages/mixins/base"
//= require "pages/mixins/has_registry"
//= require "pages/mixins/has_canvas"
//= require "pages/mixins/has_audio"

//= require "pages/title/init"
//= require "pages/title/dom"
//= require "pages/title/runner"
//= require "pages/title/autoplay"

//= require "omega/gen"

Omega.Pages.Title = function(){
  this.init_page();
  this.init_registry();
  this.init_canvas();
  this.init_audio();
  this.init_title();
};

$.extend(Omega.Pages.Title.prototype, Omega.Pages.Base);
$.extend(Omega.Pages.Title.prototype, Omega.Pages.HasRegistry);
$.extend(Omega.Pages.Title.prototype, Omega.Pages.HasCanvas);
$.extend(Omega.Pages.Title.prototype, Omega.Pages.HasAudio);

$.extend(Omega.Pages.Title.prototype, Omega.Pages.TitleInitializer);
$.extend(Omega.Pages.Title.prototype, Omega.Pages.TitleDOM);
$.extend(Omega.Pages.Title.prototype, Omega.Pages.TitleRunner);
$.extend(Omega.Pages.Title.prototype, Omega.Pages.TitleAutoplay);

$(document).ready(function(){
  if(Omega.Test) return;

  new Omega.Pages.Title().wire_up().start();
});
