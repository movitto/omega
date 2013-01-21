/* Omega Client Commands
 *
 * Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

require('javascripts/omega/client.js');
require('javascripts/omega/user.js');
require('javascripts/omega/renderer.js');
require('javascripts/omega/entity.js');

/////////////////////////////////////// Helper Methods

/* Generate a function to handle the result of an rjr
 * operation by storing the result and invoking the registered
 * success/failure callbacks
 */
function omega_callback(success_callback, error_callback){
  return function(result, error){
    // only invoke client callback on success (assuming errors handled elsewhere)
    if(error == null && typeof(result) == "object"){
      var unpack = false;

      // ensure result is an array to iterate over
      if(Object.prototype.toString.call( result ) !== '[object Array]'){
        result = [result];
        unpack = true;
      }

      // register entities w/ the register
      for(var ei in result){
        if(result[ei] != null)
          result[ei] = convert_entity(result[ei]);
      }

      // invoke client callback
      if(success_callback != null)
        success_callback(unpack ? result[0] : result);

    }else if(error != null && error_callback != null){
      error_callback(error);

    }
  };
}

/////////////////////////////////////// Omega Event Namespace

var OmegaEvent = {

  /////////////////////////////////////// Movement Event

  movement : {
    handled : false,

    handle  : function(){
      if(OmegaEvent.movement.handled) return;
      OmegaEvent.movement.handled = true;

      $omega_node.add_request_handler('motel::on_movement', function(loc){
        var entity = $omega_registry.select([function(e){ return e.location &&
                                                                 e.location.id == loc.id }])[0];

        entity.location.x = loc.x;
        entity.location.y = loc.y;
        entity.location.z = loc.z;

        // XXX hack if scene changed remove callbacks
        if($omega_scene.get_root().location.id != entity.location.parent_id){
          $omega_node.ws_request('motel::remove_callbacks', loc.id, null);

        }else{
          entity.moved();
          $omega_scene.animate();
        }

      });
    },

    subscribe : function(location_id, distance){
      OmegaEvent.movement.handle();
      $omega_node.ws_request('motel::track_movement', location_id, distance, null);
    }
  },

  /////////////////////////////////////// Mining Events

  mining : {
    handled : false,

    handle : function(){
      if(OmegaEvent.mining.handled) return;
      OmegaEvent.mining.handled = true;

      $omega_node.add_request_handler('manufactured::event_occurred', function(p0, p1, p2, p3){
        var evnt = p0;
        if(evnt == "resource_collected"){
          var ship = p1; var resource_source = p2; var quantity = p3;
          convert_entity(ship);
          $omega_scene.animate();

        }else if(evnt == "mining_stopped"){
          var reason = p1; var ship = p2;
          // XXX hack serverside ship.mining might not be nil at this point
          ship.mining  = null;
          convert_entity(ship);
          $omega_scene.animate();

        }
      });
    },

    subscribe : function(ship_id){
      OmegaEvent.mining.handle();
      $omega_node.ws_request('manufactured::subscribe_to', ship_id, 'resource_collected', null);
      $omega_node.ws_request('manufactured::subscribe_to', ship_id, 'mining_stopped',     null);
    }
  },

  /////////////////////////////////////// Attacked Events

  attacked : {
    handled : false,

    handle : function(){
      if(OmegaEvent.attacked.handled) return;
      OmegaEvent.attacked.handled = true;

      $omega_node.add_request_handler('manufactured::event_occurred', function(p0, p1, p2, p3){
        var evnt = p0;
        if(evnt == "attacked"){
          var attacker = p1; var defender = p2;
          attacker.attacking = defender;
          convert_entity(attacker); convert_entity(defender);
          $omega_scene.animate();

        }else if(evnt == "attacked_stop"){
          var attacker = p1; var defender = p2;
          attacker.attacking = null;
          convert_entity(attacker); convert_entity(defender);
          $omega_scene.animate();

        }
      });
    },

    subscribe : function(ship_id){
      OmegaEvent.attacked.handle();
      $omega_node.ws_request('manufactured::subscribe_to', ship_id, 'attacked',      null);
      $omega_node.ws_request('manufactured::subscribe_to', ship_id, 'attacked_stop', null);
    }
  },

  /////////////////////////////////////// Defended Events

  defended : {
    handled : false,

    handle : function(){
      if(OmegaEvent.defended.handled) return;
      OmegaEvent.defended.handled = true;

      $omega_node.add_request_handler('manufactured::event_occurred', function(p0, p1, p2, p3){
        var evnt = p0;
        if(evnt == "defended"){
          var attacker = p1; var defender = p2;
          attacker.attacking = defender;
          convert_entity(attacker); convert_entity(defender);
          $omega_scene.animate();

        }else if(evnt == "defended_stop"){
          var attacker = p1;
          var defender = p2;
          attacker.attacking = null;
          convert_entity(attacker); convert_entity(defender);
          $omega_scene.animate();

        }else if(evnt == "destroyed"){
          var attacker = p1;
          var defender = p2;
          attacker.attacking = null;
          convert_entity(attacker); convert_entity(defender);
          $omega_scene.remove(defender.id);
          $omega_scene.animate();

        }
      });
    },

    subscribe : function(ship_id){
      OmegaEvent.defended.handle();
      $omega_node.ws_request('manufactured::subscribe_to', ship_id, 'defended',      null);
      $omega_node.ws_request('manufactured::subscribe_to', ship_id, 'defended_stop', null);
      $omega_node.ws_request('manufactured::subscribe_to', ship_id, 'destroyed',     null);
    }
  }

}


/////////////////////////////////////// Omega Command Namespace

var OmegaCommand = {

  /////////////////////////////////////// Login User Command

  /* Log the user into the server
   */
  login_user : {

    /* Execute the login_user command.
     *
     * @param {Users::User} user to log into the server
     * @param {Callback} login_callback function to invoke w/ session on login
     * @param {Callback} error_callback function to invoke if user could not be logged in
     */
    exec : function(user, login_callback, error_callback){
      $omega_node.web_request('users::login', user,
                              omega_callback(login_callback, error_callback));
    }

  },

  /////////////////////////////////////// Logout User Command

  /* Log the user out of the server
   */
  logout_user : {

    /* Execute the logout_user command.
     *
     * @param {String} session_id id of session to use when logging out user
     * @param {Callback} logout_callback function to invoke on logout
     */
    exec : function(session_id, logout_callback){
      $omega_node.web_request('users::logout', session_id,
                              omega_callback(logout_callback, logout_callback));
    }

  },

  /////////////////////////////////////// Update User Command

  /* Update the user on the server
   */
  update_user : {

    /* Execute the update_user command.
     *
     * @param {Users::User} user to update on the server
     * @param {Callback} callback function to invoke when user is updated
     */
    exec : function(user, callback){
      $omega_node.web_request('users::update_user', user, omega_callback(callback));
    }

  },


  /////////////////////////////////////// Trigger Jump Gate Command

  /* Detect ships around jump gate and
   * invoke jump operation on them
   */
  trigger_jump_gate : {

    /* Execute the trigger_jump_gate command.
     *
     * @param {Cosmos::JumpGate} jg jump gate to trigger
     * @param {Callback} triggered_callback function to invoke after jump gate is triggered
     */
    exec : function(jg, triggered_callback){
      // get local and remote systems
      var source   = $omega_registry.select([function(e) { return e.json_class == "Cosmos::SolarSystem" &&
                                                                  e.location.id == jg.location.parent_id; }]);
      var endpoint = $omega_registry.select([function(e) { return e.id == jg.endpoint; }]);

      // if remote system isn't loaded yet, load
      if(endpoint.length == 0){
        OmegaSolarSystem.cached(jg.endpoint, function(sys) { OmegaCommand.trigger_jump_gate.exec(jg, triggered_callback) });
        return;
      }

      // move entities within triggering distance of gate
      var entities = $omega_registry.select([function(e) { return e.json_class == "Manufactured::Ship" &&
                                                                  e.user_id    == $user_id             &&
                                                                  e.location.is_within(jg.trigger_distance, jg.location); }]);
      endpoint = endpoint[0];
      for(var entity in entities){
        entity = entities[entity];
        OmegaCommand.jump_ship.exec(entity, endpoint);

        // redraw scene w/out location (XXX don't like doing this here)
        $omega_scene.remove(entity.id);
        $omega_scene.animate();
      }

      // XXX might be invoked before all jump_ship commands return results
      if(triggered_callback){
        triggered_callback(jg);
      }
    },

    /* Setup the trigger_jump_gate command */
    init : function(){
      $('#ship_trigger_jg').live('click', function(e){
        var selected = $omega_registry.get($omega_scene.selection.selected());
        OmegaCommand.trigger_jump_gate.exec(selected);
      });
    }

  },

  /////////////////////////////////////// Jump Ship Command

  /* Invoke omega server side manufactured::move_entity 
   * operation to move ship inbetween systems
   */
  jump_ship : {
    /* Execute the jump ship command
     *
     * @param {Manufactured::Ship} ship to jump
     * @param {Cosmos::SolarSystem} sys system to jump to
     */
    exec : function(ship, sys){
      ship.location.parent_id = sys.location.id;
      ship.system_name = sys.name;
      $omega_node.web_request('manufactured::move_entity', ship.id, ship.location, null);
    }

  },

  /////////////////////////////////////// Move Ship Command

  /* Invoke omega server side manufactured::move_entity 
   * operation to move ship in a system
   */
  move_ship : {

    /* Execute the move ship command
     *
     * @param {Manufactured::Ship} ship ship to move
     * @param {Float} x x coordinate to move ship to
     * @param {Float} y y coordinate to move ship to
     * @param {Float} z z coordinate to move ship to
     */
    exec : function(ship, x, y, z){
      var loc = ship.location.clone();
      loc.x = x; loc.y = y; loc.z = z;

      OmegaEvent.movement.subscribe(loc.id, 20);
      $omega_node.web_request('manufactured::move_entity', ship.id, loc, null);
    },

    /* Display dialog w/ coordinate selection
     */
    pre_exec : function(ship){
      // TODO drop down select box w/ all entities in the local system
      var text = "<div class='dialog_row'>"+ship.id+"</div>"+
                 "<div class='dialog_row'>X: <input id='dest_x' type='text' value='"+roundTo(ship.location.x,2)+"'/></div>" +
                 "<div class='dialog_row'>Y: <input id='dest_y' type='text' value='"+roundTo(ship.location.y,2)+"'/></div>" +
                 "<div class='dialog_row'>Z: <input id='dest_z' type='text' value='"+roundTo(ship.location.z,2)+"'/></div>" +
                 "<div class='dialog_row'><input type='button' value='move' id='ship_move_to' /></div>";
      $omega_dialog.show('Move Ship', null, text);
    },

    /* Setup the move_ship command */
    init : function(){
      $('#ship_select_move').live('click', function(e){
        var selected = $omega_registry.get($omega_scene.selection.selected());
        OmegaCommand.move_ship.pre_exec(selected);
      });

      $('#ship_move_to').live('click', function(e){
        $omega_dialog.hide();
        var selected = $omega_registry.get($omega_scene.selection.selected());
        OmegaCommand.move_ship.exec(selected,
                                    $('#dest_x').val(),
                                    $('#dest_y').val(),
                                    $('#dest_z').val());
      });
    }

  },

  /////////////////////////////////////// Launch Attack Command

  /* Invoke omega server side manufactured::attack_entity 
   * operation to attack specified entity
   */
  launch_attack : {

    /* Execute the launch attack command
     *
     * @param {Manufactured::Ship} attacker ship to launch attack with
     * @param {String} defender_id id of ship we are attacking
     */
    exec : function(attacker, defender_id){
      OmegaEvent.attacked.subscribe(attacker.id);
      $omega_node.web_request('manufactured::attack_entity',
                              attacker.id, defender_id, omega_callback());
    },

    /* Display dialog to select attack target
     */
    pre_exec : function(ship){
      // TODO also list stations
      var entities = $omega_registry.select([function(e) { return e.json_class == 'Manufactured::Ship' &&
                                                                  e.user_id    != $user_id             &&
                                                                  e.location.is_within(ship.attack_distance, ship.location) }]);
      var text = "<div class='dialog_row'>Select "+ship.id+" target</div>";
      for(var entity in entities){
        entity = entities[entity];
        text += "<div class='dialog_row dialog_clickable_row ship_launch_attack'>" + entity.id + "</div>";
      }
      $omega_dialog.show('Launch Attack', null, text);
    },

    /* Setup the launch_attack command */
    init : function(){
      $('#ship_select_target').live('click', function(e){
        var selected = $omega_registry.get($omega_scene.selection.selected());
        OmegaCommand.launch_attack.pre_exec(selected);
      });

      $('.ship_launch_attack').live('click', function(e){
        $omega_dialog.hide();
        var selected = $omega_registry.get($omega_scene.selection.selected());
        OmegaCommand.launch_attack.exec(selected, $(e.currentTarget).html());
      });
    }
  },

  /////////////////////////////////////// Dock Ship Command

  /* Invoke omega server side manufactured::dock 
   * operation to dock the ship at the specified station
   */
  dock_ship : {

    /* Execute the dock ship command
     *
     * @param {Manufactured::Ship} ship ship to dock
     * @param {String} station_id id of the station we are docking
     */
    exec : function(ship, station_id){
      $omega_node.web_request('manufactured::dock', ship.id, station_id,
                              omega_callback(function(ship){
                                $omega_scene.reload(ship);
                              }));
    },

    /* Display dialog to select station to dock at
     */
    pre_exec : function(ship){
      var entities = $omega_registry.select([function(e) { return e.json_class == 'Manufactured::Station' &&
                                                                  e.location.is_within(100, ship.location) }])

      var text = "<div class='dialog_row'>Dock "+ship.id+" at</div>";
      for(var entity in entities){
        entity = entities[entity];
        text += "<div class='dialog_row dialog_clickable_row ship_dock_at'>" + entity.id + "</div>";
      }
      $omega_dialog.show('Dock Ship', null, text);
    },

    /* Setup the dock_ship command */
    init : function(){
      $('#ship_select_dock').live('click', function(e){
        var selected = $omega_registry.get($omega_scene.selection.selected());
        OmegaCommand.dock_ship.pre_exec(selected);
      });

      $('.ship_dock_at').live('click', function(e){
        var selected = $omega_registry.get($omega_scene.selection.selected());
        OmegaCommand.dock_ship.exec(selected, $(e.currentTarget).html());

        $omega_dialog.hide();
        $('#ship_select_dock').hide();
        $('#ship_undock').show();
        $('#ship_select_transfer').show();
      });
    }

  },

  /////////////////////////////////////// Undock Ship Command

  /* Invoke omega server side manufactured::undock 
   * operation to undock the specified ship
   *
   */
  undock_ship : {

    /* Execute the undock ship command
     *
     * @param {Manufactured::Ship} ship ship to undock
     */
    exec : function(ship){
      $omega_node.web_request('manufactured::undock', ship.id,
                              omega_callback(function(ship) { 
                                $omega_scene.reload(ship);
                              }));
    },

    /* Setup the undock_ship command */
    init : function(){
      $('#ship_undock').live('click', function(e){
        var selected = $omega_registry.get($omega_scene.selection.selected());
        OmegaCommand.undock_ship.exec(selected);
        $('#ship_select_dock').show();
        $('#ship_undock').hide();
        $('#ship_select_transfer').hide();
      });
    }
  },

  /////////////////////////////////////// Transfer Resources Command

  /* Invoke omega server side manufactured::transfer_resource 
   * operation to transfer all resources for the specified ship
   * to the specified station
   *
   */
  transfer_resources : {

    /* Execute the transfer resources command
     *
     * @param {Manufactured::Ship} ship ship to transfer resources from
     * @param {String} station_id id of station to transfer resources to
     */
    exec : function(ship, station_id){
      for(var r in ship.resources){
        $omega_node.web_request('manufactured::transfer_resource', ship.id, station_id, r, ship.resources[r], omega_callback())
      }
    },

    /* Display dialog to select station to transfer resources to
     */
    pre_exec : function(ship){
      var entities = $omega_registry.select([function(e){ return e.json_class == "Manufactured::Station" &&
                                                                 e.location.is_within(100, ship.location); }]);
      var text = "<div class='dialog_row'>Transfer Resources from "+ship.id+" to</div>";
      for(var entity in entities){
        entity = entities[entity];
        text += "<div class='dialog_row dialog_clickable_row ship_transfer'>" + entity.id + "</div>";
      }
      $omega_dialog.show('Transfer Resources', null, text);
    },

    /* Setup the transfer_resources command */
    init : function(){
      $('#ship_select_transfer').live('click', function(e){
        var selected = $omega_registry.get($omega_scene.selection.selected());
        OmegaCommand.transfer_resources.pre_exec(selected);
      });

      $('.ship_transfer').live('click', function(e){
        $omega_dialog.hide();
        var selected = $omega_registry.get($omega_scene.selection.selected());
        OmegaCommand.transfer_resources.exec(selected, $(e.currentTarget).html());
      });
    }

  },

  /////////////////////////////////////// Start Mining Command

  /* Invoke omega server side manufactured::start_mining 
   * operation to start mining the specified resource using
   * the specified ship
   *
   */
  start_mining : {

    /* Execute the start mining command
     *
     * @param {Manufactured::Ship} ship ship to use to start mining
     * @param {String} resource_source_id id of the resource source to starting mining
     */
    exec : function(ship, resource_source_id){
      var ids = resource_source_id.split('_');
      var entity_id = ids[0];
      var resource_id  = ids[1];

      OmegaEvent.mining.subscribe(ship.id);
      $omega_node.web_request('manufactured::start_mining',
                              ship.id, entity_id, resource_id,
                              omega_callback(function(){
                                $omega_scene.animate();
                              }));
    },

    /* Display dialog to select mining target
     */
    pre_exec : function(ship){
      var entities = $omega_registry.select([function(e){ return e.json_class == "Cosmos::Asteroid" &&
                                                                 e.location.is_within(100, ship.location); }]);
      var text = "<div class='dialog_row'>Select resource to mine w/"+ship.id+"</div>";
      $omega_dialog.show('Start Mining', null, text);
    
      for(var entity in entities){
        entity = entities[entity];
        $omega_node.web_request('cosmos::get_resource_sources', entity.name, function(resource_sources, error){
          if(error == null){
            var details = "";
            for(var r in resource_sources){
              var res = resource_sources[r];
              details += "<div class='dialog_row dialog_clickable_row ship_start_mining' id='start_mining_rs_" + res.entity.name + "_" + res.resource.id + "'>" + res.resource.type + ": " + res.resource.name + " (" + res.quantity + ")</div>";
            }
            $omega_dialog.append(details);
          }
        });
      }
    },

    /* Setup the start_mining command */
    init : function(){
      $('#ship_select_mine').live('click', function(e){
        var selected = $omega_registry.get($omega_scene.selection.selected());
        OmegaCommand.start_mining.pre_exec(selected);
      });

      $('.ship_start_mining').live('click', function(e){
        $omega_dialog.hide();
        var selected = $omega_registry.get($omega_scene.selection.selected());
        var rsid = e.currentTarget.id.replace('start_mining_rs_', '');
        OmegaCommand.start_mining.exec(selected, rsid);
      });
    }
  },

  /////////////////////////////////////// Construct Entity Command

  construct_entity : {

    /* Invoke omega server side manufactured::construct 
     * operation to construct entity using the specified station
     *
     * @param {Manufactured::Station} station station to use to construct entity
     */
    exec : function(station){
      $omega_node.web_request('manufactured::construct_entity', station.id, 'Manufactured::Ship',
                              omega_callback(function(entities){
                                // add constructed entity to scene
                                $omega_scene.add_entity(entities[1]);
                                $omega_scene.animate();
                              }));
    },

    /* Setup the construct_entity command */
    init : function(){
      $('#station_select_construction').live('click', function(e){
        var selected = $omega_registry.get($omega_scene.selection.selected());
        OmegaCommand.construct_entity.exec(selected);
      });
    }
  },

  /////////////////////////////////////// Command initialization

  init : function(){
    // setup command controls
    for(var cmd in OmegaCommand){
      if(OmegaCommand[cmd].init)
        OmegaCommand[cmd].init();
    }
  }
}


/////////////////////////////////////// Omega Query Namespace

var OmegaQuery = {

  /* Invoke omega server side manufactured::get_entities 
   * operation to retrieved all entities
   *
   * @param {Callback} callback function to invoke w/ array of galaxies retrieved
   */
  all_entities : function(callback){
    $omega_node.web_request('manufactured::get_entity', omega_callback(callback));
  },

  /* Invoke omega server side manufactured::get_entities 
   * operation to retrieved entities owned by specified user
   *
   * @param {String} user_id id of the user to retrieve entities owned by
   * @param {Callback} callback function to invoke w/ array of entities retrieved
   */
  entities_owned_by : function(user_id, callback){
    $omega_node.web_request('manufactured::get_entities', 'owned_by', user_id, omega_callback(callback));
  },
  
  /* Invoke omega server side manufactured::get_entities 
   * operation to retrieved entities under the specified system
   *
   * @param {String} system_name name of the system to retrieve entities under
   * @param {Callback} callback function to invoke w/ array of entities retrieved
   */
  entities_under : function(system_name, callback){
    $omega_node.web_request('manufactured::get_entities', 'under', system_name, omega_callback(callback));
  },
  
  
  /* Invoke omega server side manufactured::get_entity
   * operation to retrieve entity with the specified id
   *
   * @param {String} entity_id id of the entity to retrieve
   * @param {Callback} callback function to invoke w/ entity retrieved
   */
  entity_with_id : function(entity_id, callback){
    $omega_node.web_request('manufactured::get_entities', 'with_id', entity_id, omega_callback(callback));
  },
  
  /* Invoke omega server side cosmos::get_entities 
   * operation to retrieve all galaxies
   *
   * @param {Callback} callback function to invoke w/ array of galaxies retrieved
   */
  all_galaxies : function(callback){
    $omega_node.web_request('cosmos::get_entity', 'of_type', 'Cosmos::Galaxy', omega_callback(callback));
  },

  /* Invoke omega server side cosmos::get_entities 
   * operation to retrieve galaxy with the specified name
   *
   * @param {String} galaxy name of the system to retrieve
   * @param {Callback} callback function to invoke w/ galaxy when retrieved
   */
  galaxy_with_name : function(galaxy_name, callback){
    $omega_node.web_request('cosmos::get_entity', 'with_name', galaxy_name, omega_callback(callback));
  },
  
  /* Invoke omega server side cosmos::get_entity
   * operation to retrieve system with the specified name
   *
   * @param {String} system_name name of the system to retrieve
   * @param {Callback} callback function to invoke w/ system when retrieved
   */
  system_with_name : function(system_name, callback){
    $omega_node.web_request('cosmos::get_entity', 'with_name', system_name, omega_callback(callback));
  },
  
  /* Invoke omega server side cosmos::get_resource_sources 
   * operation to retrieve resource sources associated with the specified 
   * entity
   *
   * @param {String} entity_name name of the entity to retireve associated resource sources
   * @param {Callback} callback function to invoke w/ resource sources when retrieved
   */
  resource_sources : function(entity_name, callback){
    $omega_node.web_request('cosmos::get_resource_sources', entity_name, omega_callback(callback));
  },
  
  /* Invoke omega server side users::get_entity
   * operation to retrieve all users
   *
   * @param {Callback} callback function to invoke w/ array of users retrieved
   */
  all_users : function(callback){
    $omega_node.web_request('users::get_entity', 'of_type', 'Users::User', omega_callback(callback));
  },

  /* Invoke omega server side users::get_entity
   * operation to retrieve user with the specified id
   *
   * @param {String} user_id id of the user to retrieve
   * @param {Callback} callback function to invoke w/ user when retrieved
   */
  user_with_id : function(user_id, callback){
    $omega_node.web_request('users::get_entity', 'with_id', user_id, omega_callback(callback));
  }

}
