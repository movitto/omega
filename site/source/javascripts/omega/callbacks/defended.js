/* Omega JS Defended Event Callback
 *
 * Methods here will get mixed into the CommandTracker module
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.Callbacks.defended = function(event, event_args){
  var defender = event_args[1];
  var attacker = event_args[2];

  var pattacker = this.page.entity(attacker.id);
  var pdefender = this.page.entity(defender.id);
  if(pattacker == null || pdefender == null) return;

  pdefender.hp           = defender.hp;
  pdefender.shield_level = defender.shield_level;
  pdefender.update_defense_gfx();
}
