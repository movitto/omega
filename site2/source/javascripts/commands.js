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

  $('#ship_launch_attack').live('click', function(e){
    ship_launch_attack($selected_entity, 'TODO');
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

  $('#ship_start_mining').live('click', function(e){
    ship_start_mining($selected_entity, 'TODO');
  });

  $('#station_select_construction').live('click', function(e){
    station_construct($selected_entity);
  });
});
