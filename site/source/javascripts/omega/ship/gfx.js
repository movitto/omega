/* Omega Ship Graphics
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/canvas/entity/gfx"

//= require "omega/ship/gfx/components"
//= require "omega/ship/gfx/load"
//= require "omega/ship/gfx/init"
//= require "omega/ship/gfx/update"
//= require "omega/ship/gfx/effects"

// Ship GFX Mixin
Omega.ShipGfx = {};

$.extend(Omega.ShipGfx, Omega.UI.CanvasEntityGfx);
$.extend(Omega.ShipGfx, Omega.ShipGfxLoader);
$.extend(Omega.ShipGfx, Omega.ShipGfxInitializer);
$.extend(Omega.ShipGfx, Omega.ShipGfxUpdater);
$.extend(Omega.ShipGfx, Omega.ShipGfxEffects);

/// Override CanvasEntityGfx#scene_components to specify components based on scene_mode
Omega.ShipGfx.scene_components = function(scene){
  if(scene.omega_id == 'far')
    return this.abstract_components;
  else if(!this.scene_mode || this.scene_mode != 'far')
    return this.components;
  return [];
};
