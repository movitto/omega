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
  if(scene.omega_id == 'far')
    return this.abstract_components;
  else if(!this.scene_mode || this.scene_mode != 'far')
    return this.components;
  return [];
};
