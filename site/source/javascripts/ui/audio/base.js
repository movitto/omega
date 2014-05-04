/* Omega Base Audio Effect
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

/// All subclasses need to do is override this.audio
/// to point to audio dom element
Omega.BaseAudioEffect = {
  overlap_start: 0.5,

  dom : function(){
    return $('#' + this.audio.src)[0];
  },

  loop_dom : function(){
    return $('#' + this.audio.src + '_loop')[0];
  },

  should_loop : function(){
    return !!(this.audio.loop);
  },

  _setup_loop : function(element){
    var _this = this;
    var alt_element = element == this.dom() ? this.loop_dom() : this.dom();

    element.addEventListener('timeupdate', function(){
      var interval = this.duration - this.currentTime;
      if(interval < _this.overlap_start && alt_element.paused)
        _this._play_element(alt_element);
    }, false);
  },

  _play_element : function(element){
    if(this.should_loop()) this._setup_loop(element);
    if(element.currentTime) element.currentTime = 0;
    element.play();
  },

  play : function(target){
    if(target) this.set(target);
    this._play_element(this.dom());
  },

  pause : function(){
    this.dom().pause();
    this.loop_dom().pause();
  },

  set : function(target){
    if(typeof(target) === "string") target = this[target];

    this.audio = target;
  }
};
