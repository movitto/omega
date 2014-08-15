/* Omega JS Title Page Runner
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.Pages.TitleRunner = {
  start : function(){
    this.effects_player.start();

    /// play scene specified in url
    if(this.should_autoplay())
      this.play(this.autoplay_scene());

    return this;
  },

  play : function(scene){
    if(this.current_scene)
      this.current_scene.stop(this);
    this.current_scene = scene;
    this.canvas.reset_cam();
    scene.run(this);
  }
};
