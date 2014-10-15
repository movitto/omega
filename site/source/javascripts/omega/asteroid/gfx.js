/* Omega Asteroid Graphics
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/canvas/entity/gfx"

//= require "omega/asteroid/gfx/components"
//= require "omega/asteroid/gfx/load"
//= require "omega/asteroid/gfx/init"
//= require "omega/asteroid/gfx/update"

// Asteroid GFX Mixin
Omega.AsteroidGfx = {};

$.extend(Omega.AsteroidGfx, Omega.UI.CanvasEntityGfx);
$.extend(Omega.AsteroidGfx, Omega.AsteroidGfxLoader);
$.extend(Omega.AsteroidGfx, Omega.AsteroidGfxInitializer);
$.extend(Omega.AsteroidGfx, Omega.AsteroidGfxUpdater);

/// Override CanvasEntityGfx#scene_components to specify components based on scene
Omega.AsteroidGfx.scene_components = function(scene){
  var in_scene = (scene.omega_id == 'far' && this.scene_mode == 'far') ||
                 (scene.omega_id != 'far' && this.scene_mode != 'far');
  return in_scene ? this.components : [];
};
