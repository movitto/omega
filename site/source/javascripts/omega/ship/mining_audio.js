/* Omega Ship Mining Audio Effects
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/audio/base"

Omega.ShipMiningAudioEffect = function(args){
  this.audio = args.config.audio['mining'];
};

$.extend(Omega.ShipMiningAudioEffect.prototype, Omega.BaseAudioEffect);

Omega.ShipMiningCompletedAudioEffect = function(args){
  this.audio = args.config.audio['mining_completed'];
};

$.extend(Omega.ShipMiningCompletedAudioEffect.prototype, Omega.BaseAudioEffect);
