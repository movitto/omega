/* Omega JS Station Graphics Updater
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.StationGfxUpdater = {
  update_gfx : function(){
    var loc = this.scene_location();
    this.position_tracker().position.set(loc.x, loc.y, loc.z);

    if(this.location.is_stopped()){
      if(this._has_orbit_line()) this._rm_orbit_line();
      this._run_movement_effects = this._run_movement;

    }else{
      if(!this._has_orbit_line()){
        this._calc_orbit();
        this._orbit_angle = this._orbit_angle_from_coords(this.location.coordinates());
        this._add_orbit_line(0x99CCEE);
      }

      if(this.mesh)
        this._run_movement_effects = this._run_orbit_movement;
    }
  },

  update_construction_gfx : function(){
    this.construction_bar.update();
  }
};
