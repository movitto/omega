/* Omega JS Command Dialog
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
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

  clear_errors : function(){
    $('#command_error').empty();
  },

  show_error_dialog : function(){
    this.div_id = '#command_dialog';
    this.show();
  },

  show_destination_selection_dialog : function(page, entity, dests){
    /// Set title / div_id
    this.title  = 'Move Ship';
    this.div_id = '#select_destination_dialog';
    $('#dest_id').html('Move ' + entity.id + ' to:');

    /// Hide subsections
    $('#dest_selection_section').hide();
    $('#coords_selection_section').hide();

    /// Wire up select destination section toggle
    $('#select_destination, #select_dest_title').off('click');
    $('#select_destination, #select_dest_title').click(function(){
      $('#dest_selection_section').toggle();
    });

    /// Wire up select coordinates section toggle
    $('#select_coordinates, #select_coords_title').off('click');
    $('#select_coordinates, #select_coords_title').click(function(){
      $('#coords_selection_section').toggle();
    });

    /// Populate dest selection input w/ specified destinations
    var dest_selection = $('#dest_selection');
    dest_selection.html('<option/>');
    for(var entity_class in dests){
      /// XXX but works for now
      var title = entity_class.substr(0, entity_class.length-1);

      var entities = dests[entity_class];
      for(var e = 0; e < entities.length; e++){
        var dest = entities[e];
        var text = title + ': ' + dest.id;
        if(dest.json_class == 'Cosmos::Entities::JumpGate')
          text = title + ': ' + dest.endpoint_title();
        var option = $('<option/>', {text: text});
        option.data('id', dest.id);
        option.data('location', dest.location);
        dest_selection.append(option);
      }
    }
    dest_selection.off('change');
    dest_selection.change(function(evnt){ //wiring onChange to the select element
      /// generate new coords a random offset from location
      var loc = $(evnt.currentTarget).find(":selected").data('location');
      var offset = page.config.movement_offset;
          offset = (Math.random() * (offset.max - offset.min)) + offset.min;
      entity._move(page, loc.x + offset, loc.y + offset, loc.z + offset);
    });

    /// Set coordinates inputs to current coordinates
    /// TODO offset a bit so default movement doesn't result in 'already at location' error
    $('#dest_x').val(Omega.Math.round_to(entity.location.x, 2));
    $('#dest_y').val(Omega.Math.round_to(entity.location.y, 2));
    $('#dest_z').val(Omega.Math.round_to(entity.location.z, 2));

    /// Wire up enter key press on coordinate input fields
    var dest_fields = [$('#dest_x'), $('#dest_y'), $('#dest_z')];
    for(var d = 0; d < dest_fields.length; d++){
      dest_fields[d].off('keypress');
      dest_fields[d].keypress(function(evnt){
        var nx = $('#dest_x').val();
        var ny = $('#dest_y').val();
        var nz = $('#dest_z').val();
        if(evnt.which == 13) entity._move(page, nx, ny, nz);
      });
    }

    /// Wire up move button click
    $('#command_move').off('click');
    $('#command_move').click(function(evnt){
      var nx = $('#dest_x').val();
      var ny = $('#dest_y').val();
      var nz = $('#dest_z').val();
      entity._move(page, nx, ny, nz);
    });

    /// Show the dialog
    this.show();
  },

  show_attack_dialog : function(page, entity, targets){
    this.title  = 'Launch Attack';
    this.div_id = '#select_attack_target_dialog';
    $("#attack_id").html('Select ' + entity.id + ' target');

    var attack_cmds = [];
    for(var t = 0; t < targets.length; t++){
      var target = targets[t];
      var cmd = $("<span/>",
        {id    : 'attack_' + target.id,
         class : 'cmd_attack dialog_cmd',
         text  : target.id });
      cmd.data("entity", entity);
      cmd.data("target", target);
      cmd.click(function(evnt){
        entity._start_attacking(page, evnt);
        evnt.stopPropagation();
      })

      attack_cmds.push(cmd);
    }

    $('#attack_targets').html('');
    $('#attack_targets').append(attack_cmds);
    this.show();
  },

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
  },

  show_mining_dialog : function(page, entity){
    this.title  = 'Start Mining';
    this.div_id = '#select_mining_target_dialog';
    $('#mining_id').html('Select resource to mine with ' + entity.id);
    this.show();
  },

  append_mining_cmd : function(page, entity, resource, asteroid){
    var cmd = $("<span/>",
      {id    : "mine_" + resource.id,
       class : 'cmd_mine dialog_cmd',
       text  : resource.material_id + ' (' + resource.quantity + ')'});
    cmd.data("entity", entity);
    cmd.data("resource", resource);
    cmd.data("asteroid", asteroid);
    cmd.click(function(evnt){ entity._start_mining(page, evnt); });

    $('#mining_targets').append(cmd);
  }
};

$.extend(Omega.UI.CommandDialog.prototype,
         new Omega.UI.Dialog());
