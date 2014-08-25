/* Omega JS Ship Movement
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega/ship/movement/linear"
//= require "omega/ship/movement/rotate"
//= require "omega/ship/movement/follow"
//= require "omega/ship/movement/figure8"

Omega.ShipMovement = {
  _no_movement : function(){}
};

$.extend(Omega.ShipMovement, Omega.ShipLinearMovement);
$.extend(Omega.ShipMovement, Omega.ShipRotationMovement);
$.extend(Omega.ShipMovement, Omega.ShipFollowMovement);
$.extend(Omega.ShipMovement, Omega.ShipFigure8Movement);
