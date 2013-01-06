/* Omega Client Commands
 *
 * Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

/////////////////////////////////////// public methods

/* Detect ships around jump gate and
 * invoke jump operation on them
 *
 * @param {Cosmos::JumpGate} jg jump gate to trigger
 */
function trigger_jump_gate(jg){
  // get local and remote systems
  var source   = $tracker.matching_entities({location : jg.location.parent_id})[0];
  var endpoint = $tracker.matching_entities({id : jg.endpoint});

  // if remote system isn't loaded yet, load
  if(endpoint.length == 0){
    $tracker.load('Cosmos::SolarSystem', jg.endpoint,
                  function(sys) { trigger_jump_gate(jg) });
    return;
  }

  // move entities within triggering distance of gate
  var entities = $tracker.matching_entities({type : "Manufactured::Ship", owned_by : $user_id,
                                             within : [jg.trigger_distance, jg.location]});
  endpoint = endpoint[0];
  for(var entity in entities){
    entity = entities[entity];
    omega_jump_ship(entity, endpoint);

    // redraw scene w/out location (XXX don't like doing this here)
    $scene.remove(entity.id);
    $scene.animate();
  }

  // update systems
  source.update_children();
  endpoint.update_children();
}

/* Invoke omega server side manufactured::move_entity 
 * operation to move ship inbetween systems
 *
 * @param {Manufactured::Ship} ship to jump
 * @param {Cosmos::SolarSystem} sys system to jump to
 */
function omega_jump_ship(ship, sys){
  ship.location.parent_id = sys.location.id;
  ship.system_name = sys.name;
  $omega_node.web_request('manufactured::move_entity', ship.id, ship.location, null);
}

/* Invoke omega server side manufactured::move_entity 
 * operation to move ship in a system
 *
 * @param {Manufactured::Ship} ship ship to move
 * @param {Float} x x coordinate to move ship to
 * @param {Float} y y coordinate to move ship to
 * @param {Float} z z coordinate to move ship to
 */
function omega_move_ship_to(ship, x, y, z){
  $omega_dialog.hide();
  var loc = ship.location.clone();
  loc.x = x; loc.y = y; loc.z = z;
  $omega_node.web_request('manufactured::move_entity', ship.id, loc, null);
}

/* Invoke omega server side manufactured::attack_entity 
 * operation to attack specified entity
 *
 * @param {Manufactured::Ship} attacker ship to launch attack with
 * @param {String} defender_id id of ship we are attacking
 */
function omega_ship_launch_attack(attacker, defender_id){
  $omega_dialog.hide();
  $omega_node.web_request('manufactured::attack_entity', attacker.id, defender_id, omega_callback());
}

/* Invoke omega server side manufactured::dock 
 * operation to dock the ship at the specified station
 *
 * @param {Manufactured::Ship} ship ship to dock
 * @param {String} station_id id of the station we are docking
 */
function omega_ship_dock_at(ship, station_id){
  $omega_dialog.hide();
  $omega_node.web_request('manufactured::dock', ship.id, station_id, omega_callback());
}

/* Invoke omega server side manufactured::undock 
 * operation to undock the specified ship
 *
 * @param {Manufactured::Ship} ship ship to undock
 */
function omega_ship_undock(ship){
  $omega_node.web_request('manufactured::undock', ship.id, omega_callback());
}

/* Invoke omega server side manufactured::transfer_resource 
 * operation to transfer all resources for the specified ship
 * to the specified station
 *
 * @param {Manufactured::Ship} ship ship to transfer resources from
 * @param {String} station_id id of station to transfer resources to
 */
function omega_ship_transfer(ship, station_id){
  for(var r in ship.resources){
    $omega_node.web_request('manufactured::transfer_resource', ship.id, station_id, r, ship.resources[r], omega_callback())
  }
  $omega_dialog.hide();
}

/* Invoke omega server side manufactured::start_mining 
 * operation to start mining the specified resource using
 * the specified ship
 *
 * @param {Manufactured::Ship} ship ship to use to start mining
 * @param {String} resource_source_id id of the resource source to starting mining
 */
function omega_ship_start_mining(ship, resource_source_id){
  $omega_dialog.hide();
  var ids = resource_source_id.split('_');
  var entity_id = ids[0];
  var resource_id  = ids[1];
  $omega_node.web_request('manufactured::start_mining', ship.id, entity_id, resource_id, omega_callback());
}

/* Invoke omega server side manufactured::construct 
 * operation to construct entity using the specified station
 *
 * @param {Manufactured::Station} station station to use to construct entity
 */
function omega_station_construct(station){
  $omega_node.web_request('manufactured::construct_entity', station.id, 'Manufactured::Ship', omega_callback(function(constructed){
    $scene.add_entity($tracker.entities[constructed.id]);
    $scene.animate();
  }));
}

/* Invoke omega server side manufactured::get_entities 
 * operation to retrieved all entities
 *
 * @param {Callback} callback function to invoke w/ array of galaxies retrieved
 */
function omega_all_entities(callback){
  $omega_node.web_request('manufactured::get_entity', omega_callback(callback));
}

/* Invoke omega server side manufactured::get_entities 
 * operation to retrieved entities owned by specified user
 *
 * @param {String} user_id id of the user to retrieve entities owned by
 * @param {Callback} callback function to invoke w/ array of entities retrieved
 */
function omega_entities_owned_by(user_id, callback){
  $omega_node.web_request('manufactured::get_entities', 'owned_by', user_id, omega_callback(callback));
}

/* Invoke omega server side manufactured::get_entities 
 * operation to retrieved entities under the specified system
 *
 * @param {String} system_name name of the system to retrieve entities under
 * @param {Callback} callback function to invoke w/ array of entities retrieved
 */
function omega_entities_under(system_name, callback){
  $omega_node.web_request('manufactured::get_entities', 'under', system_name, omega_callback(callback));
}


/* Invoke omega server side manufactured::get_entity
 * operation to retrieve entity with the specified id
 *
 * @param {String} entity_id id of the entity to retrieve
 * @param {Callback} callback function to invoke w/ entity retrieved
 */
function omega_entity(entity_id, callback){
  $omega_node.web_request('manufactured::get_entities', 'with_id', entity_id, omega_callback(callback));
}

/* Invoke omega server side cosmos::get_entities 
 * operation to retrieve all galaxies
 *
 * @param {Callback} callback function to invoke w/ array of galaxies retrieved
 */
function omega_all_galaxies(callback){
  $omega_node.web_request('cosmos::get_entity', 'of_type', 'Cosmos::Galaxy', omega_callback(callback));
}

/* Invoke omega server side cosmos::get_entities 
 * operation to retrieve systems with the specified name
 *
 * @param {String} system_name name of the system to retrieve
 * @param {Callback} callback function to invoke w/ system when retrieved
 */
function omega_system(system_name, callback){
  $omega_node.web_request('cosmos::get_entity', 'with_name', system_name, omega_callback(callback));
}

/* Invoke omega server side cosmos::get_resource_sources 
 * operation to retrieve resource sources associated with the specified 
 * entity
 *
 * @param {String} entity_name name of the entity to retireve associated resource sources
 * @param {Callback} callback function to invoke w/ resource sources when retrieved
 */
function omega_resource_sources(entity_name, callback){
  $omega_node.web_request('cosmos::get_resource_sources', entity_name, omega_callback(callback));
}

/* Invoke omega server side users::get_entity
 * operation to retrieve all users
 *
 * @param {Callback} callback function to invoke w/ array of users retrieved
 */
function omega_all_users(callback){
  $omega_node.web_request('users::get_entity', 'of_type', 'Users::User', omega_callback(callback));
}

/////// precommands to display dialog to select command

// display dialog w/ coordinate selection
function select_ship_destination(ship){
  // TODO drop down select box w/ all entities in the local system
  var text = "<div class='dialog_row'>"+ship.id+"</div>"+
             "<div class='dialog_row'>X: <input id='dest_x' type='text' value='"+roundTo(ship.location.x,2)+"'/></div>" +
             "<div class='dialog_row'>Y: <input id='dest_y' type='text' value='"+roundTo(ship.location.y,2)+"'/></div>" +
             "<div class='dialog_row'>Z: <input id='dest_z' type='text' value='"+roundTo(ship.location.z,2)+"'/></div>" +
             "<div class='dialog_row'><input type='button' value='move' id='ship_move_to' /></div>";
  $omega_dialog.show('Move Ship', null, text);
}

function select_ship_target(ship){
  // TODO also list stations
  var entities = $tracker.matching_entities({type : "Manufactured::Ship",
                                             not_owned_by : $user_id,
                                             within : [ship.attack_distance, ship.location]});
  var text = "<div class='dialog_row'>Select "+ship.id+" target</div>";
  for(var entity in entities){
    entity = entities[entity];
    text += "<div class='dialog_row dialog_clickable_row ship_launch_attack'>" + entity.id + "</div>";
  }
  $omega_dialog.show('Launch Attack', null, text);
}

function select_ship_dock(ship){
  var entities = $tracker.matching_entities({type : "Manufactured::Station",
                                             within : [100, ship.location]});
  var text = "<div class='dialog_row'>Dock "+ship.id+" at</div>";
  for(var entity in entities){
    entity = entities[entity];
    text += "<div class='dialog_row dialog_clickable_row ship_dock_at'>" + entity.id + "</div>";
  }
  $omega_dialog.show('Dock Ship', null, text);
}

function select_ship_transfer(ship){
  var entities = $tracker.matching_entities({type : "Manufactured::Station",
                                             within : [100, ship.location]});
  var text = "<div class='dialog_row'>Transfer Resources from "+ship.id+" to</div>";
  for(var entity in entities){
    entity = entities[entity];
    text += "<div class='dialog_row dialog_clickable_row ship_transfer'>" + entity.id + "</div>";
  }
  $omega_dialog.show('Transfer Resources', null, text);
}

function select_ship_mining(ship){
  var entities = $tracker.matching_entities({type : "Cosmos::Asteroid",
                                             within : [100, ship.location]});
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
}

/////////////////////////////////////// private methods

/* Generate as wrapper that handles the result of rjr
 * operations and invokes the registered client callback
 */
function omega_callback(oc){
  return function(result, error){
    // only invoke client callback on success (assuming errors handled elsewhere)
    if(error == null){

      // register entities w/ the register
      if(typeof(result) == "object" && result.length > 0 && result[0]){
        for(var entity in result){
          entity = result[entity];
          register_entity(entity);
        }
      }else if(typeof(result) != "object" || Object.keys(result).length != 0){
        register_entity(result);
      }

      // invoke client callback
      if(oc != null)
        oc(result);
    }
  };
}
