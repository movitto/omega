/* Omega JS Attacked Stop Event Callback
 *
 * Methods here will get mixed into the CommandTracker module
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.Callbacks.attacked_stop = function(event, event_args){
  var attacker = event_args[1];
  var defender = event_args[2];

  var pattacker = this.page.entity(attacker.id);
  var pdefender = this.page.entity(defender.id);
  if(pattacker == null || pdefender == null) return;

  pattacker.clear_attacking();
  pattacker.update_attack_gfx();
};
