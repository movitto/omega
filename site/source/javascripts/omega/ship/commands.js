/* Omega Ship Command Operations
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.ShipCommands = {
  has_details : true,

  refresh_details_on : ['movement'],

  cmds : [
    { id      : 'ship_move_',
      class   : 'ship_move details_command',
      text    : 'move',
      handler : '_select_destination'      },

    { id      : 'ship_attack_',
      class   : 'ship_attack details_command',
      text    : 'attack',
      handler : '_select_attack_target'    },

    { id      : 'ship_dock_',
      class   : 'ship_dock details_command',
      text    : 'dock',
      handler : '_select_docking_station',
      display : function(ship){
                  return ship.docked_at_id == null;
                }                          },

    { id      : 'ship_undock_',
      class   : 'ship_undock details_command',
      text    : 'undock',
      handler : '_undock',
      display : function(ship){
                  return ship.docked_at_id != null;
                }                          },

    { id      : 'ship_transfer_',
      class   : 'ship_transfer details_command',
      text    : 'transfer',
      handler : '_transfer',
      display : function(ship){
                  return ship.docked_at_id != null;
                }                          },

    { id      : 'ship_mine_',
      class   : 'ship_mine details_command',
      text    : 'mine',
      handler : '_select_mining_target'    }],


  _command_details : function(page){
    //if(this.__commands) return this.__commands;

    var _this = this;
    var commands = [];
    for(var c = 0; c < Omega.Ship.prototype.cmds.length; c++){
      var cmd_data = {};
      $.extend(cmd_data, Omega.Ship.prototype.cmds[c]);

      var display  = (!cmd_data.display || cmd_data.display(this)) ? '' : 'none';
      $.extend(cmd_data, {id : cmd_data.id + this.id,
                          style : 'display: ' + display});

      var cmd = $('<span/>', cmd_data);
      cmd.data('ship', this);
      cmd.data('handler', cmd_data.handler)
      cmd.click(function(evnt){
        page.audio_controls.play(page.audio_controls.effects.command);

        var handler = $(evnt.currentTarget).data('handler');
        _this[handler](page);
      });
      commands.push(cmd);
    }

    this.__commands = commands;
    return commands;
  },

  _command_details_wrapper : function(){
    var cmds_container = $('<div/>', {id : 'ship_cmds'});
    return cmds_container;
  },

  _title_details : function(){
    var title_text = 'Ship: ' + this.id;
    var title = $('<div/>', {id : 'ship_title', text : title_text});
    return title;
  },

  _loc_details : function(){
    var loc_text = '@ ' + this.location.to_s();
    var loc = $('<div/>', {id : 'ship_loc', text : loc_text});
    return loc;
  },

  _orientation_details : function(){
    var orien_text = '> ' + this.location.orientation_s();
    var orien = $('<div/>', {id : 'ship_orientation', text : orien_text});
    return orien;
  },

  _hp_details : function(){
    var hp_text = 'HP: ' + this.hp;
    var hp = $('<div/>', {id : 'ship_hp', text : hp_text});
    return hp;
  },

  _type_details : function(){
    var type_text = 'Type: ' + this.type;
    var type = $('<div/>', {id : 'ship_type', text : type_text});
    return type;
  },

  _resource_details : function(){
    var resources = $('<div/>', {id : 'ship_resources', text : 'Resources:'});
    for(var r = 0; r < this.resources.length; r++){
      var resource = this.resources[r];
      resources.append(' ' + resource.quantity + ' of ' + resource.material_id);
    }
    return resources;
  },

  retrieve_details : function(page, details_cb){
    var details = [this._title_details(),
                   this._loc_details(),
                   this._orientation_details(),
                   this._hp_details(),
                   this._type_details()].
           concat([this._resource_details(),
                   this._command_details_wrapper()]);

    if(page.session && this.belongs_to_user(page.session.user_id))
      details[details.length-1].append(this._command_details(page));

    details_cb(details);
  },

  /// Simply refresh mutable entity properties
  refresh_details : function(){
    $('#ship_loc').html(this._loc_details().html());
    $('#ship_orientation').html(this._orientation_details().html());
    $('#ship_hp').html(this._hp_details().html());
    $('#ship_resources').html(this._resource_details().html());
  },

  // refresh commands
  refresh_cmds : function(page){
    var ship_cmds = $('#ship_cmds');
    ship_cmds.html('');
    ship_cmds.append(this._command_details(page));
  }
};
