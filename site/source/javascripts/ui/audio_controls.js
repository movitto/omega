/* Omega JS Audio Controls UI Component
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require_tree './audio'

Omega.UI.AudioControls = function(parameters){
  this.current = null;
  this.disabled = false;

  /// need handle to page audio controls is on to
  /// - access audio config
  this.page = null;

  $.extend(this, parameters);

  /// central / shared audio effects
  if(this.page)
    this.effects = {  click :        new Omega.ClickAudioEffect(this.page.config),
                    command :      new Omega.CommandAudioEffect(this.page.config),
               confirmation : new Omega.ConfirmationAudioEffect(this.page.config)};
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

  /// Play specified audio target w/ controls
  play : function(){
    if(this.disabled) return;

    var params = Array.prototype.slice.call(arguments);
    var target = params.shift();

    if(target) this.current = target;
    this.current.play.apply(this.current, params);
  },

  /// Stop playing audio
  stop : function(){
    /// TODO option to stop d/l of media
    if(this.current) this.current.pause();
  }
};
