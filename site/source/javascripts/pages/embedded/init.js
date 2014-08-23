/* Omega JS Embedded Page Initializer
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.Pages.EmbeddedInitializer = {
  wire_up : function(){
    this.canvas.wire_up();
    this.effects_player.wire_up();
    this.audio_controls.wire_up();

    /// audio disabled by default
    //this.audio_controls.toggle();

    this.canvas.init_gl().append();
    return this;
  }
};
