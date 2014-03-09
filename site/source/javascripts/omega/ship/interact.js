/* Omega Ship Interaction Operations
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/command_dialog"

// TODO split up into submodules

Omega.ShipInteraction = {
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

  /// Launch ship context action to perform operation with ship depending on
  /// context provided by specified target entity
  context_action : function(entity, page){
    if(!page.session || !this.belongs_to_user(page.session.user_id)) return;

    if(this._should_move_to(entity)){
      var offset = page.config.movement_offset;
          offset = (Math.random() * (offset.max - offset.min)) + offset.min;
      this._move(page, entity.location.x + offset,
                       entity.location.y + offset,
                       entity.location.z + offset);

    }else if(this._should_follow(entity)){
      this._follow(page, entity.id);

    } /// TODO else if(should_mine, should_dock)
  },

  /// TODO centralize command dialog
  dialog : function(){
    if(typeof(this._dialog) === "undefined")
      this._dialog = new Omega.UI.CommandDialog();
    return this._dialog;
  },

  /// Return list of stations sharing the same system w/ the local ship
  _stations_in_same_system : function(page){
    var _this = this;
    return $.grep(page.all_entities(), function(e){
             return e.json_class == 'Manufactured::Station' &&
                    e.in_system(_this.system_id); });
  },

  /// Return a list of ships in the same system w/ the local ship.
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
  },

  /// Return list of valid attack targets n vicinity
  _attack_targets : function(page){
    var _this = this;
    return $.grep(page.all_entities(), function(e){
             return  e.json_class == 'Manufactured::Ship'    &&
                    !e.belongs_to_user(page.session.user_id) &&
                     e.location.is_within(_this.attack_distance,
                                          _this.location)    &&
                     e.alive()
           });
  },

  /// Launch dialog to select ship attack target
  _select_attack_target : function(page){
    var _this = this;
    var targets = this._attack_targets(page);
    this.dialog().show_attack_dialog(page, this, targets);
  },

  /// Invoke ship attack command
  _start_attacking : function(page, evnt){
    var _this  = this;
    var target = $(evnt.currentTarget).data('target');
    page.node.http_invoke('manufactured::attack_entity', this.id, target.id,
      function(response){
        if(response.error)
          _this._attack_failed(response);
        else
          _this._attack_success(response, page, target);
      });
  },

  /// Interal callback invoked on attack failure
  _attack_failed : function(response){
    this.dialog().title = 'Attack Error';
    this.dialog().show_error_dialog();
    this.dialog().append_error(response.error.message);
  },

  /// Internal callback invoked on successful attack
  _attack_success : function(response, page, target){
    var _this = this;
    this.dialog().hide();
    this.attacking = target;
    page.canvas.reload(_this, function(){
      _this.update_gfx();
    });
  },

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
    page.canvas.reload(_this, function(){
      _this.update_gfx();
    });
    page.canvas.entity_container.refresh();
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
    page.canvas.entity_container.refresh();
  },

  /// Invoke ship transfer operation
  _transfer : function(page){
    var _this = this;

    /// XXX assuming we are transferring to the docked station
    var station_id = this.docked_at_id;
    for(var r = 0; r < this.resources.length; r++){
      page.node.http_invoke('manufactured::transfer_resource',
        this.id, station_id, this.resources[r],
          function(response){
            if(response.error)
              _this._transfer_failed(response);
            else
              _this._transfer_success(response, page);
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
    page.canvas.entity_container.refresh();
  },

  /// Return list of asteroids which ship can mine
  _mining_targets : function(){
    var _this = this;
    return $.grep(this.solar_system.asteroids(), function(e){
      return e.location.is_within(_this.mining_distance, _this.location); });
  },

  /// Launch dialog to select ship mining target
  _select_mining_target : function(page){
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
  }
}
