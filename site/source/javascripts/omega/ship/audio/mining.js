/* Omega Ship Mining Audio Effects
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/audio/base"

Omega.ShipMiningAudioEffect = function(){
  this.audio = Omega.Config.audio['mining'];
};

$.extend(Omega.ShipMiningAudioEffect.prototype, Omega.BaseAudioEffect);

Omega.ShipMiningCompletedAudioEffect = function(){
  this.audio = Omega.Config.audio['mining_completed'];
};

$.extend(Omega.ShipMiningCompletedAudioEffect.prototype, Omega.BaseAudioEffect);
