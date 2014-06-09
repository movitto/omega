/* Omega Ship Docking Interaction Operations
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.ShipDockingInteractions = {
  /// Return list of stations which ship may dock to
  _docking_targets : function(page){
    var _this = this;
    return $.grep(page.all_entities(), function(e){
             return e.json_class == 'Manufactured::Station' &&
                    e.belongs_to_user(page.session.user_id) &&
                    _this.location.is_within(e.docking_distance,
                                             e.location);
           });
  },

  /// Launch dialog to selection docking targets
  _select_docking_station : function(page){
    var stations = this._docking_targets(page);
    this.dialog().show_docking_dialog(page, this, stations);
  },

  /// Invoke ship docking command
  _dock : function(page, evnt){
    var _this = this;
    var station = $(evnt.currentTarget).data('station');
    page.node.http_invoke('manufactured::dock', this.id, station.id,
      function(response){
        if(response.error){
          _this._dock_failure(response);

        }else{
          _this._dock_success(response, page, station);
        }
      });
  },

  /// Internal callback invoked on docking failure
  _dock_failure : function(response){
    this.dialog().title = 'Docking Error';
    this.dialog().show_error_dialog();
    this.dialog().append_error(response.error.message);
  },

  /// Internal callback invoked on successful docking
  _dock_success : function(response, page, station){
    var _this = this;
    this.dialog().hide();
    this.docked_at = station;
    this.docked_at_id = station.id;
    page.canvas.reload(this, function(){
      _this.update_gfx();
    });
    this.refresh_cmds(page);
    page.audio_controls.play(this.docking_audio);
  },

  /// Invoke ship undock operation
  _undock : function(page){
    var _this = this;
    page.node.http_invoke('manufactured::undock', this.id,
      function(response){
        if(response.error)
          _this._undock_failure(response);

        else
          _this._undock_success(response, page);
      });
  },

  /// Internal callback invoked on undocking failure
  _undock_failure : function(response){
    this.dialog().title = 'Undocking Error';
    this.dialog().show_error_dialog();
    this.dialog().append_error(response.error.message);
  },

  /// Internal callback invoked on successfull undocking
  _undock_success : function(response, page){
    var _this = this;
    this.docked_at = null;
    this.docked_at_id = null;
    page.canvas.reload(_this, function(){
      _this.update_gfx();
    });
    this.refresh_cmds(page);
  }
};
