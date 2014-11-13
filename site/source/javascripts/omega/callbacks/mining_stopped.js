/* Omega JS Mining Stopped Event Callback
 *
 * Methods here will get mixed into the CommandTracker module
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.Callbacks.mining_stopped = function(event, event_args){
  var ship     = event_args[1];
  var resource = event_args[2];
  var reason   = event_args[3];

  var entity = this.page.entity(ship.id);
  if(entity == null) return;

  entity.clear_mining();
  entity.resources = ship.resources;
  entity._update_resources();

  if(this.page.canvas.is_root(entity.parent_id)){
    this.page.audio_controls.stop(entity.mining_audio);
    this.page.audio_controls.play(entity.mining_completed_audio);
    entity.update_mining_gfx();
  }

  this.page.canvas.entity_container.refresh_details();
};
