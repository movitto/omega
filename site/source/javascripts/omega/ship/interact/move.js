/* Omega Ship Movement Interaction Operations
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.ShipMovementInteractions = {
  entities_to_move_to : ["Cosmos::Entities::Asteroid",
                         "Manufactured::Station",
                         "Cosmos::Entities::JumpGate"],

  entities_to_follow  : ["Manufactured::Ship",
                         "Cosmos::Entities::Planet"],

  /// True/false if entity is type ship should move to
  _should_move_to : function(entity){
    return $.grep(this.entities_to_move_to,
                  function(e) { return entity.json_class == e; })[0] != null;
  },

  /// True/false if entity is type ship should follow
  _should_follow : function(entity){
    return $.grep(this.entities_to_follow,
                  function(e) { return entity.json_class == e; })[0] != null;
  },

  /// Return list of stations sharing the same system w/ the local ship
  _stations_in_same_system : function(page){
    var _this = this;
    return $.grep(page.all_entities(), function(e){
             return e.json_class == 'Manufactured::Station' &&
                    e.in_system(_this.system_id); });
  },

  /// Return a list of ships in the same system w/ the local ship.
  /// FIXME exclude entities no longer alive
  /// Note this excludes the current ship
  _ships_in_same_system : function(page){
    var _this = this;
    return $.grep(page.all_entities(), function(e){
             return e.json_class == 'Manufactured::Ship' &&
                    e.id != _this.id &&
                    e.in_system(_this.system_id); });
  },

  /// Launch dialog to ship movement destination
  _select_destination : function(page){
    var in_system = {};
    in_system['stations']   = this._stations_in_same_system(page);
    in_system['ships']      = this._ships_in_same_system(page);
    in_system['asteroids']  = page.canvas.root.asteroids();
    in_system['jump_gates'] = page.canvas.root.jump_gates();

    this.dialog().show_destination_selection_dialog(page, this, in_system);
  },

  /// Invoke ship movement command
  _move : function(page, x, y, z){
    var _this = this;
    var  nloc = this.location.clone().set(x, y, z);
    page.node.http_invoke('manufactured::move_entity', this.id, nloc,
      function(response){
        if(response.error)
          _this._move_failed(response);
        else
          _this._move_success(response, page);
      });
  },

  /// Internal callback invoked on movement failure
  _move_failed : function(response){
    this.dialog().clear_errors();
    this.dialog().title = 'Movement Error';
    this.dialog().show_error_dialog();
    this.dialog().append_error(response.error.message);
  },

  /// Internal callback invoked on successful movement
  _move_success : function(response, page){
    var _this = this;
    this.dialog().hide();
    this.location.update_ms(response.result.location.movement_strategy);
    page.canvas.reload(this, function(){
      _this.update_gfx();
    });
    page.audio_controls.play(page.audio_controls.effects.confirmation);
    page.audio_controls.play(this.movement_audio);
  },

  /// Invoke ship follow command
  _follow : function(page, target_entity_id){
    var _this = this;
    var distance = Omega.Config.follow_distance;
    page.node.http_invoke('manufactured::follow_entity', this.id,
      target_entity_id, distance, function(response){
        if(response.error)
          _this._follow_failed(response);
        else
          _this._follow_success(response, page);
      });
  },

  /// Internal callback invoked on follow failure
  _follow_failed : function(response){
    this.dialog().clear_errors();
    this.dialog().title = 'Movement Error';
    this.dialog().show_error_dialog();
    this.dialog().append_error(response.error.message);
  },

  /// Internal callback invoked on successful following
  _follow_success : function(response, page){
    var _this = this;
    this.dialog().hide();
    this.location.update_ms(response.result.location.movement_strategy);
    page.canvas.reload(this, function(){
      _this.update_gfx();
    });
  }
};
