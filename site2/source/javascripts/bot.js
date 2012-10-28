$entity_tracker = [];

function add_to_tracker(entity){
  var is_new_entity = ($entity_tracker[entity.id] == null);
  $entity_tracker[entity.id] = entity;
  //if(entity.location != null)
  //  entity.location.entity = entity;
  return is_new_entity;
}

function update_tracked_entity(entity){
  for(var p in entity)
    $entity_tracker[entity.id][p] = entity[p];
  $entity_tracker[entity.id].scene_location.dirty = true;
  return $entity_tracker[entity.id];
}

function get_entities_within(entity_type, loc, distance){
  var entities = [];
  for(var entity in $entity_tracker){
    entity = $entity_tracker[entity];
    if(entity.json_class == entity_type &&
       entity.user_id == $user_id &&
       Math.sqrt(Math.pow(entity.location.x - loc.x, 2) +
                 Math.pow(entity.location.y - loc.y, 2) +
                 Math.pow(entity.location.z - loc.z, 2)) < distance){
      entities.push(entity);
    }
  }
  return entities;
}

function calc_planet_orbit(planet){
  planet.orbit = [];
  // intercepts
  var a = planet.location.movement_strategy.semi_latus_rectum / (1 - Math.pow(planet.location.movement_strategy.eccentricity, 2));
  var b = Math.sqrt(planet.location.movement_strategy.semi_latus_rectum * a);
  // linear eccentricity
  var le = Math.sqrt(Math.pow(a, 2) - Math.pow(b, 2));
  // center (assumes planet's location's movement_strategy.relative to is set to foci
  var cx = -1 * planet.location.movement_strategy.direction_major_x * le;
  var cy = -1 * planet.location.movement_strategy.direction_major_y * le;
  var cz = -1 * planet.location.movement_strategy.direction_major_z * le;
  // orbit
  for(var i = 0; i < 2 * Math.PI; i += (Math.PI / 180)){
    var ox = cx + a * Math.cos(i) * planet.location.movement_strategy.direction_major_x +
                  b * Math.sin(i) * planet.location.movement_strategy.direction_minor_x ;
    var oy = cy + a * Math.cos(i) * planet.location.movement_strategy.direction_major_y +
                  b * Math.sin(i) * planet.location.movement_strategy.direction_minor_y ;
    var oz = cz + a * Math.cos(i) * planet.location.movement_strategy.direction_major_z +
                  b * Math.sin(i) * planet.location.movement_strategy.direction_minor_z ;
    planet.orbit.push([ox, oy, oz]);
  }
}

function set_root_entity(entity_id){
  // explicitly depends on omega_renderer & canvas modules
  var entity = $entity_tracker[entity_id];
  $scene.set_target(entity.location.id);
  hide_entity_container();
  $('#omega_canvas').css('background', 'url("/womega/images/backgrounds/' + entity.background + '.png") no-repeat');

  // cancel all event tracking
  clear_method_handlers();
  var tracking_location = false;

  for(var entityI in $entity_tracker){
    var entityT = $entity_tracker[entityI];

    // remove all callbacks by default
    if(entityT.user_id == $user_id){
      omega_ws_request('motel::remove_callbacks', entityT.location.id, null);
      if(entityT.json_class == "Manufactured::Ship")
        omega_ws_request('manufactured::remove_callbacks', entityT.id, null);
    }

    if(entityT.location.parent_id == entity.location.id){
      $scene.add_entity(entityT);

      // track planet movement & ship events
      if(entityT.json_class == "Cosmos::Planet"){
        tracking_location = true;
        omega_ws_request('motel::track_movement', entityT.location.id, 100, null);
      }else if(entityT.json_class == "Manufactured::Ship"){
        tracking_location = true;
        omega_ws_request('motel::track_movement', entityT.location.id, 20, null);
        // TODO track attack/defend and mining events
      }
    }
  }

  if(tracking_location){
    add_method_handler('motel::on_movement', function(loc){
      loc = $scene.update_location(loc);
      loc.render($scene);
    });
  }

  $scene.setup();
}

function callback_got_galaxy(galaxy, error){
  if(error == null){
    galaxy.id = galaxy.name;
    add_to_tracker(galaxy);
  }
}

function callback_got_system(system, error){
  if(error == null){
    // add entities to tracker
    system.id = system.name;
    var new_system = add_to_tracker(system);

    if(new_system){
      // explicity depends on canvas module
      $('#locations_list ul').
       append('<li name="'+system.galaxy_name+'">'+system.galaxy_name+'</li>').
       append('<li name="'+system.id+'"> -> '+system.id+'</li>');
      $('#locations_list').show();

      //if($entity_tracker[system.galaxy_name] == null){
      //  // XXX potential performance issues
      //  omega_web_request('cosmos::get_entity', 'with_name', system.galaxy_name, callback_got_galaxy);
      //}
      if(system.star != null){
        system.star.id = system.star.name;
        add_to_tracker(system.star);
      }
      for(var p in system.planets){
        p = system.planets[p];
        calc_planet_orbit(p);
        p.id = p.name;
        add_to_tracker(p);
        for(var m in p.moons){
          m = p.moons[m];
          m.id = m.name;
          add_to_tracker(m);
        }
      }
      for(var j in system.jump_gates){
        j = system.jump_gates[j];
        j.id = j.solar_system + "-" + j.endpoint;
        //if($entity_tracker[j.endpoint] == null){
        //  // XXX potential performance issues
        //  omega_web_request('cosmos::get_entity', 'with_name', j.endpoint, callback_got_system);
        //}
        add_to_tracker(j);
      }
      for(var a in system.asteroids){
        a = system.asteroids[a];
        a.id = a.name;
        add_to_tracker(a);
      }
    }
  }
}

function callback_got_manufactured_entities(entities, error){
  if(error == null){
    for(var entityI in entities){
      var entity = entities[entityI];
      add_to_tracker(entity);
      omega_web_request('cosmos::get_entity', 'with_name', entity.system_name, callback_got_system);
    }
  }
}

function get_manufactured_entities(user, error){
  if(error == null){
    var user_id = (user.json_class == 'Users::User' ? user.id : user.user_id);
    omega_web_request('manufactured::get_entities', 'owned_by', user_id, callback_got_manufactured_entities);
  }
}

function trigger_jump_gate(jg){
  var triggered = false;
  var endpoint = $entity_tracker[jg.endpoint].location;
  var entities = get_entities_within("Manufactured::Ship", jg.location, jg.trigger_distance);
  for(var entity in entities){
    triggered = true;
    entity = entities[entity];
    entity.location.parent_id = endpoint.id;
    omega_web_request('manufactured::move_entity', entity.id, entity.location, null);

    $scene.remove_location(entity.location);
  }
  // redraw scene w/out location
  if(triggered) $scene.setup();
    
}

function select_ship_destination(ship){
  var text = "<div class='dialog_row'>"+ship.id+"</div>"+
             "<div class='dialog_row'>X: <input id='dest_x' type='text' value='"+roundTo(ship.location.x,2)+"'/></div>" +
             "<div class='dialog_row'>Y: <input id='dest_y' type='text' value='"+roundTo(ship.location.y,2)+"'/></div>" +
             "<div class='dialog_row'>Z: <input id='dest_z' type='text' value='"+roundTo(ship.location.z,2)+"'/></div>" +
             "<div class='dialog_row'><input type='button' value='move' id='ship_move_to' /></div>";
  show_dialog('Move Ship', null, text);
}

function move_ship_to(ship, x, y, z){
  hide_dialog();
  ship.location.x = x;
  ship.location.y = y;
  ship.location.z = z;
  omega_web_request('manufactured::move_entity', ship.id, ship.location, null);
}

function select_ship_target(ship){
}

function ship_launch_attack(attacker, defender){
}

function callback_ship_updated(ship, error){
  if(error == null){
    ship = update_tracked_entity(ship);
    clicked_manufactured_ship(ship);
  }
}

function ship_select_dock(ship){
  var entities = get_entities_within("Manufactured::Station", ship.location, 100);
  var text = "<div class='dialog_row'>Dock "+ship.id+" at</div>";
  for(var entity in entities){
    entity = entities[entity];
    text += "<div class='dialog_row dialog_clickable_row ship_dock_at'>" + entity.id + "</div>";
  }
  show_dialog('Dock Ship', null, text);
}

function ship_dock_at(ship, station_id){
  hide_dialog();
  omega_web_request('manufactured::dock', ship.id, station_id, callback_ship_updated);
}

function ship_undock(ship){
  omega_web_request('manufactured::undock', ship.id, callback_ship_updated);
}

function callback_ship_transferred(entities, error){
  if(error == null){
    var ship = update_tracked_entity(entities[0]);
    var station = update_tracked_entity(entities[1]);
    clicked_manufactured_ship(ship);
  }
}

function ship_select_transfer(ship){
  var entities = get_entities_within("Manufactured::Station", ship.location, 100);
  var text = "<div class='dialog_row'>Transfer Resources from "+ship.id+" to</div>";
  for(var entity in entities){
    entity = entities[entity];
    text += "<div class='dialog_row dialog_clickable_row ship_transfer'>" + entity.id + "</div>";
  }
  show_dialog('Transfer Resources', null, text);

}

function ship_transfer(ship, station_id){
  for(var r in ship.resources){
    omega_web_request('manufactured::transfer_resource', ship.id, station_id, r, ship.resources[r], callback_ship_transferred)
  }
  hide_dialog();
}

function ship_select_mining(ship){
}

function ship_start_mining(ship, resource_source){
}

function station_construct(station){
}

$(document).ready(function(){ 
  $validate_session_callbacks.push(get_manufactured_entities);
  $login_callbacks.push(get_manufactured_entities);
  $('#locations_list li').live('click', function(event){ 
    var entity_id = $(event.currentTarget).attr('name');
    set_root_entity(entity_id);
  });
});
