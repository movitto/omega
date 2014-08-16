/* Omega Solar System Hover Audio Effect
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/audio/base"

Omega.SolarSystemHoverAudioEffect = function(){
  this.audio = Omega.Config.audio['system_hover'];
};

$.extend(Omega.SolarSystemHoverAudioEffect.prototype, Omega.BaseAudioEffect);
