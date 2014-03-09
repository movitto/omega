/* Omega Ship Destruction Audio Effect
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.ShipDestructionAudioEffect = function(args){
  if(!args) args = {};
  var config = args['config'];
  this.audio = config.audio['destruction'];
};

Omega.ShipDestructionAudioEffect.prototype = {
  num : 3,
  interval : 1000,

  _base_dom : function(){
    return $('#' + this.audio.src);
  },

  _cloned_dom : function(){
    return $('.' + this.audio.src + '_cloned');
  },

  _cloned : function(){
    return this._cloned_dom().length > 0;
  },

  _clone : function(){
    var audio_list = $('#audio_list')
    var base_dom   = this._base_dom();
    var base_id    = base_dom.attr('id');

    for(var n = 0; n < this.num; n++){
      var clone   = base_dom.clone(true);
      clone.attr('id',    base_id + '_cloned' + n);
      clone.attr('class', base_id + '_cloned');
      audio_list.append(clone);
    }
  },

  dom : function(){
    if(!this._cloned()) this._clone();
    return this._cloned_dom();
  },

  _play_dom : function(n){
    this.dom()[n].play();;
  },

  _pause_dom : function(){
    var dom = this.dom();
    for(var n = 0; n < dom.length; n++)
      dom[n].pause();
  },

  _cycle : function(){
    this._play_dom(this.iteration);

    this.iteration++;
    if(this.iteration == this.num) this.timer.stop();
  },

  play : function(){
    var _this = this;

    this.iteration = 0;
    this.timer =
      $.timer(function(){ _this._cycle(); },
              this.interval, true)
  },

  pause : function(){
    this._pause_dom();
    this.timer.stop();
  }
};
