/* Omega Base Audio Effect
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

/// All subclasses need to do is override this.audio
/// to point to audio dom element
Omega.BaseAudioEffect = {
  overlap: 0.5,

  dom : function(){
    if(!this._dom) this._dom = $('#' + this.audio.src)[0];
    return this._dom;
  },

  loop_dom : function(){
    if(!this._loop_dom) this._loop_dom = $('#' + this.audio.src + '_loop')[0];
    return this._loop_dom;
  },

  set_volume : function(volume){
    if(!this.dom()) return;

    this.dom().volume = volume;
    this.loop_dom().volume = volume;
  },

  should_loop : function(){
    return !!(this.audio.loop);
  },

  _setup_loop : function(element, alt_element){
    if(this.__setup_loop) return;
    this.__setup_loop = true;

    var _this = this;
    this.dom().addEventListener('timeupdate', function(){
      var interval = this.duration - this.currentTime;
      if(interval < _this.overlap && _this.loop_dom().paused)
        _this._play_element(_this.loop_dom());
    }, false);

    this.loop_dom().addEventListener('timeupdate', function(){
      var interval = this.duration - this.currentTime;
      if(interval < _this.overlap && _this.dom().paused)
        _this._play_element(_this.dom());
    }, false);
  },

  _setup_end : function(ended_cb){
    if(this.__setup_end) return;
    this.__setup_end = true;

    this.dom().addEventListener('ended', function(){ ended_cb(); });
  },

  _play_element : function(element){
    if(element.currentTime) element.currentTime = 0;
    element.play();
  },

  play : function(target, ended_cb){
    if(typeof(target) === "function"){
      ended_cb = target;
      target   = null;
    }

    if(target) this.set(target);
    if(!this.dom()) return;

    if(this.should_loop()) this._setup_loop();
    else this._setup_end(ended_cb);

    this._play_element(this.dom());
  },

  pause : function(){
    if(!this.dom()) return;

    this.dom().pause();
    this.loop_dom().pause();
  },

  set : function(target){
    if(typeof(target) === "string") target = this[target];

    this.audio = target;
  }
};
