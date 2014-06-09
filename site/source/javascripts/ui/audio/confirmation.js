/* Omega Confirmation Audio Effect
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/audio/base"

Omega.ConfirmationAudioEffect = function(config){
  this.audio = config.audio['confirmation'];
};

$.extend(Omega.ConfirmationAudioEffect.prototype, Omega.BaseAudioEffect);
