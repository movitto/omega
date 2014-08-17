/* Omega Galaxy Graphics
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/canvas/entity/gfx"

//= require "omega/galaxy/gfx/components"
//= require "omega/galaxy/gfx/load"
//= require "omega/galaxy/gfx/init"
//= require "omega/galaxy/gfx/effects"

// Galaxy GFX Mixin
Omega.GalaxyGfx = {};

$.extend(Omega.GalaxyGfx, Omega.UI.CanvasEntityGfx);
$.extend(Omega.GalaxyGfx, Omega.GalaxyGfxLoader);
$.extend(Omega.GalaxyGfx, Omega.GalaxyGfxInitializer);
$.extend(Omega.GalaxyGfx, Omega.GalaxyGfxEffects);
