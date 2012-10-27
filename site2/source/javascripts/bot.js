$entity_tracker = [];

function add_to_tracker(entity){
  var is_new_entity = ($entity_tracker[entity.id] == null);
  $entity_tracker[entity.id] = entity;
  if(entity.location != null)
    entity.location.entity = entity;
  return is_new_entity;
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
  $('#omega_canvas').css('background', 'url("/womega/images/backgrounds/' + entity.background + '.png") no-repeat');
  for(var entityI in $entity_tracker){
    if($entity_tracker[entityI].location.parent_id == entity.location.id){
      $scene.add_location($entity_tracker[entityI].location);
    }
  }
  // TODO cancel all tracking, then track planet & ship movement
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

      if($entity_tracker[system.galaxy_name] == null){
        // XXX potential performance issues
        omega_web_request('cosmos::get_entity', 'with_name', system.galaxy_name, callback_got_galaxy);
      }
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
        if($entity_tracker[j.endpoint] == null){
          // XXX potential performance issues
          omega_web_request('cosmos::get_entity', 'with_name', j.endpoint, callback_got_system);
        }
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

$(document).ready(function(){ 
  $validate_session_callbacks.push(get_manufactured_entities);
  $login_callbacks.push(get_manufactured_entities);
  $('#locations_list li').live('click', function(event){ 
    var entity_id = $(event.currentTarget).attr('name');
    set_root_entity(entity_id);
  });
});
