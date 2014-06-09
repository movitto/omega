/* Omega Epic Audio Effect
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/audio/base"

Omega.EpicAudioEffect = function(config){
  this.audio = config.audio['epic'];
};

$.extend(Omega.EpicAudioEffect.prototype, Omega.BaseAudioEffect);
