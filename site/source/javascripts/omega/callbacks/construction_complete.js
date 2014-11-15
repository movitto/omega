/* Omega JS Construction Complete Event Callback
 *
 * Methods here will get mixed into the CommandTracker module
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.Callbacks.construction_complete = function(event, evnt_args){
  var station     = evnt_args[1];
  var constructed = evnt_args[2];

  var pstation = this.page.entity(station.id);
  pstation._constructing = false;
  pstation.construction_percent = 0;
  pstation.resources = station.resources;
  pstation._update_resources();
  pstation.update_construction_gfx();

  // retrieve full entity from server / process
  var _this = this;
  var entity_class = constructed.json_class == 'Manufactured::Station' ?
                     Omega.Station : Omega.Ship;
  entity_class.get(constructed.id, this.page.node, function(entity){
    _this.page.process_entity(entity);
    if(_this.page.canvas.is_root(entity.system_id)){
      _this.page.audio_controls.play(pstation.construction_audio, 'complete');
    }
  });

  this.page.canvas.entity_container.refresh_details();
};
