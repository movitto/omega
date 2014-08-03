/* Omega Station Construction Audio Effect
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/audio/base"

Omega.StationConstructionAudioEffect = function(){
  this.started  = Omega.Config.audio['construction_started'];
  this.complete = Omega.Config.audio['construction_completed'];
};

$.extend(Omega.StationConstructionAudioEffect.prototype,
         Omega.BaseAudioEffect);
