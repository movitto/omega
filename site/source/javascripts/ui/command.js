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
        var option = $('<option/>', {text : title + ': ' + dest.id});
        option.data('id', dest.id);
        option.data('location', dest.location);
        dest_selection.append(option);
      }
      dest_selection.parent().change(function(evnt){ //wiring onChange to the select element
        /// generate new coords a random offset from location
        var loc = $(evnt.currentTarget).find(":selected").data('location');
        var offset = Math.floor(Math.random() * 100) + 50; /// TODO parameterize via config
        entity._move(page, loc.x + offset, loc.y + offset, loc.z + offset);
      });
    }

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

Omega.UI.CommandTracker = function(parameters){
  this.handling = [];

  /// need handle to page to
  /// - register and clear rpc handlers with node
  /// - retrieve/update entities
  /// - process new entities
  /// - refresh entities in canvas scene
  /// - refresh canvas entity container
  this.page = null;

  $.extend(this, parameters);
};

Omega.UI.CommandTracker.prototype = {
  motel_events :
    ['motel::on_movement',
     'motel::on_rotation',
     'motel::changed_strategy',
     'motel::location_stopped'],

  manufactured_events :
    ['manufactured::event_occurred'],

  _callbacks_motel_event : function(evnt, event_args){
    var entity = $.grep(this.page.all_entities(), function(entity){
                   return entity.location &&
                          entity.location.id == event_args[0].id;
                 })[0];
    if(entity == null) return;
    var new_loc = new Omega.Location(event_args[0]);

    // reset last moved if movement strategy changed
    if(entity.location.movement_strategy.json_class !=
       new_loc.movement_strategy.json_class)
      entity.last_moved = null;
    else
      entity.last_moved = new Date();

    entity.location = new_loc; // TODO should this just be an update?

    if(this.page.canvas.is_root(entity.parent_id)){
      this.page.canvas.reload(entity, function(){
        if(entity.update_gfx) entity.update_gfx();
      });
    }

    this.page.canvas.entity_container.refresh();
  },

  _callbacks_resource_collected : function(evnt, event_args){
    var ship     = event_args[1];
    var resource = event_args[2];
    var quantity = event_args[3];

    var entity = $.grep(this.page.all_entities(),
                        function(entity){ return entity.id == ship.id; })[0];
    if(entity == null) return;
    entity.mining    = ship.mining;
    /// FIXME also need to lookup & set entity.mining_asteroid
    /// incase entity is already mining on being loaded
    entity.resources = ship.resources;
    entity._update_resources();

    if(this.page.canvas.is_root(entity.parent_id)){
      this.page.canvas.reload(entity, function(){
        if(entity.update_gfx) entity.update_gfx();
      });
    }

    this.page.canvas.entity_container.refresh();
  },

  _callbacks_mining_stopped : function(evnt, event_args){
    var ship     = event_args[1];
    var resource = event_args[2];
    var reason   = event_args[3];

    var entity = $.grep(this.page.all_entities(),
                        function(entity){ return entity.id == ship.id; })[0];
    if(entity == null) return;
    entity.mining          = null;
    entity.mining_asteroid = null;

    if(this.page.canvas.is_root(entity.parent_id)){
      this.page.canvas.reload(entity, function(){
        if(entity.update_gfx) entity.update_gfx();
      });
    }

    this.page.canvas.entity_container.refresh();
  },

  _callbacks_attacked : function(evnt, event_args){
    var attacker = event_args[1];
    var defender = event_args[2];

    var pattacker = $.grep(this.page.all_entities(),
                           function(entity){ return entity.id == attacker.id; })[0];
    var pdefender = $.grep(this.page.all_entities(),
                           function(entity){ return entity.id == defender.id; })[0];
    if(pattacker == null || pdefender == null) return;
    pattacker.attacking    = pdefender;

    if(this.page.canvas.is_root(pattacker.parent_id)){
      this.page.canvas.reload(pattacker, function(){
        if(pattacker.update_gfx) pattacker.update_gfx();
      });
    }
  },

  _callbacks_attacked_stop : function(evnt, event_args){
    var attacker = event_args[1];
    var defender = event_args[2];

    var pattacker = $.grep(this.page.all_entities(),
                           function(entity){ return entity.id == attacker.id; })[0];
    var pdefender = $.grep(this.page.all_entities(),
                           function(entity){ return entity.id == defender.id; })[0];
    if(pattacker == null || pdefender == null) return;
    pattacker.attacking    = null;

    if(this.page.canvas.is_root(pattacker.parent_id)){
      this.page.canvas.reload(pattacker, function(){
        if(pattacker.update_gfx) pattacker.update_gfx();
      });
    }
  },

  _callbacks_defended : function(evnt, event_args){
    var defender = event_args[1];
    var attacker = event_args[2];

    var pattacker = $.grep(this.page.all_entities(),
                           function(entity){ return entity.id == attacker.id; })[0];
    var pdefender = $.grep(this.page.all_entities(),
                           function(entity){ return entity.id == defender.id; })[0];
    if(pattacker == null || pdefender == null) return;
    pdefender.hp           = defender.hp;
    pdefender.shield_level = defender.shield_level;

    if(this.page.canvas.is_root(pdefender.parent_id) &&
       this.page.canvas.has(pdefender.id)){
      this.page.canvas.reload(pdefender, function(){
        if(pdefender.update_gfx) pdefender.update_gfx();
      });
    }
  },

  _callbacks_defended_stop : function(evnt, event_args){
    var defender = event_args[1];
    var attacker = event_args[2];

    var pattacker = $.grep(this.page.all_entities(),
                           function(entity){ return entity.id == attacker.id; })[0];
    var pdefender = $.grep(this.page.all_entities(),
                           function(entity){ return entity.id == defender.id; })[0];
    if(pattacker == null || pdefender == null) return;
    pdefender.hp           = defender.hp;
    pdefender.shield_level = defender.shield_level;

    if(this.page.canvas.is_root(pdefender.parent_id) &&
       this.page.canvas.has(pdefender.id)){
      this.page.canvas.reload(pdefender, function(){
        if(pdefender.update_gfx) pdefender.update_gfx();
      });
    }
  },

  _callbacks_destroyed_by : function(evnt, event_args){
    var defender = event_args[1];
    var attacker = event_args[2];

    var pattacker = $.grep(this.page.all_entities(),
                           function(entity){ return entity.id == attacker.id; })[0];
    var pdefender = $.grep(this.page.all_entities(),
                           function(entity){ return entity.id == defender.id; })[0];
    if(pattacker == null || pdefender == null) return;
    pattacker.attacking    = null;
    pdefender.hp           = 0;
    pdefender.shield_level = 0;

    if(this.page.canvas.is_root(pattacker.parent_id)){
      this.page.canvas.reload(pattacker, function(){
        if(pattacker.update_gfx) pattacker.update_gfx();
      });
    }

    if(this.page.canvas.is_root(pdefender.parent_id)){
      /// allow defender to tidy up gfx b4 removing from scene:
      pdefender.update_gfx();
      this.page.canvas.remove(pdefender);
    }
  },

  _callbacks_construction_complete : function(evnt, evnt_args){
    var station     = evnt_args[1];
    var constructed = evnt_args[2];

    var pstation = $.grep(this.page.all_entities(),
                          function(entity){ return entity.id == station.id; })[0];

    // retrieve full entity from server / process
    var _this = this;
    Omega.Ship.get(constructed.id, this.page.node, function(entity){
      _this.page.process_entity(entity);
      if(_this.page.canvas.is_root(entity.system_id))
        _this.page.canvas.add(entity);
    });

    pstation.resources = station.resources;
    pstation._update_resources();
    this.page.canvas.entity_container.refresh();
  },

  _callbacks_partial_construction : function(evnt, evnt_args){
    /// TODO
  },

  _callbacks_system_jump : function(evnt, evnt_args){
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
  },

  _msg_received : function(evnt, event_args){
    if(Omega.UI.CommandTracker.prototype.motel_events.indexOf(evnt) != -1){
      this._callbacks_motel_event(evnt, event_args);

    }else{
      var mevnt = event_args[0];
      if(mevnt == 'resource_collected'){
        this._callbacks_resource_collected(evnt, event_args);

      }else if(mevnt == 'mining_stopped'){
        this._callbacks_mining_stopped(evnt, event_args);

      }else if(mevnt == 'attacked'){
        this._callbacks_attacked(evnt, event_args);

      }else if(mevnt == 'attacked_stop'){
        this._callbacks_attacked_stop(evnt, event_args);

      }else if(mevnt == 'defended'){
        this._callbacks_defended(evnt, event_args);

      }else if(mevnt == 'defended_stop'){
        this._callbacks_defended_stop(evnt, event_args);

      }else if(mevnt == 'destroyed_by'){
        this._callbacks_destroyed_by(evnt, event_args);

      }else if(mevnt == 'construction_complete'){
        this._callbacks_construction_complete(evnt, event_args);

      }else if(mevnt == 'partial_construction'){
        this._callbacks_partial_construction(evnt, event_args);

      }else if(mevnt == 'system_jump'){
        this._callbacks_system_jump(evnt, event_args);
      }
    }
  },

  track : function(evnt){
    if(this.handling.indexOf(evnt) != -1) return;
    this.handling.push(evnt);

    var _this = this;
    this.page.node.addEventListener(evnt, function(node_evnt){
      var args = [];
      for(var a = 0; a < node_evnt.data.length; a++)
        args.push(node_evnt.data[a]);
      _this._msg_received(evnt, args);
    });
  }
};
