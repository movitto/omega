/* Omega JS Title Page Autoplayer
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "vendor/purl"

Omega.Pages.TitleAutoplay = {
  autoplay_scene_id : function(){
    var url = $.url(window.location);
    return url.param('autoplay');
  },

  autoplay_scene : function(){
    return this.cutscene(this.autoplay_scene_id());
  },

  should_autoplay : function(){
    return !!(this.autoplay_scene_id());
  }
};
