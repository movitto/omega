/* Omega Ship Interaction Operations
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.ShipInteraction = {
  //TODO register mine/dock callbacks
  context_action : function(entity, page){
    if (page.session && this.belongs_to_user(page.session.user_id)){
      var offset = page.config.movement_offset;
          offset = (Math.random() * (offset.max - offset.min)) + offset.min;
      if (entity.json_class == "Cosmos::Entities::Asteroid" ||
          entity.json_class == "Manufactured::Station"      ||
          entity.json_class == "Cosmos::Entities::JumpGate"  )
        this._move(page, entity.location.x + offset, entity.location.y + offset, entity.location.z + offset);
      //TODO change move strat to follow
      if (entity.json_class == "Manufactured::Ship"      ||
          entity.json_class == "Cosmos::Entities::Planet" )
        this._follow(page, entity.id);
    }
  },

  /// XXX not a big fan of having this here, should eventually be moved elsewhere
  /// TODO replace w/ page.command_dialog
  dialog : function(){
    if(typeof(this._dialog) === "undefined")
      this._dialog = new Omega.UI.CommandDialog();
    return this._dialog;
  },

  _select_destination : function(page){
    var _this = this;
    var in_system = {};
    in_system['stations'] = $.grep(page.all_entities(), function(e){
      return e.json_class == 'Manufactured::Station' &&
             e.in_system(_this.system_id); }),
    in_system['ships'] = $.grep(page.all_entities(), function(e){
      return e.json_class == 'Manufactured::Ship' &&
             e.id != _this.id &&
             e.in_system(_this.system_id); }),
    in_system['asteroids'] = page.canvas.root.asteroids();
    in_system['jump_gates'] = page.canvas.root.jump_gates();

    this.dialog().show_destination_selection_dialog(page, this, in_system);
  },

  _move : function(page, x, y, z){
    /// TODO temp update local ms to stopped to stop movement in run_effects ?
    /// (or perhaps calculate new linear/rotated ms?)
    var _this = this;
    var nloc = this.location.clone();
    nloc.x = x; nloc.y = y; nloc.z = z;
    page.node.http_invoke('manufactured::move_entity', this.id, nloc,
      function(response){
        if(response.error){
          _this.dialog().clear_errors();
          _this.dialog().title = 'Movement Error';
          _this.dialog().show_error_dialog();
          _this.dialog().append_error(response.error.message);

        }else{
          _this.dialog().hide();
          _this.location.movement_strategy = response.result.location.movement_strategy;
          page.canvas.reload(_this, function(){
            _this.update_gfx();
          });
        }
      });
  },

  _follow : function(page, target_entity_id){
    var _this = this;
    // TODO parametrize distance?
    page.node.http_invoke('manufactured::follow_entity', this.id, target_entity_id, 100,
      function(response){
        if(response.error){
          _this.dialog().clear_errors();
          _this.dialog().title = 'Movement Error';
          _this.dialog().show_error_dialog();
          _this.dialog().append_error(response.error.message);

        }else{
          _this.dialog().hide();
          _this.location.movement_strategy = response.result.location.movement_strategy;
          page.canvas.reload(_this, function(){
            _this.update_gfx();
          });
        }
      });
  },

  _select_attack_target : function(page){
    var _this = this;
    var targets = $.grep(page.all_entities(), function(e){
                    return  e.json_class == 'Manufactured::Ship'    &&
                           !e.belongs_to_user(page.session.user_id) &&
                            e.location.is_within(_this.attack_distance,
                                                 _this.location)    &&
                            e.alive()
                  });
    this.dialog().show_attack_dialog(page, this, targets);
  },

  _start_attacking : function(page, evnt){
    var _this = this;
    var target = $(evnt.currentTarget).data('target');
    page.node.http_invoke('manufactured::attack_entity', this.id, target.id,
      function(response){
        if(response.error){
          _this.dialog().title = 'Attack Error';
          _this.dialog().show_error_dialog();
          _this.dialog().append_error(response.error.message);

        }else{
          _this.dialog().hide();
          _this.attacking = target;
          page.canvas.reload(_this, function(){
            _this.update_gfx();
          });
        }
      });
  },

  _select_docking_station : function(page){
    var _this = this;
    var stations = $.grep(page.all_entities(), function(e){
                     return e.json_class == 'Manufactured::Station' &&
                            e.belongs_to_user(page.session.user_id) &&
                            _this.location.is_within(e.docking_distance,
                                                     e.location);
                   });
    this.dialog().show_docking_dialog(page, this, stations);
  },

  _dock : function(page, evnt){
    var _this = this;
    var station = $(evnt.currentTarget).data('station');
    page.node.http_invoke('manufactured::dock', this.id, station.id,
      function(response){
        if(response.error){
          _this.dialog().title = 'Docking Error';
          _this.dialog().show_error_dialog();
          _this.dialog().append_error(response.error.message);

        }else{
          _this.dialog().hide();
          _this.docked_at = station;
          _this.docked_at_id = station.id;
          page.canvas.reload(_this, function(){
            _this.update_gfx();
          });
          page.canvas.entity_container.refresh();
        }
      });
  },

  _undock : function(page){
    var _this = this;
    page.node.http_invoke('manufactured::undock', this.id,
      function(response){
        if(response.error){
          _this.dialog().title = 'Undocking Error';
          _this.dialog().show_error_dialog();
          _this.dialog().append_error(response.error.message);
        }else{
          _this.docked_at = null;
          _this.docked_at_id = null;
          page.canvas.reload(_this, function(){
            _this.update_gfx();
          });
          page.canvas.entity_container.refresh();
        }
      });
  },

  _transfer : function(page){
    var _this = this;

    /// XXX assuming we are transferring to the docked station
    var station_id = this.docked_at_id;
    for(var r = 0; r < this.resources.length; r++){
      page.node.http_invoke('manufactured::transfer_resource',
        this.id, station_id, this.resources[r],
          function(response){
            if(response.error){
              _this.dialog().title = 'Transfer Error';
              _this.dialog().show_error_dialog();
              _this.dialog().append_error(response.error.message);

            }else{
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
            }
          });
    }
  },

  _select_mining_target : function(page){
    var _this = this;
    this.dialog().show_mining_dialog(page, this);

    var asteroids = this.solar_system.asteroids();
    asteroids = $.grep(asteroids, function(e){
                  return e.location.is_within(_this.mining_distance,
                                              _this.location);
                });
    for(var a = 0; a < asteroids.length; a++){
      var ast = asteroids[a];
      (function(ast){
        page.node.http_invoke('cosmos::get_resources', ast.id,
          function(response){
            if(!response.error){
              for(var r = 0; r < response.result.length; r++){
                var resource = response.result[r];
                _this.dialog().append_mining_cmd(page, _this, resource, ast);
              }
            }
          });
      })(ast);
    }
  },

  _start_mining : function(page, evnt){
    var _this = this;
    var resource = $(evnt.currentTarget).data('resource');
    var asteroid = $(evnt.currentTarget).data('asteroid');
    page.node.http_invoke('manufactured::start_mining', this.id,
      resource.id, function(response){
        if(response.error){
          _this.dialog().title = 'Mining Error';
          _this.dialog().show_error_dialog();
          _this.dialog().append_error(response.error.message);

        }else{
          _this.dialog().hide();
          _this.mining = resource;
          _this.mining_asteroid = asteroid;
          page.canvas.reload(_this, function(){
            _this.update_gfx();
          });
        }
      });
  }
}
