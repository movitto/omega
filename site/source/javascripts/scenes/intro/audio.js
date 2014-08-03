/* Omega Intro Scene Audio
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.Scenes.IntroAudio = function(){
  this.audio1 = Omega.Config.audio.scenes['intro']['bg'];
  this.audio2 = Omega.Config.audio.scenes['intro']['thud'];
};

Omega.Scenes.IntroAudio.prototype = {
  dom1 : function(){
    return $('#' + this.audio1.src)[0];
  },

  dom2 : function(){
    return $('#' + this.audio2.src)[0];
  },

  set_volume : function(volume){
    this.dom1().volume = volume;
    this.dom2().volume = volume;
  },

  _played1 : function(){
    if(!this.first){
      this.first = true;
      return false;
    }

    return true;
  },

  reset : function(){
    this.first = false;
  },

  play : function(){
    this._played1() ? this.dom2().play() :
                      this.dom1().play();
  },

  pause : function(){
    this.dom1().pause()
    this.dom1().currentTime = 0;
    this.dom2().pause();
    this.dom2().currentTime = 0;
  }
};
