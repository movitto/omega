/* Omega JS Destroyed By Event Callback
 *
 * Methods here will get mixed into the CommandTracker module
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.Callbacks.destroyed_by = function(event, event_args){
  var _this    = this;
  var defender = event_args[1];
  var attacker = event_args[2];

  var pattacker = $.grep(this.page.all_entities(),
                         function(entity){ return entity.id == attacker.id; })[0];
  var pdefender = $.grep(this.page.all_entities(),
                         function(entity){ return entity.id == defender.id; })[0];
  if(pattacker == null || pdefender == null) return;
  pattacker.clear_attacking();
  pdefender.hp           = 0;
  pdefender.shield_level = 0;

  if(this.page.canvas.is_root(pattacker.parent_id)){
    this.page.canvas.reload(pattacker, function(){
      pattacker.update_attack_gfx();
    });
  }

  if(this.page.canvas.is_root(pdefender.parent_id)){
    /// play destruction audio effect
    _this.page.audio_controls.play(pdefender.destruction_audio);

    /// start destruction sequence / register cb
    pdefender.trigger_destruction(function(){
      /// allow defender to tidy up gfx b4 removing from scene:
      pdefender.update_defense_gfx();
      /// TODO instead of removing swap out mesh for a 'debris' mesh w/ loot
      /// remove after loot is collected and a certain amount of time passed
      _this.page.canvas.remove(pdefender);
    });
  }
};
