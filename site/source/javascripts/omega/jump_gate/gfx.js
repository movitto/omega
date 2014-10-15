/* Omega Jump Gate Graphics
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/canvas/entity/gfx"

//= require 'omega/jump_gate/gfx/components'
//= require 'omega/jump_gate/gfx/load'
//= require 'omega/jump_gate/gfx/init'
//= require 'omega/jump_gate/gfx/update'
//= require 'omega/jump_gate/gfx/effects'

// JumpGate GFX Mixin
Omega.JumpGateGfx = {};

$.extend(Omega.JumpGateGfx, Omega.UI.CanvasEntityGfx);
$.extend(Omega.JumpGateGfx, Omega.JumpGateGfxLoader);
$.extend(Omega.JumpGateGfx, Omega.JumpGateGfxInitializer);
$.extend(Omega.JumpGateGfx, Omega.JumpGateGfxUpdater);
$.extend(Omega.JumpGateGfx, Omega.JumpGateGfxEffects);

/// Override CanvasEntityGfx#scene_components to specify components based on scene
Omega.JumpGateGfx.scene_components = function(scene){
  var in_scene = (scene.omega_id == 'far' && this.scene_mode == 'far') ||
                 (scene.omega_id != 'far' && this.scene_mode != 'far');
  return in_scene ? this.components : [];
};
