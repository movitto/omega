/* Omega JS Attacked Event Callback
 *
 * Methods here will get mixed into the CommandTracker module
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.Callbacks.attacked = function(event, event_args){
  var attacker = event_args[1];
  var defender = event_args[2];

  var pattacker = $.grep(this.page.all_entities(),
                         function(entity){ return entity.id == attacker.id; })[0];
  var pdefender = $.grep(this.page.all_entities(),
                         function(entity){ return entity.id == defender.id; })[0];
  if(pattacker == null || pdefender == null) return;
  pattacker.set_attacking(pdefender);
  pattacker.update_attack_gfx();
};
