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

/// Override CanvasEntityGfx#scale_size to scale mesh/axis size
Omega.PlanetGfx.scale_size = function(scale){
  if(!this.mesh) return;

  this.mesh.tmesh.scale.set(scale, scale, scale);
  this.axis.mesh.scale.set(scale, scale, scale);
};
