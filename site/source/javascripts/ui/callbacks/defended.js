/* Omega JS Defended Event Callback
 *
 * Methods here will get mixed into the CommandTracker module
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.Callbacks.defended = function(event, event_args){
  var defender = event_args[1];
  var attacker = event_args[2];

  var pattacker = $.grep(this.page.all_entities(),
                         function(entity){ return entity.id == attacker.id; })[0];
  var pdefender = $.grep(this.page.all_entities(),
                         function(entity){ return entity.id == defender.id; })[0];
  if(pattacker == null || pdefender == null) return;
  pdefender.hp           = defender.hp;
  pdefender.shield_level = defender.shield_level;

  if(this.page.canvas.is_root(pdefender.parent_id) &&
     this.page.canvas.has(pdefender.id)){
    this.page.canvas.reload(pdefender, function(){
      pdefender.update_defense_gfx();
    });
  }
}
