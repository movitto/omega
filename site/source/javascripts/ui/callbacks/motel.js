/* Omega JS Motel Event Callback
 *
 * Methods here will get mixed into the CommandTracker module
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.Callbacks.motel = function(evnt, event_args){
  var entity = $.grep(this.page.all_entities(), function(entity){
                 return entity.location &&
                        entity.location.id == event_args[0].id;
               })[0];
  if(entity == null) return;
  var new_loc = new Omega.Location(event_args[0]);

  // update last moved
  entity.last_moved = new Date();

  entity.location.update(new_loc);

  if(entity.update_movement_effects) entity.update_movement_effects();

  if(this.page.canvas.is_root(entity.parent_id)){
    this.page.canvas.reload(entity, function(){
      entity.update_gfx();
    });
  }

  entity.dispatchEvent({type : 'movement', data : entity});
};
