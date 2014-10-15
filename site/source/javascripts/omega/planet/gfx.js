/* Omega Planet Graphics
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/canvas/entity/gfx"

//= require "omega/planet/gfx/components"
//= require "omega/planet/gfx/load"
//= require "omega/planet/gfx/init"
//= require "omega/planet/gfx/update"
//= require "omega/planet/gfx/effects"

// Planet Gfx Mixin

Omega.PlanetGfx = {}

$.extend(Omega.PlanetGfx, Omega.UI.CanvasEntityGfx);
$.extend(Omega.PlanetGfx, Omega.PlanetGfxLoader);
$.extend(Omega.PlanetGfx, Omega.PlanetGfxInitializer);
$.extend(Omega.PlanetGfx, Omega.PlanetGfxUpdater);
$.extend(Omega.PlanetGfx, Omega.PlanetGfxEffects);

/// Override CanvasEntityGfx#scene_components to specify components based on scene
Omega.PlanetGfx.scene_components = function(scene){
  if(scene.omega_id == 'far'){
    if(this.scene_mode == 'far')
      return this.abstract_components.concat(this.components);
    else
      return this.abstract_components;
  }

  return this.components;
};
