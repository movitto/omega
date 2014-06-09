/* Omega Ship Movement Audio Effects
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/audio/base"

Omega.ShipMovementAudioEffect = function(args){
  this.audio = args.config.audio['movement'];
};

$.extend(Omega.ShipMovementAudioEffect.prototype, Omega.BaseAudioEffect);
