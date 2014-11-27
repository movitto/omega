/* Omega Location JS Representation
 *
 * Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega/location/convert"
//= require "omega/location/coordinates"
//= require "omega/location/json"
//= require "omega/location/movement"
//= require "omega/location/movement_strategy"
//= require "omega/location/orientation"
//= require "omega/location/tracking"

Omega.Location = function(parameters){
  $.extend(this, parameters);
  this.update_ms();
};

Omega.Location.prototype = {
  constructor: Omega.Location,
  json_class : 'Motel::Location'
};

$.extend(Omega.Location.prototype, Omega.LocationConvert);
$.extend(Omega.Location.prototype, Omega.LocationCoordinates);
$.extend(Omega.Location.prototype, Omega.LocationJSON);
$.extend(Omega.Location.prototype, Omega.LocationMovement);
$.extend(Omega.Location.prototype, Omega.LocationMovementStrategy);
$.extend(Omega.Location.prototype, Omega.LocationOrientation);
$.extend(Omega.Location.prototype, Omega.LocationTracking);

Omega.MovementStrategies = {
  json_classes : {
    stopped : 'Motel::MovementStrategies::Stopped',
    linear  : 'Motel::MovementStrategies::Linear',
    rotate  : 'Motel::MovementStrategies::Rotate',
    follow  : 'Motel::MovementStrategies::Follow',
    figure8 : 'Motel::MovementStrategies::Figure8',
    towards : 'Motel::MovementStrategies::Towards'
  }
};
