/* Omega Star Graphics
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/canvas/entity/gfx"

//= require "omega/star/gfx/components"
//= require "omega/star/gfx/load"
//= require "omega/star/gfx/init"
//= require "omega/star/gfx/effects"

// Star Gfx Mixin
Omega.StarGfx = {
  /// for api compatability
  update_gfx : function(){}
};

$.extend(Omega.StarGfx, Omega.UI.CanvasEntityGfx);
$.extend(Omega.StarGfx, Omega.StarGfxLoader);
$.extend(Omega.StarGfx, Omega.StarGfxInitializer);
$.extend(Omega.StarGfx, Omega.StarGfxEffects);
