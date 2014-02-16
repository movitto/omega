/* Omega JS Motel Event Callback
 *
 * Methods here will get mixed into the CommandTracker module
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.Callbacks.motel = function(event, event_args){
  var entity = $.grep(this.page.all_entities(), function(entity){
                 return entity.location &&
                        entity.location.id == event_args[0].id;
               })[0];
  if(entity == null) return;
  var new_loc = new Omega.Location(event_args[0]);

  // reset last moved if movement strategy changed
  if(entity.location.movement_strategy.json_class !=
     new_loc.movement_strategy.json_class)
    entity.last_moved = null;
  else
    entity.last_moved = new Date();

  entity.location = new_loc; // TODO should this just be an update?

  if(this.page.canvas.is_root(entity.parent_id)){
    this.page.canvas.reload(entity, function(){
      if(entity.update_gfx) entity.update_gfx();
    });
  }

  this.page.canvas.entity_container.refresh();
};
