/* Omega JS Audio Controls UI Component
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require_tree './audio'

Omega.UI.AudioControls = function(parameters){
  this.volume  = 1;
  this.playing = [];
  this.disabled = false;

  /// need handle to page audio controls is on to
  /// - access audio config
  this.page = null;

  $.extend(this, parameters);

  /// central / shared audio effects
  if(this.page)
    this.effects = {  click :        new Omega.ClickAudioEffect(this.page.config),
                    command :      new Omega.CommandAudioEffect(this.page.config),
               confirmation : new Omega.ConfirmationAudioEffect(this.page.config),
                       epic : new Omega.EpicAudioEffect(this.page.config),
                 background : new Omega.BackgroundAudio(this.page.config)};
  else
    this.effects = {};

  /// disable controls by default
  this.toggle();
};

Omega.UI.AudioControls.prototype = {
  /// Wire up AudioControls DOM components
  wire_up : function(){
    var _this = this;

    var mute = $('#mute_audio');
    mute.off('click');
    mute.on('click', function(){
      _this.toggle();
    });
  },

  /// Enable/Disable Audio Controls
  toggle : function(){
    this.disabled = !this.disabled;
    this.set_volume(this.disabled ? 0 : 1);

    if(!this.page) return;
    var url        = this.page.config.url_prefix +
                     this.page.config.images_path + '/icons/';
    var mute_img   = url + 'audio-mute.png';
    var unmute_img = url + 'audio-unmute.png';
    var mute       = $('#mute_audio');

    if(this.disabled)
      mute.css('background', 'url("'+unmute_img+'") no-repeat');
    else
      mute.css('background', 'url("'+mute_img+'") no-repeat');
  },

  set_volume : function(volume){
    this.volume = volume;
    for(var p = 0; p < this.playing.length; p++)
      this.playing[p].set_volume(volume);
  },

  /// Play specified audio target w/ controls
  play : function(){
    var _this  = this;
    var params = Array.prototype.slice.call(arguments);
    var target = params.shift();
    if(!target) return;

    /// Setup ended cb to cleanup after completed
    var ended_cb = function(){ _this.stop(target) }
    params.push(ended_cb);

    this.playing.push(target);
    target.play.apply(target, params);
    target.set_volume(this.volume);
  },

  /// Stop playing audio
  stop : function(target){
    if($.isArray(target)){
      for(var t = 0; t < target.length; t++)
        this.stop(target[t]);
      return;
    }

    if(!target) return;

    this.playing.splice(this.playing.indexOf(target), 1);

    /// TODO option to stop d/l of media
    target.pause();
  }
};
