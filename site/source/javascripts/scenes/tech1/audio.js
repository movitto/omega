/* Omega Tech1 Scene Audio
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.Scenes.Tech1Audio = function(){
  this.audio1 = Omega.Config.audio.scenes['tech1']['bg'];
};

Omega.Scenes.Tech1Audio.prototype = {
  dom : function(){
    return $('#' + this.audio1.src)[0];
  },

  set_volume : function(volume){
    this.dom().volume = volume;
  },

  play : function(){
    this.dom().play();
  },

  pause : function(){
    this.dom().pause();
    this.dom().currentTime = 0;
  }
};
