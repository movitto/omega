/* Omega Solar System Click Audio Effect
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/audio/base"

Omega.SolarSystemClickAudioEffect = function(){
  this.audio = Omega.Config.audio['system_click'];
};

$.extend(Omega.SolarSystemClickAudioEffect.prototype, Omega.BaseAudioEffect);
