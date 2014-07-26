/* Omega Entity Graphics Stub
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

// Base Entity GFX Stub, allows us to stub out gfx components when not needed.
//
// XXX quick hack to handle some gfx edge cases for certain entity types, ideally
// this would be solved by an extended inheritance heirarchy or similar
Omega.EntityGfxStub = function(){
};

Omega.EntityGfxStub.prototype = {
  update       : function(){},
  update_state : function(){},
  run_effects  : function(){},
  set_position : function(){}
};