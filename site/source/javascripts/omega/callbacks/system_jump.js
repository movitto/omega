/* Omega JS System Jump Event Callback
 *
 * Methods here will get mixed into the CommandTracker module
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.Callbacks.system_jump = function(event, evnt_args){
  var jumped     = evnt_args[1];
  var old_system = evnt_args[2];

  var in_root = this.page.canvas.is_root(jumped.system_id);
  var pentity = this.page.entity(jumped.id);
  var psystem = this.page.entity(jumped.system_id);

  if(!pentity) pentity = Omega.convert.entity(jumped);
  pentity.update_system(psystem);

  if(in_root){
    this.page.process_entity(pentity);
  }else{
    this.page.entity(pentity.id, pentity);
  }
};
