/* Omega JS Construction Failed Event Callback
 *
 * Methods here will get mixed into the CommandTracker module
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.Callbacks.construction_failed = function(event, evnt_args){
  var station       = evnt_args[1];
  var failed_entity = evnt_args[2];

  var pstation = $.grep(this.page.all_entities(),
                        function(entity){ return entity.id == station.id; })[0];

  pstation.construction_percent = 0;
  pstation.resources = station.resources;
  pstation._update_resources();

  if(this.page.canvas.is_root(pstation.parent_id)){
    this.page.canvas.reload(pstation, function(){ pstation.update_gfx(); });
    this.page.canvas.animate();
  }

  /// TODO should pop up dialog or similar w/ reason for failure

  this.page.canvas.entity_container.refresh();
};
