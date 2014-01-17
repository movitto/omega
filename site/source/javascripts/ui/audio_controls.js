/* Omega JS Audio Controls UI Component
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.UI.AudioControls = function(parameters){
  this.current = null;
  this.disabled = false;

  /// need handle to page audio controls is on to
  /// - access audio config
  this.page = null;

  $.extend(this, parameters);

  /// disable controls by default
  this.toggle();
};

Omega.UI.AudioControls.prototype = {
  wire_up : function(){
    var _this = this;

    var mute = $('#mute_audio');
    mute.off('click');
    mute.on('click', function(){
      _this.toggle();
    });
  },

  toggle : function(){
    var url        = this.page.config.url_prefix +
                     this.page.config.images_path + '/icons/';
    var mute_img   = url + 'audio-mute.png';
    var unmute_img = url + 'audio-unmute.png';
    var mute       = $('#mute_audio');

    this.disabled = !this.disabled;
    if(this.disabled)
      mute.css('background', 'url("'+unmute_img+'") no-repeat');
    else
      mute.css('background', 'url("'+mute_img+'") no-repeat');
  },

  set : function(id){
    this.current = this.page.config.audio[id];
  },

  audio : function(){
    return $('#' + this.current.src)[0];
  },

  play : function(){
    if(this.disabled) return;

    /// TODO start & stop if specified in this.current
    this.audio().play();
  },

  stop : function(){
    /// TODO option to stop d/l of media
    this.audio().pause();
  }
};
