/* Omega JS Command UI Components
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/dialog"

Omega.UI.CommandDialog = function(parameters){
  $.extend(this, parameters);
};

Omega.UI.CommandDialog.prototype = {
  append_error : function(message){
    $('#command_error').append(message);
  },

  show_error_dialog : function(){
    this.div_id = '#command_dialog';
    this.show();
  },

  show_destination_selection_dialog : function(page, entity){
    this.title  = 'Move Ship';
    this.div_id = '#select_destination_dialog';
    $('#dest_id').html(entity.id);
    $('#dest_x').value(Omega.Math.round_to(entity.location.x, 2));
    $('#dest_y').value(Omega.Math.round_to(entity.location.y, 2));
    $('#dest_z').value(Omega.Math.round_to(entity.location.z, 2));
    $('#command_move').click(function(evnt){
      var nx = $('#dest_x').value();
      var ny = $('#dest_y').value();
      var nz = $('#dest_z').value();
      entity._move(page, nx, ny, nz);
    });
    this.show();
  },

  show_attack_dialog : function(page, entity, targets){
    this.title  = 'Launch Attack';
    this.div_id = '#select_attack_target_dialog';
    $("#attack_id").html('Select ' + entity.id + 'target');

    var attack_cmds = [];
    for(var t = 0; t < targets.length; t++){
      var target = targets[t];
      var cmd = $("<span/>",
        {id    : 'attack_' target.id,
         class : ['cmd_attack', 'dialog_cmd'],
         text  : target.id });
      cmd.data("entity", entity);
      cmd.data("target", target);
      cmd.click(function(evnt){ entity._start_attacking(page, evnt); })

      attack_cmds.push(cmd);
    }

    $('#attack_targets').append(attack_cmds);
    this.show();
  },

  show_docking_dialog : function(page, entity, stations){
    this.title  = 'Dock Ship';
    this.div_id = '#select_docking_station_dialog';
    $('#dock_id').html('Dock ' + entity.id + 'at:');

    var dock_cmds = [];
    for(var s = 0; s < stations.length; s++){
      var station = stations[s];
      var cmd = $("<span/>",
        {id    : "dock_" + station.id,
         class : ['cmd_dock', 'dialog_cmd'],
         text  : station.id});
      cmd.data("entity", entity);
      cmd.data("station", station);
      cmd.click(function(evnt){ entity._dock(page, evnt); });

      dock_cmds.push(cmd);
    }

    $('#dock_stations').append(dock_cmds);
    this.show();
  },

  show_mining_dialog : function(page, entity){
    this.title  = 'Start Mining';
    this.div_id = '#select_mining_target_dialog';
    $('#mining_id').html('Select resource to mine with ' + entity.id);
    this.show();
  },

  append_mining_cmd : function(page, entity, resource){
    var cmd = $("<span/>",
      {id    : "mine_" + resource.id,
       class : ['cmd_mine', 'dialog_cmd'],
       text  : resource.material_id + '(' + resource.quantity + ')'});
      cmd.data("entity", entity);
      cmd.data("resource", resource);
      cmd.click(function(evnt){ entity._start_mining(page, evnt); });
    }

    $('#mining_targets').append(cmd);
  }
};

$.extend(Omega.UI.CommandDialog.prototype,
         new Omega.UI.Dialog());
