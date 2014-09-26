/* Omega JS Resource Collected Event Callback
 *
 * Methods here will get mixed into the CommandTracker module
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.Callbacks.resource_collected = function(event, event_args){
  var ship     = event_args[1];
  var resource = event_args[2];
  var quantity = event_args[3];

  var entity = $.grep(this.page.all_entities(),
                      function(entity){ return entity.id == ship.id; })[0];
  if(entity == null) return;

  if(!entity.is_mining()){
    var ast = this.page.asteroid_with_resource(ship.mining.id);
    var resource = ast.resource(ship.mining.id);
    entity.set_mining(resource, ast);
  }

  entity.resources = ship.resources;
  entity._update_resources();
  entity.update_mining_gfx();
  this.page.canvas.entity_container.refresh_details();
};
