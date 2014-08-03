/* Omega Docking Audio Effect
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/audio/base"

Omega.ShipDockingAudioEffect = function(){
  this.audio = Omega.Config.audio['dock'];
};

$.extend(Omega.ShipDockingAudioEffect.prototype, Omega.BaseAudioEffect);
