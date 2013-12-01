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
    $('#dest_x').val(Omega.Math.round_to(entity.location.x, 2));
    $('#dest_y').val(Omega.Math.round_to(entity.location.y, 2));
    $('#dest_z').val(Omega.Math.round_to(entity.location.z, 2));
    $('#command_move').off('click');
    $('#command_move').click(function(evnt){
      var nx = $('#dest_x').val();
      var ny = $('#dest_y').val();
      var nz = $('#dest_z').val();
      entity._move(page, nx, ny, nz);
    });
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
         class : ['cmd_attack', 'dialog_cmd'],
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
         class : ['cmd_dock', 'dialog_cmd'],
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

  append_mining_cmd : function(page, entity, resource){
    var cmd = $("<span/>",
      {id    : "mine_" + resource.id,
       class : ['cmd_mine', 'dialog_cmd'],
       text  : resource.material_id + ' (' + resource.quantity + ')'});
    cmd.data("entity", entity);
    cmd.data("resource", resource);
    cmd.click(function(evnt){ entity._start_mining(page, evnt); });

    $('#mining_targets').append(cmd);
  }
};

$.extend(Omega.UI.CommandDialog.prototype,
         new Omega.UI.Dialog());

Omega.UI.CommandTracker = function(parameters){
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
    ['manufacutred::event_occurred'],

  _callbacks_motel_event : function(evnt, event_args){
    var entity = $.grep(this.page.entities, function(entity){
                   return entity.location.id == event_args[0].id;
                 })[0];
    if(entity == null) return;
    entity.location = event_args[0];

    if(this.page.canvas.root.id == entity.parent_id){
      this.page.canvas.reload(entity, function(){
        if(entity.update_gfx) entity.update_gfx();
      });
    }

    this.page.canvas.entity_container.refresh();
  },

  _callbacks_resource_collected : function(evnt, event_args){
    var ship     = event_args[2];
    var resource = event_args[3];
    var quantity = event_args[4];

    var entity = $.grep(this.page.entities,
                        function(entity){ return entity.id == ship.id; })[0];
    if(entity == null) return;
    entity.mining    = ship.mining;
    entity.resources = ship.resources;

    if(this.page.canvas.root.id == entity.parent_id){
      this.page.canvas.reload(entity, function(){
        if(entity.update_gfx) entity.update_gfx();
      });
    }

    this.page.canvas.entity_container.refresh();
  },

  _callbacks_mining_stopped : function(evnt, event_args){
    var ship     = event_args[2];
    var resource = event_args[3];
    var reason   = event_args[4];

    var entity = $.grep(this.page.entities,
                        function(entity){ return entity.id == ship.id; })[0];
    if(entity == null) return;
    entity.mining    = null;

    if(this.page.canvas.root.id == entity.parent_id){
      this.page.canvas.reload(entity, function(){
        if(entity.update_gfx) entity.update_gfx();
      });
    }

    this.page.canvas.entity_container.refresh();
  },

  _callbacks_attacked : function(evnt, event_args){
    var attacker = event_args[2];
    var defender = event_args[3];

    var pattacker = $.grep(this.page.entities,
                           function(entity){ return entity.id == attacker.id; })[0];
    var pdefender = $.grep(this.page.entities,
                           function(entity){ return entity.id == defender.id; })[0];
    if(pattacker == null || pdefender == null) return;
    pattacker.attacking    = pdefender;

    if(this.page.canvas.root.id == pattacker.parent_id){
      this.page.canvas.reload(pattacker, function(){
        if(pattacker.update_gfx) pattacker.update_gfx();
      });
    }

    this.page.canvas.entity_container.refresh();
  },

  _callbacks_attacked_stop : function(evnt, event_args){
    var attacker = event_args[2];
    var defender = event_args[3];

    var pattacker = $.grep(this.page.entities,
                           function(entity){ return entity.id == attacker.id; })[0];
    var pdefender = $.grep(this.page.entities,
                           function(entity){ return entity.id == defender.id; })[0];
    if(pattacker == null || pdefender == null) return;
    pattacker.attacking    = null;

    if(this.page.canvas.root.id == pattacker.parent_id){
      this.page.canvas.reload(pattacker, function(){
        if(pattacker.update_gfx) pattacker.update_gfx();
      });
    }
  },

  _callbacks_defended : function(evnt, event_args){
    var attacker = event_args[2];
    var defender = event_args[3];

    var pattacker = $.grep(this.page.entities,
                           function(entity){ return entity.id == attacker.id; })[0];
    var pdefender = $.grep(this.page.entities,
                           function(entity){ return entity.id == defender.id; })[0];
    if(pattacker == null || pdefender == null) return;
    pdefender.hp           = defender.hp;
    pdefender.shield_level = defender.shield_level;

    if(this.page.canvas.root.id == pdefender.parent_id){
      this.page.canvas.reload(pdefender, function(){
        if(pdefender.update_gfx) pdefender.update_gfx();
      });
    }

    this.page.canvas.entity_container.refresh();
  },

  _callbacks_defended_stop : function(evnt, event_args){
    var attacker = event_args[2];
    var defender = event_args[3];

    var pattacker = $.grep(this.page.entities,
                           function(entity){ return entity.id == attacker.id; })[0];
    var pdefender = $.grep(this.page.entities,
                           function(entity){ return entity.id == defender.id; })[0];
    if(pattacker == null || pdefender == null) return;
    pdefender.hp           = defender.hp;
    pdefender.shield_level = defender.shield_level;

    if(this.page.canvas.root.id == pdefender.parent_id){
      this.page.canvas.reload(pdefender, function(){
        if(pdefender.update_gfx) pdefender.update_gfx();
      });
    }

    this.page.canvas.entity_container.refresh();
  },

  _callbacks_destroyed_by : function(evnt, evnt_args){
    var attacker = event_args[2];
    var defender = event_args[3];

    var pattacker = $.grep(this.page.entities,
                           function(entity){ return entity.id == attacker.id; })[0];
    var pdefender = $.grep(this.page.entities,
                           function(entity){ return entity.id == defender.id; })[0];
    if(pattacker == null || pdefender == null) return;
    pattacker.attacking    = null;
    pdefender.hp           = 0;
    pdefender.shield_level = 0;

    if(this.page.canvas.root.id == pattacker.parent_id){
      this.page.canvas.reload(pattacker, function(){
        if(pattacker.update_gfx) pattacker.update_gfx();
      });
    }

    if(this.page.canvas.root.id == pdefender.parent_id){
      this.page.canvas.reload(pdefender, function(){
        if(pdefender.update_gfx) pdefender.update_gfx();
      });
    }
  },

  _callbacks_construction_complete : function(evnt, evnt_args){
    var station = eargs[2];
    var constructed = eargs[3];

    var pstation = $.grep(this.page.entities,
                          function(entity){ return entity.id == station.id; })[0];

    // retrieve full entity from server / process
    var _this = this;
    Omega.Ship.with_id(constructed.id, function(entity){
      _this.page.process_entity(entity);
      if(_this.page.canvas.root.id == entity.parent_id)
        _this.page.canvas.add(entity);
    });
  },

  _callbacks_partial_construction : function(evnt, evnt_args){
    /// TODO
  },

  track : function(evnt){
    var _this = this;
    this.page.node.clear_handlers(evnt);
    this.page.node.add_handler(evnt, function(){
      if(Omega.UI.CommandTracker.prototype.motel_events.indexOf(evnt) != -1){
        _this._callbacks_motel_event(evnt, arguments);

      }else{
        var mevnt = arguments[1];
        if(mevnt == 'resource_collected'){
          _this._callbacks_resource_collected(evnt, arguments);

        }else if(mevnt == 'mining_stopped'){
          _this._callbacks_mining_stopped(evnt, arguments);

        }else if(mevnt == 'attacked'){
          _this._callbacks_attacked(evnt, arguments);

        }else if(mevnt == 'attacked_stop'){
          _this._callbacks_attacked_stop(evnt, arguments);

        }else if(mevnt == 'defended'){
          _this._callbacks_defended(evnt, arguments);

        }else if(mevnt == 'defended_stop'){
          _this._callbacks_defended_stop(evnt, arguments);

        }else if(mevnt == 'destroyed_by'){
          _this._callbacks_destroyed_by(evnt, arguments);

        }else if(mevnt == 'construction_complete'){
          _this._callbacks_construction_complete(evnt, arguments);

        }else if(mevnt == 'partial_construction'){
          _this._callbacks_partial_construction(evnt, arguments);
        }
      }
    });
  }
};
