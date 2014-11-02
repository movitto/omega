/* Omega Station Graphics
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/canvas/entity/gfx"

//= require "omega/station/gfx/components"
//= require "omega/station/gfx/load"
//= require "omega/station/gfx/init"
//= require "omega/station/gfx/update"
//= require "omega/station/gfx/effects"

// Station GFX Mixin
Omega.StationGfx = {};

$.extend(Omega.StationGfx, Omega.StationConstructionGfxHelpers);
$.extend(Omega.StationGfx, Omega.UI.CanvasEntityGfx);
$.extend(Omega.StationGfx, Omega.StationGfxLoader);
$.extend(Omega.StationGfx, Omega.StationGfxInitializer);
$.extend(Omega.StationGfx, Omega.StationGfxUpdater);
$.extend(Omega.StationGfx, Omega.StationGfxEffects);

/// Override CanvasEntityGfx#scene_components to specify components based on scene_mode
Omega.StationGfx.scene_components = function(scene){
  var far_components = (this.scene_mode && this.scene_mode == 'far');
  return far_components ? this.abstract_components :
                          this.abstract_components.concat(this.components);
};

/// Override CanvasEntityGfx#scale_size to scale indicator size
Omega.StationGfx.scale_size = function(scale){
  if(!this.indicator) return;
  var size = this.indicator.size;
  if(this.scene_mode != 'near') scale = 0.25;
  this.indicator.set_size(size[0] / scale,
                          size[1] / scale);
};
