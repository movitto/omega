/* Omega Solar System Audio Effects
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/audio/base"

Omega.SolarSystemHoverAudioEffect = function(args){
  this.audio = args.config.audio['system_hover'];
};

$.extend(Omega.SolarSystemHoverAudioEffect.prototype, Omega.BaseAudioEffect);

Omega.SolarSystemClickAudioEffect = function(args){
  this.audio = args.config.audio['system_click'];
};

$.extend(Omega.SolarSystemClickAudioEffect.prototype, Omega.BaseAudioEffect);
