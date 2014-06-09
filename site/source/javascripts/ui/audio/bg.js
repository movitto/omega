/* Omega Background Audio
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.BackgroundAudio = function(config){
  this.num = config.audio.backgrounds;
  this.effects = [];

  this.current = 0;
  this.init_effects();
  this._shuffle_effects();
};

Omega.BackgroundAudio .prototype = {
  max_times : 2,

  _shuffle_effects : function(){
    /// http://stackoverflow.com/questions/6274339/
    var o = this.effects;
    for(var j, x, i = o.length; i;
        j = Math.floor(Math.random() * i),
        x = o[--i], o[i] = o[j], o[j] = x);
  },

  init_effects : function(){
    var _this = this;

    for(var n = 0; n < this.num; n++){
      var effect = $.extend({}, Omega.BaseAudioEffect);
      effect.audio = {src : 'bg_bg' + n + '_wav', loop : true};
      if(effect.dom()){
        effect.dom().addEventListener('ended', function(){
          _this._effect_ended();
        }, false);
      }
      this.effects.push(effect);
    }
  },

  current_effect : function(){
    return this.effects[this.current];
  },

  _effect_ended : function(){
    this.played += 1;
    if(this.played > this.times){
      this._start_fade();
    }
  },

  _start_fade : function(){
    var i = 0;
    var _this = this;

    $.timer(function(){
      var current = _this.current_effect().dom().volume - 0.1;
      if(current < 0) current = 0;
      _this.current_effect().set_volume(current);

      i += 1;
      if(i == 10){
        _this.set_volume(_this.volume);
        _this.current_effect().pause();
        _this.play();
        this.stop();
      }
    }, 1000, true);
  },

  set_volume : function(volume){
    this.volume = volume;
    for(var n = 0; n < this.num; n++)
      this.effects[n].set_volume(volume);
  },

  play : function(){
    this.current += 1;
    if(this.current >= this.num) this.current = 0;

    this.played = 1;
    this.times = Math.floor(Math.random() * this.max_times);
    this.current_effect().play();
  },

  pause : function(){
    for(var n = 0; n < this.num; n++)
      this.effects[n].pause();
  }
};
