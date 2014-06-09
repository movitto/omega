/* Omega JS Docking Dialog Operations
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.UI.DockingDialog = {
  show_docking_dialog : function(page, entity, stations){
    this.title  = 'Dock Ship';
    this.div_id = '#select_docking_station_dialog';
    $('#dock_id').html('Dock ' + entity.id + ' at:');

    var dock_cmds = [];
    for(var s = 0; s < stations.length; s++){
      var station = stations[s];
      var cmd = $("<span/>",
        {id    : "dock_" + station.id,
         class : 'cmd_dock dialog_cmd',
         text  : station.id});
      cmd.data("entity", entity);
      cmd.data("station", station);
      cmd.click(function(evnt){
        entity._dock(page, evnt);
        evnt.stopPropagation();
      });

      dock_cmds.push(cmd);
    }

    $('#dock_stations').append(dock_cmds);
    this.show();
  }
};
