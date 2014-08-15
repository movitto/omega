/* Omega JS Callback Handler
 *
 * Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require 'ui/callback_handler'

//= require_tree './callbacks'

Omega.CallbackHandler = function(parameters){
  this.init_handlers(parameters);
};

Omega.CallbackHandler.prototype = {
  /// Supported server side events
  motel_events        : [       'motel::on_movement',
                                'motel::on_rotation',
                                'motel::changed_strategy',
                                'motel::location_stopped'],
  manufactured_events : ['manufactured::event_occurred'],
  missions_events     : [    'missions::event_occurred'],

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
  _callbacks_mission_failed        : Omega.Callbacks.mission_failed,

  all_events : function(){
    return this.motel_events.concat(this.manufactured_events)
                            .concat(this.missions_events);
  },

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

      }else if(mevnt == 'failed'){
        this._callbacks_mission_failed(evnt, event_args);
      }
    }
  }
};

$.extend(Omega.CallbackHandler.prototype, Omega.UI.CallbackHandler);

Omega.CallbackHandler.all_events = function(){
  return Omega.CallbackHandler.prototype.all_events();
};
