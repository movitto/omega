function trigger_jump_gate(jg){
  var triggered = false;
  var source   = $tracker.matching_entities({location : jg.location.parent_id})[0];
  var endpoint = $tracker.matching_entities({id : jg.endpoint});
  if(endpoint.length == 0){
    // TODO get system
    $tracker.load('Cosmos::SolarSystem', jg.endpoint, function(sys, err){
      callback_got_system(sys, err); // XXX
      trigger_jump_gate($selected_entity);
    });
    return;
  }
  endpoint = endpoint[0];
  var eloc = endpoint.location;
  var entities = $tracker.matching_entities({type : "Manufactured::Ship",
                                             within : [jg.trigger_distance, jg.location],
                                             owned_by : $user_id});
  for(var entity in entities){
    triggered = true;
    entity = entities[entity];
    entity.location.parent_id = eloc.id;
    entity.system_name = endpoint.name;
    omega_web_request('manufactured::move_entity', entity.id, entity.location, null);

    // update systems and scene
    source.update_children();
    endpoint.update_children();
    $scene.remove(entity.id);
  }
  // redraw scene w/out location
  if(triggered) $scene.animate();
    
}

function select_ship_destination(ship){
  // TODO drop down select box w/ all entities in the local system
  var text = "<div class='dialog_row'>"+ship.id+"</div>"+
             "<div class='dialog_row'>X: <input id='dest_x' type='text' value='"+roundTo(ship.location.x,2)+"'/></div>" +
             "<div class='dialog_row'>Y: <input id='dest_y' type='text' value='"+roundTo(ship.location.y,2)+"'/></div>" +
             "<div class='dialog_row'>Z: <input id='dest_z' type='text' value='"+roundTo(ship.location.z,2)+"'/></div>" +
             "<div class='dialog_row'><input type='button' value='move' id='ship_move_to' /></div>";
  show_dialog('Move Ship', null, text);
}

function move_ship_to(ship, x, y, z){
  hide_dialog();
  var loc = ship.location.clone();
  loc.x = x; loc.y = y; loc.z = z;
  omega_web_request('manufactured::move_entity', ship.id, loc, null);
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
  show_dialog('Launch Attack', null, text);
}

function ship_launch_attack(attacker, defender_id){
  hide_dialog();
  omega_web_request('manufactured::attack_entity', attacker.id, defender_id, callback_ship_updated);
}

function callback_ship_updated(ship, error){
  if(error == null){
    $tracker.add(ship);
  }
}

function ship_select_dock(ship){
  var entities = $tracker.matching_entities({type : "Manufactured::Station",
                                             within : [100, ship.location]});
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
    $tracker.add(entities[0]);
    $tracker.add(entities[1]);
  }
}

function ship_select_transfer(ship){
  var entities = $tracker.matching_entities({type : "Manufactured::Station",
                                             within : [100, ship.location]});
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
  var entities = $tracker.matching_entities({type : "Cosmos::Asteroid",
                                             within : [100, ship.location]});
  var text = "<div class='dialog_row'>Select resource to mine w/"+ship.id+"</div>";
  show_dialog('Start Mining', null, text);

  for(var entity in entities){
    entity = entities[entity];
    omega_web_request('cosmos::get_resource_sources', entity.name, function(resource_sources, error){
      if(error == null){
        var details = "";
        for(var r in resource_sources){
          var res = resource_sources[r];
          details += "<div class='dialog_row dialog_clickable_row ship_start_mining' id='start_mining_rs_" + res.entity.name + "_" + res.resource.id + "'>" + res.resource.type + ": " + res.resource.name + " (" + res.quantity + ")</div>";
        }
        append_to_dialog(details);
      }
    });
  }
}

function ship_start_mining(ship, resource_source_id){
  hide_dialog();
  var ids = resource_source_id.split('_');
  var entity_id = ids[0];
  var resource_id  = ids[1];
  omega_web_request('manufactured::start_mining', ship.id, entity_id, resource_id, callback_ship_updated);
}

function station_construct(station){
  // TODO update station as well
  omega_web_request('manufactured::construct_entity', station.id, 'Manufactured::Ship', function(constructed){
    $tracker.add(constructed);
    $scene.add($tracker.entities[constructed.id]);
    $scene.animate();
  });
}


$(document).ready(function(){ 
  // FIXME selected_entity may have changed in the meantime

  $('#ship_trigger_jg').live('click', function(e){
    trigger_jump_gate($selected_entity);
  });

  $('#ship_select_move').live('click', function(e){
    select_ship_destination($selected_entity);
  });

  $('#ship_move_to').live('click', function(e){
    move_ship_to($selected_entity, $('#dest_x').attr('value'),
                                   $('#dest_y').attr('value'),
                                   $('#dest_z').attr('value'));
  });

  $('#ship_select_target').live('click', function(e){
    select_ship_target($selected_entity);
  });

  $('.ship_launch_attack').live('click', function(e){
    ship_launch_attack($selected_entity, $(e.currentTarget).html());
  });

  $('#ship_select_dock').live('click', function(e){
    ship_select_dock($selected_entity);
  });

  $('.ship_dock_at').live('click', function(e){
    ship_dock_at($selected_entity, $(e.currentTarget).html());
  });

  $('#ship_undock').live('click', function(e){
    ship_undock($selected_entity);
  });

  $('#ship_select_transfer').live('click', function(e){
    ship_select_transfer($selected_entity);
  });

  $('.ship_transfer').live('click', function(e){
    ship_transfer($selected_entity, $(e.currentTarget).html());
  });

  $('#ship_select_mine').live('click', function(e){
    ship_select_mining($selected_entity);
  });

  $('.ship_start_mining').live('click', function(e){
    var rsid = e.currentTarget.id.replace('start_mining_rs_', '');
    ship_start_mining($selected_entity, rsid);
  });

  $('#station_select_construction').live('click', function(e){
    station_construct($selected_entity);
  });
});
