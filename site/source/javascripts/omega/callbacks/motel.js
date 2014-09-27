/* Omega JS Motel Event Callback
 *
 * Methods here will get mixed into the CommandTracker module
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

/// TODO incorporate global network latency calculation & use to
/// adjust locs & strategies here

Omega.Callbacks.motel = function(evnt, event_args){
  var entity = $.grep(this.page.all_entities(), function(entity){
                 return entity.location &&
                        entity.location.id == event_args[0].id;
               })[0];
  if(entity == null) return;
  var new_loc = new Omega.Location(event_args[0]);

  /// TODO accomodate for lag, need timestamp from server

  // update last moved
  entity.last_moved = new Date();

  var was_stopped = entity.location.is_stopped();
  entity.location.update(new_loc);
  var is_stopped = entity.location.is_stopped();

  if(entity.update_movement_effects) entity.update_movement_effects();

  if(this.page.canvas.is_root(entity.parent_id)){
    entity.update_gfx();

    if(!was_stopped && is_stopped){
      this.page.audio_controls.play(this.page.audio_controls.effects.epic);
      if(entity.movement_audio)
        this.page.audio_controls.stop(entity.movement_audio);
    }
  }

  entity.dispatchEvent({type : 'movement', data : entity});
};
