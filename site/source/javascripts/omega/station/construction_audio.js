/* Omega Station Construction Audio Effect
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/audio/base"

Omega.StationConstructionAudioEffect = function(args){
  this.started  = args.config.audio['construction_started'];
  this.complete = args.config.audio['construction_completed'];
};

$.extend(Omega.StationConstructionAudioEffect.prototype,
         Omega.BaseAudioEffect);
