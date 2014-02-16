/* Omega JS Resource Collected Event Callback
 *
 * Methods here will get mixed into the CommandTracker module
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.Callbacks.resource_collected = function(event, event_args){
  var ship     = event_args[1];
  var resource = event_args[2];
  var quantity = event_args[3];

  var entity = $.grep(this.page.all_entities(),
                      function(entity){ return entity.id == ship.id; })[0];
  if(entity == null) return;
  entity.mining    = ship.mining;
  /// FIXME also need to lookup & set entity.mining_asteroid
  /// incase entity is already mining on being loaded
  entity.resources = ship.resources;
  entity._update_resources();

  if(this.page.canvas.is_root(entity.parent_id)){
    this.page.canvas.reload(entity, function(){
      if(entity.update_gfx) entity.update_gfx();
    });
  }

  this.page.canvas.entity_container.refresh();
};
