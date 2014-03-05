/* Omega JS Command Tracker
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require_tree './callbacks'

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
  /// Supported server side events
  motel_events        : ['motel::on_movement',
                         'motel::on_rotation',
                         'motel::changed_strategy',
                         'motel::location_stopped'],
  manufactured_events : ['manufactured::event_occurred'],
  missions_events : ['missions::event_occurred'],

  /// See 'callbacks' dir for specific event handling
  _callbacks_motel_event           : Omega.Callbacks.motel,
  _callbacks_resource_collected    : Omega.Callbacks.resource_collected,
  _callbacks_mining_stopped        : Omega.Callbacks.mining_stopped,
  _callbacks_attacked              : Omega.Callbacks.attacked,
  _callbacks_attacked_stop         : Omega.Callbacks.attacked_stop,
  _callbacks_defended              : Omega.Callbacks.defended,
  _callbacks_defended_stop         : Omega.Callbacks.defended_stop,
  _callbacks_destroyed_by          : Omega.Callbacks.destroyed_by,
  _callbacks_construction_complete : Omega.Callbacks.construction_complete,
  _callbacks_construction_failed   : Omega.Callbacks.construction_failed,
  _callbacks_partial_construction  : Omega.Callbacks.partial_construction,
  _callbacks_system_jump           : Omega.Callbacks.system_jump,
  _callbacks_mission_victory       : Omega.Callbacks.mission_victory,
  _callbacks_mission_expired       : Omega.Callbacks.mission_expired,

  /// Maps server side event notifications to local callback invokations
  _msg_received : function(evnt, event_args){
    var is_motel_event    = (this.motel_events.indexOf(evnt)        != -1);
    var is_manu_event     = (this.manufactured_events.indexOf(evnt) != -1);
    var is_missions_event = (this.missions_events.indexOf(evnt)     != -1);

    if(is_motel_event){
      this._callbacks_motel_event(evnt, event_args);

    }else if(is_manu_event){
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

      }else if(mevnt == 'construction_failed'){
        this._callbacks_construction_failed(evnt, event_args);

      }else if(mevnt == 'partial_construction'){
        this._callbacks_partial_construction(evnt, event_args);

      }else if(mevnt == 'system_jump'){
        this._callbacks_system_jump(evnt, event_args);
      }

    }else if(is_missions_event){
      var mevnt = event_args[0];
      if(mevnt == 'victory'){
        this._callbacks_mission_victory(evnt, event_args);

      }else if(mevnt == 'expired'){
        this._callbacks_mission_expired(evnt, event_args);
      }
    }
  },

  /// Track specified server event,
  /// invoking callback configured above on receiving
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
