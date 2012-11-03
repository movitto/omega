function clear_timers(){
  for(var timer in $timers){
    $timers[timer].stop();
    delete $timers[timer];
  }
  $timers = [];
}

function set_root_entity(entity_id){
  var entity = $tracker.entities[entity_id];
  hide_entity_container();
  $('#omega_canvas').css('background', 'url("/womega/images/backgrounds/' + entity.background + '.png") no-repeat');

  $scene.clear();

  // cancel all event tracking
  clear_timers();
  clear_method_handlers();
  var tracking_location = false;
  var tracking_manufactured_events = false;
  $tracked_planets = [];

  for(var child in entity.children){
    child = entity.children[child];
    // remove & resetup callbacks
    if(child.is_a("Manufactured::Ship")){
      if(child.belongs_to_user()){ // TODO should this conditional be here ?
        omega_ws_request('motel::remove_callbacks', child.location.id, null);
        omega_ws_request('manufactured::remove_callbacks', child.id, null);
      }

      tracking_location = true;
      omega_ws_request('motel::track_movement', child.location.id, 20, null);

      tracking_manufactured_events = true;
      omega_ws_request('manufactured::subscribe_to', child.id, 'resource_collected', null);
      omega_ws_request('manufactured::subscribe_to', child.id, 'mining_stopped', null);

      omega_ws_request('manufactured::subscribe_to', child.id, 'attacked', null);
      omega_ws_request('manufactured::subscribe_to', child.id, 'attacked_stop', null);
      omega_ws_request('manufactured::subscribe_to', child.id, 'defended', null);
      omega_ws_request('manufactured::subscribe_to', child.id, 'defended_stop', null);
      omega_ws_request('manufactured::subscribe_to', child.id, 'destroyed', null);

      // TODO track attack/defend events

    }else if(child.is_a("Cosmos::Planet")){
      $tracked_planets.push(child);
      omega_ws_request('motel::remove_callbacks', child.location.id, null);

      tracking_location = true;
      omega_ws_request('motel::track_movement', child.location.id, 120, null);
    }

    $scene.add(child);
  }

  if(tracking_location){
    add_method_handler('motel::on_movement', function(loc){
      var entity = $tracker.matching_entities({location : loc.id});
      entity[0].update({location : loc});
      $scene.animate();
    });
  }

  if(tracking_manufactured_events){
    add_method_handler('manufactured::event_occurred', function(p0, p1, p2, p3){
      var evnt = p0;
      if(evnt == "resource_collected"){
        var ship = p1;
        var resource_source = p2;
        var quantity = p3;
        $tracker.add(ship);

      }else if(evnt == "mining_stopped"){
        var reason = p1;
        var ship = p2;
        // XXX hack serverside ship.mining might not be nil at this point
        ship.mining  = null;
        $tracker.add(ship);

      }else if(evnt == "attacked"){
        var attacker = p1;
        var defender = p2;
        attacker.attacking = defender;
        $tracker.add(attacker);
        $tracker.add(defender);

      }else if(evnt == "attacked_stop"){
        var attacker = p1;
        var defender = p2;
        attacker.attacking = null;
        $tracker.add(attacker);
        $tracker.add(defender);

      }else if(evnt == "defended"){
        var attacker = p1;
        var defender = p2;
        attacker.attacking = defender;
        $tracker.add(attacker);
        $tracker.add(defender);

      }else if(evnt == "defended_stop"){
        var attacker = p1;
        var defender = p2;
        attacker.attacking = null;
        $tracker.add(attacker);
        $tracker.add(defender);

      }else if(evnt == "destroyed"){
        var attacker = p1;
        var defender = p2;
        attacker.attacking = null;
        $tracker.add(attacker);
        $tracker.add(defender);
        $scene.remove(defender.id);

      }

      $scene.animate();
    });
  }

  if($tracked_planets.length > 0){
    // create a timer to periodically update planet location inbetween server syncronizations
    $timers['planet_movement'] = $.timer(function(){
      for(var planet in $tracked_planets){
        planet = $tracked_planets[planet];
        planet.move();
        $scene.animate();
      }
    });
    $timers['planet_movement'].set({time : 2000, autostart : true });
  }

  $scene.animate();
}

function callback_got_system(system, error){
  if(error == null){
    if(!system.modified){ // if adding system for the first time
      $('#locations_list ul').append('<li name="'+system.name+'">'+system.name+'</li>');
      $('#locations_list').show();

      register_entity(system);

      // get additional entities under system
      omega_web_request('manufactured::get_entities', 'under', system.name, callback_got_manufactured_entities);
    }
  }
}

function callback_got_manufactured_entities(entities, error){
  if(error == null){
    for(var entityI in entities){
      var entity = entities[entityI];
      var new_entity = $tracker.add(entity);
      if(new_entity){
        var system = $tracker.load('Cosmos::SolarSystem', entity.system_name, callback_got_system);
        if(system){
          system.update_children();
        }
      }
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
  $timers = {};
  $validate_session_callbacks.push(get_manufactured_entities);
  $login_callbacks.push(get_manufactured_entities);

  $('#locations_list li').live('click', function(event){ 
    var entity_id = $(event.currentTarget).attr('name');
    set_root_entity(entity_id);
  });
});
