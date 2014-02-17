/* Omega Intro Scene Audio
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.Scenes.IntroAudio = function(config){
  this.audio1 = config.audio.scenes['intro']['bg'];
  this.audio2 = config.audio.scenes['intro']['thud'];
};

Omega.Scenes.IntroAudio.prototype = {
  dom1 : function(){
    return $('#' + this.audio1.src)[0];
  },

  dom2 : function(){
    return $('#' + this.audio2.src)[0];
  },

  _played1 : function(){
    if(typeof(this.first) === "undefined"){
      this.first = true;
      return false;
    }

    return true;
  },

  play : function(){
    this._played1() ? this.dom2().play() :
                      this.dom1().play();
  },
};
