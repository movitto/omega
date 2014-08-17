/* Omega JS Planet Graphics Updater
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.PlanetGfxUpdater = {
  /// Update local system graphics on core entity changes
  update_gfx : function(){
    this.mesh.update();

    var loc = this.scene_location();
    this.position_tracker().position.set(loc.x, loc.y, loc.z);
  }
};
