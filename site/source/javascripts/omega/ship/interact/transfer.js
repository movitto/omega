/* Omega Ship Transferring Interaction Operations
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.ShipTransferInteractions = {
  /// Invoke ship transfer operation
  _transfer : function(page){
    var _this = this;

    /// XXX assuming we are transferring to the docked station
    var station_id = this.docked_at_id;
    var resources  = this.resources.length;
    var responses  = 0;

    for(var r = 0; r < resources; r++){
      page.node.http_invoke('manufactured::transfer_resource',
        this.id, station_id, this.resources[r],
          function(response){
            responses += 1;

            if(response.error)
              _this._transfer_failed(response);
            else
              _this._transfer_success(response, page);

            if(responses == resources)
              _this._transfer_complete(page);
          });
    }
  },

  /// Internal callback invoked on transfer failed
  _transfer_failed : function(response){
    this.dialog().title = 'Transfer Error';
    this.dialog().show_error_dialog();
    this.dialog().append_error(response.error.message);
  },

  /// Internal callback invoked on transfer success
  _transfer_success : function(response, page){
    var _this = this;
    var src = response.result[0];
    var dst = response.result[1];

    _this.resources = src.resources;
    _this._update_resources();
    _this.docked_at.resources = dst.resources;
    _this.docked_at._update_resources();

    /// TODO also update local dst resources
    page.canvas.reload(_this, function(){
      _this.update_gfx();
    });
    this.refresh_details();
  },

  /// Internal callback invoked on transfer completion
  _transfer_complete : function(page){
    page.audio_controls.play(page.audio_controls.effects.confirmation);
  }
}
