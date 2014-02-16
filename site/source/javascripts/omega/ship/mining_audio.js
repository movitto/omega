/* Omega Ship Mining Audio Effect
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.ShipMiningAudioEffect = function(config){
  this.audio = config.audio['mining'];
};

Omega.ShipMiningAudioEffect.prototype = {
  dom : function(){
    return $('#' + this.audio.src)[0];
  },

  play : function(){
    this.dom().play();
  },

  pause : function(){
    this.dom().pause();
  },
};
