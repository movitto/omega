/* Omega Star Graphics
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

/// TODO solar flares

//= require "ui/canvas/entity/gfx"

//= require "omega/star/gfx/components"
//= require "omega/star/gfx/load"
//= require "omega/star/gfx/init"

// Star Gfx Mixin
Omega.StarGfx = {
  /// for api compatability
  update_gfx : function(){}
};

$.extend(Omega.StarGfx, Omega.UI.CanvasEntityGfx);
$.extend(Omega.StarGfx, Omega.StarGfxLoader);
$.extend(Omega.StarGfx, Omega.StarGfxInitializer);

/// Override CanvasEntityGfx#scene_components to always
/// add components to far scene
Omega.StarGfx.scene_components = function(scene){
  if(scene.omega_id == 'far')
    return this.abstract_components;
  return this.components;
};
