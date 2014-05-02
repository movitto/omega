/* Omega Base Audio Effect
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

/// All subclasses need to do is override this.audio
/// to point to audio dom element
Omega.BaseAudioEffect = {
  dom : function(){
    return $('#' + this.audio.src)[0];
  },

  play : function(){
    this.dom().play();
  },

  pause : function(){
    this.dom().pause();
  }
};
