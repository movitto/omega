/* Omega Ship Command Operations
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.ShipCommands = {
  /// TODO only display cmds if entity is alive
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


  retrieve_details : function(page, details_cb){
    var title = 'Ship: ' + this.id;
    var loc   = '@ ' + this.location.to_s();
    var orien = '> ' + this.location.orientation_s();
    var hp    = 'HP: ' + this.hp;

    var resources = ['Resources:'];
    for(var r = 0; r < this.resources.length; r++){
      var resource = this.resources[r];
      resources.push(resource.quantity + ' of ' + resource.material_id);
    }

    var details = [title, loc, orien, hp].concat(resources);
    for(var d = 0; d < details.length; d++) details[d] += '<br/>';

    if(page.session && this.belongs_to_user(page.session.user_id)){
      var cmds = this._create_commands(page);
      details = details.concat(cmds);
    }

    details_cb(details);
  },

  _create_commands : function(page){
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
        var handler = $(evnt.currentTarget).data('handler');
        _this[handler](page);
      });
      commands.push(cmd);
    }

    return commands;
  }
};
