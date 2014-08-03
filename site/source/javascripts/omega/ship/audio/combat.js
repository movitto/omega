/* Omega Ship Combat Audio Effects
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/audio/base"

Omega.ShipCombatAudioEffect = function(){
  this.start_attack = Omega.Config.audio['start_attack'];
};

$.extend(Omega.ShipCombatAudioEffect.prototype, Omega.BaseAudioEffect);
