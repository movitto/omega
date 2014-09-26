/* Omega Ship Mining Interaction Operations
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.ShipMiningInteractions = {
  /// Return list of asteroids which ship can mine
  _mining_targets : function(){
    var _this = this;
    return $.grep(this.solar_system.asteroids(), function(e){
      return e.location.is_within(_this.mining_distance, _this.location); });
  },

  /// Launch dialog to select ship mining target
  _select_mining_target : function(page){
    this.dialog().clear_mining_commands();
    this.dialog().show_mining_dialog(page, this);

    var asteroids = this._mining_targets();
    for(var a = 0; a < asteroids.length; a++)
      this._refresh_mining_target(asteroids[a], page);
  },

  /// Internal helper to refresh mining asteroid resources
  _refresh_mining_target : function(asteroid, page){
    var _this = this;
    page.node.http_invoke('cosmos::get_resources', asteroid.id,
      function(response){
        if(!response.error){
          for(var r = 0; r < response.result.length; r++){
            var resource = response.result[r];
            _this.dialog().append_mining_cmd(page, _this, resource, asteroid);
          }
        }
        /// FIXME shouldn't silently hide error
      });
  },

  /// Launch ship mining operation
  _start_mining : function(page, evnt){
    var _this = this;
    var resource = $(evnt.currentTarget).data('resource');
    var asteroid = $(evnt.currentTarget).data('asteroid');
    page.node.http_invoke('manufactured::start_mining', this.id,
      resource.id, function(response){
        if(response.error)
          _this._mining_failed(response);

        else
          _this._mining_success(response, page, resource, asteroid);
      });
  },

  _mining_failed : function(response){
    this.dialog().title = 'Mining Error';
    this.dialog().show_error_dialog();
    this.dialog().append_error(response.error.message);
  },

  _mining_success : function(response, page, resource, asteroid){
    var _this = this;
    this.dialog().hide();
    this.mining = resource;
    this.mining_asteroid = asteroid;
    page.canvas.reload(this, function(){
      _this.update_gfx();
    });
    page.audio_controls.play(this.mining_audio);
  }
};
