/* Omega Page Audio Mixin
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/audio_controls"

Omega.Pages.HasAudio = {
  init_audio : function(){
    this.audio_controls = new Omega.UI.AudioControls();
  }
};
