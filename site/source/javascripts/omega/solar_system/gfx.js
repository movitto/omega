/* Omega Solar System Graphics
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/canvas/entity/gfx"

//= require "omega/solar_system/gfx/components"
//= require "omega/solar_system/gfx/load"
//= require "omega/solar_system/gfx/init"
//= require "omega/solar_system/gfx/update"
//= require "omega/solar_system/gfx/effects"

// Solar System GFX Mixin
Omega.SolarSystemGfx = {};

$.extend(Omega.SolarSystemGfx, Omega.UI.CanvasEntityGfx);
$.extend(Omega.SolarSystemGfx, Omega.SolarSystemGfxLoader);
$.extend(Omega.SolarSystemGfx, Omega.SolarSystemGfxInitializer);
$.extend(Omega.SolarSystemGfx, Omega.SolarSystemGfxUpdater);
$.extend(Omega.SolarSystemGfx, Omega.SolarSystemGfxEffects);
