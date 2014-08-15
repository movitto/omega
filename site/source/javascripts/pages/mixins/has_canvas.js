/* Omega Page Canvas Mixin
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/effects_player"
//= require "ui/canvas"

Omega.Pages.HasCanvas = {
  init_canvas : function(){
    this.canvas         = new Omega.UI.Canvas({page: this});
    this.effects_player = new Omega.UI.EffectsPlayer({page: this});
  }
};
