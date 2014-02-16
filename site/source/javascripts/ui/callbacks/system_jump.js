/* Omega JS System Jump Event Callback
 *
 * Methods here will get mixed into the CommandTracker module
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.Callbacks.system_jump = function(event, evnt_args){
  var jumped     = evnt_args[1];
  var old_system = evnt_args[2];

  var in_root = this.page.canvas.is_root(jumped.system_id);
  var pentity = $.grep(this.page.all_entities(),
                       function(entity){ return entity.id == jumped.id })[0];
  var psystem = $.grep(this.page.all_entities(),
                       function(entity){ return entity.id == jumped.system_id; })[0];

  if(!pentity) pentity = Omega.convert_entity(jumped);
  pentity.update_system(psystem);

  if(in_root){
    this.page.process_entity(pentity);
    this.page.canvas.add(pentity);
  }else{
    this.page.entity(pentity.id, pentity);
  }
};
