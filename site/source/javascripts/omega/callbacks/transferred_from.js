/* Omega JS Transferred From Event Callback
 *
 * Methods here will get mixed into the CommandTracker module
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.Callbacks.transferred_from = function(event, event_args){
  var dst = event_args[1];
  var src = event_args[2];

  var pdst = this.page.entity(dst.id);
  var psrc = this.page.entity(src.id);

  pdst.resources = dst.resources;
  psrc.resources = src.resources;
  pdst._update_resources();
  psrc._update_resources();

  this.page.canvas.entity_container.refresh_details();
};
