/* Omega JS Construction Complete Event Callback
 *
 * Methods here will get mixed into the CommandTracker module
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.Callbacks.construction_complete = function(event, evnt_args){
  var station     = evnt_args[1];
  var constructed = evnt_args[2];

  var pstation = $.grep(this.page.all_entities(),
                        function(entity){ return entity.id == station.id; })[0];

  pstation.construction_percent = 0;
  pstation.resources = station.resources;
  pstation._update_resources();

  if(this.page.canvas.is_root(pstation.parent_id)){
    this.page.canvas.reload(pstation, function(){ pstation.update_gfx(); });
    this.page.canvas.animate();
  }

  // retrieve full entity from server / process
  var _this = this;
  Omega.Ship.get(constructed.id, this.page.node, function(entity){
    _this.page.process_entity(entity);
    if(_this.page.canvas.is_root(entity.system_id)){
      /// TODO better place to put audi effect?
      _this.page.audio_controls.play('construction');
      _this.page.canvas.add(entity);
    }
  });

  this.page.canvas.entity_container.refresh();
};
