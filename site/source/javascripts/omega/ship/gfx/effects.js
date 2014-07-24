/* Omega JS Ship Graphics Effects
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.ShipGfxEffects = {
  /// Run ship graphics effects
  run_effects : function(page){
    this._run_movement(page);
    this.lamps.run_effects();
    this.trails.run_effects();
    this.visited_route.run_effects();

    this.attack_component.run_effects();
    this.mining_vector.run_effects();
    this.explosions.run_effects();
    this.destruction.run_effects();
    this.smoke.run_effects();
  },

  /// Trigger ship destruction sequence
  trigger_destruction : function(cb){
    if(this.destruction) this.destruction.trigger(2000, cb);
  }
};
