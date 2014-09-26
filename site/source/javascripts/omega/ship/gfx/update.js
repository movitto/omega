/* Omega JS Ship Graphics Updater
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.ShipGfxUpdater = {
  /// Update ship graphics on movement events
  update_gfx : function(){
    var loc = this.scene_location();
    this.position_tracker().position.set(loc.x, loc.y, loc.z);
    this.location_tracker().rotation.setFromRotationMatrix(this.location.rotation_matrix());
    this.mining_vector.update();
  },

  /// Update graphics on attack events
  update_attack_gfx : function(){
    this.attack_vector.update_state();
    this.attack_component().update_state();
    this.explosions.update_state();
  },

  /// Update graphics on defense events
  update_defense_gfx : function(){
    this.hp_bar.update();
    this.smoke.update_state();
  },

  /// Update graphics on mining events
  update_mining_gfx : function(){
    this.mining_vector.update();
    this.mining_vector.update_state();
  },

  /// Update Movement Effects
  update_movement_effects : function(){
    if(this.location.is_moving('linear'))
      this._run_movement = this._run_linear_movement;
    else if(this.location.is_moving('follow'))
      this._run_movement = this._run_follow_movement;
    else if(this.location.is_moving('rotate'))
      this._run_movement = this._run_rotation_movement;
    else if(this.location.is_moving('figure8'))
      this._run_movement = this._run_figure8_movement;
    else if(this.location.is_stopped())
      this._run_movement = this._no_movement;

    if(this.trails) this.trails.update_state();
  }
};
