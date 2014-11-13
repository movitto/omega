/* Omega JS Transferred To Event Callback
 *
 * Methods here will get mixed into the CommandTracker module
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.Callbacks.transferred_to = function(event, event_args){
  var src = event_args[1];
  var dst = event_args[2];

  var psrc = this.page.entity(src.id);
  var pdst = this.page.entity(dst.id);

  psrc.resources = src.resources;
  pdst.resources = dst.resources;
  psrc._update_resources();
  pdst._update_resources();

  this.page.canvas.entity_container.refresh_details();
};
