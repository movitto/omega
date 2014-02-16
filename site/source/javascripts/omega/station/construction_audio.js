/* Omega Station Construction Audio Effect
 *
 * TODO should be station construction complete audio effect
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.StationConstructionAudioEffect = function(config){
  this.audio = config.audio['construction'];
};

Omega.StationConstructionAudioEffect.prototype = {
  num : 3,

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
