/* Omega Command Audio Effect
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.CommandAudioEffect = function(config){
  this.audio = config.audio['command'];
};

$.extend(Omega.CommandAudioEffect.prototype, Omega.BaseAudioEffect);
