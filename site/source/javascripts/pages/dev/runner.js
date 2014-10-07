/* Omega JS Dev Page Runner
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.Pages.DevRunner = {
  start : function(){
    this.effects_player.start();
    this.track_cam();

    return this;
  }
};
