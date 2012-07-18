function CosmosControls(){
  // selected entities
  this.selected_ships = [];
  this.selected_ship = null; // will point to first selected ship, null if none
  this.selected_gate  = null;
  this.selected_station  = null;
  this.selected_asteroid = null;

  // helper method
  this.update_selected_ship = function(ship){
    for(var si in this.selected_ships){
      if(this.selected_ships[si].id == ship.id){
        ship.selected = true;
        this.selected_ships[si] = ship;
        return true;
      }
    }
    ship.selected = false;
    return false;
  }

  this.set_selected_ship = function(ship, clear_selected){
    if(clear_selected){
      for(var s in this.selected_ships)
        this.selected_ships[s].selected = false;
      this.selected_ships = [];
      this.selected_ship  = null;
    }
    if(ship){
      ship.selected = true;
      if(this.selected_ships.length == 0) this.selected_ship = ship;
      this.selected_ships.push(ship);
      this.set_selected_gate(null);
      this.set_selected_station(null);
      this.set_selected_asteroid(null);
    }
  }

  this.clear_selected_ship = function(){
    this.set_selected_ship(null, true);
  }

  this.set_selected_gate = function(gate){
    this.selected_gate = gate;

    if(gate != null){
      this.clear_selected_ship();
      this.set_selected_station(null);
      this.set_selected_asteroid(null);
    }
  }

  this.set_selected_station = function(station){
    this.selected_station = station;
    if(station != null){
      this.clear_selected_ship();
      this.set_selected_gate(null);
      this.set_selected_asteroid(null);
    }
  }

  this.set_selected_asteroid = function(asteroid){
    this.selected_asteroid = asteroid;
    if(asteroid != null){
      this.clear_selected_ship();
      this.set_selected_gate(null);
      this.set_selected_station(null);
    }
  }

  // initialize mouse input
  this.mouse_down_x          = null;
  this.mouse_down_y          = null;
  this.mouse_current_x       = null;
  this.mouse_current_y       = null;
  
  // initialize select box
  this.select_box_top_left_x = null;
  this.select_box_top_left_y = null;
  this.select_box_width      = null;
  this.select_box_height     = null;

  this.update_select_box = function(){
    if(this.mouse_down_x    && this.mouse_down_y &&
       this.mouse_current_x && this.mouse_current_y){
         if(this.mouse_current_x < this.mouse_down_x){
           this.select_box_top_left_x     = this.mouse_current_x;
           this.select_box_bottom_right_x = this.mouse_down_x;
         }else{
           this.select_box_top_left_x     = this.mouse_down_x;
           this.select_box_bottom_right_x = this.mouse_current_x;
         }
  
         if(this.mouse_current_y < this.mouse_down_y){
           this.select_box_top_left_y     = this.mouse_current_y;
           this.select_box_bottom_right_y = this.mouse_down_y;
         }else{
           this.select_box_top_left_y     = this.mouse_down_y;
           this.select_box_bottom_right_y = this.mouse_current_y;
         }
         this.select_box_width  = this.select_box_bottom_right_x - this.select_box_top_left_x - 15;
         this.select_box_height = this.select_box_bottom_right_y - this.select_box_top_left_y - 15;
    }else{
      this.select_box_top_left_x     = null;
      this.select_box_top_left_y     = null;
      this.select_box_bottom_right_x = null;
      this.select_box_bottom_right_y = null;
      this.select_box_width          = null;
      this.select_box_height         = null;
    }

    // draw the controls
    this.draw();
  }

  this.show_login_controls = function(){
    $('#create_account_dialog_link').show();
    $('#login_dialog_link').show();
    $('#logout_link').hide();
    $('#account_link').hide();
  }

  this.show_logout_controls = function(){
    $('#account_link').show();
    $('#logout_link').show();
    $('#login_dialog_link').hide();
    $('#create_account_dialog_link').hide();
  }

  this.draw = function(){
    $("#motel_canvas_selection_controls").remove();
    if(this.select_box_top_left_x && this.select_box_top_left_y &&
       this.select_box_width > 0 && this.select_box_height > 0){
        $("#motel_canvas_container").append("<div id='motel_canvas_selection_controls'></div>");
        var c = $('#motel_canvas_selection_controls');
        c.css('left', canvas_ui.canvas.position().left + this.select_box_top_left_x);
        c.css('top',  canvas_ui.canvas.position().top + this.select_box_top_left_y);
        c.css('min-width',  this.select_box_width);
        c.css('min-height',  this.select_box_height);
        c.css('border', '1px solid black');
    }
  }

  this.clear_details = function(){
    var entity_container = $('#motel_entity_container');
    entity_container.html('');
  }

  // helper method to refresh the details box currently being displayed
  this.refresh_details = function(){
    if(this.selected_ship != null){
      for(var l in client.locations){
        if(client.locations[l].entity.json_class == "Manufactured::Ship" &&
           client.locations[l].entity.id == this.selected_ship.id){
          this.selected_ship = client.locations[l].entity;
          break;
        }
      }
      this.show_ship_details(this.selected_ship);

    }else if(this.selected_station != null){
      for(var l in client.locations){
        if(client.locations[l].entity.json_class == "Manufactured::Station" &&
           client.locations[l].entity.id == this.selected_station.id){
          this.selected_station = client.locations[l].entity;
          break;
        }
      }
      this.show_station_details(this.selected_station);

    }else if(this.selected_gate != null){
      this.show_gate_details(this.selected_gate);

    }else if(this.selected_asteroid != null){
      for(var l in client.locations){
        if(client.locations[l].entity.json_class == "Cosmos::Asteroid" &&
           client.locations[l].entity.name == this.selected_asteroid.name){
          this.selected_asteroid = client.locations[l].entity;
          break;
        }
      }
      this.show_asteroid_details(this.selected_asteroid);
    }
  }

  this.unregistered_click = function(click_event, entity) {}

  this.clicked_system  = function(click_event, system) {
    this.clear_selected_ship();
    handlers.set_system(system.name);
  }

  this.clicked_planet  = function(click_event, planet) {
    var entity_container = $('#motel_entity_container');
    this.clear_selected_ship();
    entity_container.show();
    entity_container.html("Planet: " + planet.name);
  }

  // helper method
  this.show_asteroid_details = function(asteroid) {
    this.set_selected_asteroid(asteroid);
    var entity_container = $('#motel_entity_container');
    var asteroid_data = "Asteroid: " + asteroid.name +
                        " ( @ " + asteroid.location.to_s() + ")" +
                        "<br/>Resources: ";
    for(var r in asteroid.resources){
      var res = asteroid.resources[r];
      asteroid_data += res.quantity + " of " + res.resource.name + " (" + res.resource.type + ")<br/>";
    }
    this.clear_selected_ship();
    entity_container.show();
    entity_container.html(asteroid_data);
  }

  this.clicked_asteroid  = function(click_event, asteroid) {
    this.show_asteroid_details(asteroid);
  }

  // helper method
  this.show_gate_details = function(gate){
    var entity_container = $('#motel_entity_container');
    controls.set_selected_gate(gate);
    entity_container.show();
    entity_container.html("JumpGate to: " + gate.endpoint +
                          "<br/> (@ "+ gate.location.to_s()+")" +
                          "<br/><div class='command_icon' id='command_selection_clear'>clear selection</div>" +
                          "<div class='command_icon' id='command_jumpgate_trigger'>Trigger</div>");
  }
  this.clicked_gate    = function(click_event, gate) {
    this.show_gate_details(gate);
  }

  // helper method
  this.show_ship_details = function(ship){
    var entity_container = $('#motel_entity_container');
    controls.set_selected_ship(ship, true);
    entity_container.show();
    var entity_container_contents = "Ship: " +
                                    controls.selected_ship.id +
                                    " (" + controls.selected_ship.type + " @ " +
                                           controls.selected_ship.location.to_s() + ")";

    entity_container_contents += "<br/>Resources: ";
    for(var r in ship.resources){
      entity_container_contents += r + " (" + ship.resources[r] + ") ";
    }
    entity_container_contents += "<br/><div class='command_icon' id='command_selection_clear'>clear selection</div>";
    entity_container_contents += "<div class='command_icon' id='command_ship_select_destination'>move</div>";
    entity_container_contents += "<div class='command_icon' id='command_ship_select_target'>attack</div>";
    entity_container_contents += "<div class='command_icon' id='command_ship_select_dock'>dock</div>";
    entity_container_contents += "<div class='command_icon' id='command_ship_undock'>undock</div>";
    entity_container_contents += "<div class='command_icon' id='command_ship_select_transfer_resource'>transfer resource</div>";
    entity_container_contents += "<div class='command_icon' id='command_ship_select_mining'>start mining</div>";
    if(controls.selected_ships.length > 1)
      entity_container_contents += "<br/><a href='#' id='command_fleet_create'>create fleet</a>";
    entity_container.html(entity_container_contents);

    if(!controls.selected_ship.docked_at){
      $('#command_ship_undock').hide();
      $('#command_ship_select_transfer_resource').hide();
    }else{
      $('#command_ship_select_dock').hide();
      $('#command_ship_select_transfer_resource').show();
    }
  }

  this.clicked_ship    = function(click_event, ship) {
    this.show_ship_details(ship);
  }

  // helper method
  this.show_station_details = function(station){
    controls.set_selected_station(station);
    var html = "Station: " + station.id +
               " @ " + station.location.to_s() +
               "<br/>Type: " + station.type +
               "<br/>Docked Ships: ";

    for(var l in client.locations){
      var e = client.locations[l].entity;
      if(e.json_class == "Manufactured::Ship" &&
         e.docked_at &&
         e.docked_at.id == station.id)
           html += "<a href='#' id='"+e.id+"' class='command_view_ship' >"+e.id+"</a>";
    }

    html += "<br/>Resources: ";
    for(var r in station.resources){
      html += r + " (" + station.resources[r] + ")";
    }

    html += "<div class='command_icon' id='command_station_select_construction'>construct ship</div>";

    this.clear_selected_ship();
    var entity_container = $('#motel_entity_container');
    entity_container.show();
    entity_container.html(html);
  }

  this.clicked_station = function(click_event, station) {
    this.show_station_details(station);
  }

  this.clicked_space = function(x, y){}
}

// handle click input
function on_canvas_clicked(e){
  var x = Math.floor(e.pageX-canvas_ui.canvas.offset().left);
  var y = Math.floor(e.pageY-canvas_ui.canvas.offset().top);
  x = x / canvas_ui.canvas.width() * 2 - 1;
  y = - y / canvas_ui.canvas.height() * 2 + 1;
  var clicked_on_entity = false;

  var projector = new THREE.Projector();
  var ray = projector.pickingRay(new THREE.Vector3(x, y, 0.5), canvas_ui.camera.scene_camera);
  var intersects = ray.intersectObjects(canvas_ui.scene.__objects);

  if(intersects.length > 0){
    for(loc in client.locations){
      var loco = client.locations[loc];
      if(loco.entity.scene_object == intersects[0].object){
        clicked_on_entity = true;
        loco.clicked(e, loco.entity);
        break;
      }
    }
  }

  if(!clicked_on_entity)
    controls.clicked_space(x, y);

  canvas_ui.setup_scene(); // appearances may have changed, redraw scene
}
$("#motel_canvas").live('click', on_canvas_clicked);
$("#motel_canvas_selection_controls").live('click', on_canvas_clicked);

// handle mouse move event
function on_canvas_mouse_move(e){
  controls.mouse_current_x = e.pageX - canvas_ui.canvas.offset().left;
  controls.mouse_current_y = e.pageY - canvas_ui.canvas.offset().top;
  controls.update_select_box();
}
$("#motel_canvas").live('mousemove', on_canvas_mouse_move);
$("#motel_canvas_selection_controls").live('mousemove', on_canvas_mouse_move);

// handle mouse down event
function on_canvas_mouse_down(e){
  controls.mouse_down_x = e.pageX - canvas_ui.canvas.offset().left;
  controls.mouse_down_y = e.pageY - canvas_ui.canvas.offset().top;
  controls.update_select_box();
}
$("#motel_canvas").live('mousedown', on_canvas_mouse_down);
$("#motel_canvas_selection_controls").live('mousedown', on_canvas_mouse_down);

// handle mouse up event
function on_canvas_mouse_up(e){
  controls.mouse_down_x = null; controls.mouse_down_y = null;
  controls.update_select_box();
}
$("#motel_canvas").live('mouseup', on_canvas_mouse_up);
$("#motel_canvas_selection_controls").live('mouseup', on_canvas_mouse_up);

/////////////////////// camera controls

if(jQuery.fn.mousehold){

$('#cam_rotate_right').mousehold(function(e, ctr){
  canvas_ui.camera.rotate(0.0, 0.2);
});

$('#cam_rotate_left').mousehold(function(e, ctr){
  canvas_ui.camera.rotate(0.0, -0.2);
});

$('#cam_rotate_up').mousehold(function(e, ctr){
  canvas_ui.camera.rotate(-0.2, 0.0);
});

$('#cam_rotate_down').mousehold(function(e, ctr){
  canvas_ui.camera.rotate(0.2, 0.0);
});

$('#cam_zoom_out').mousehold(function(e, ctr){
  canvas_ui.camera.zoom(20);
});

$('#cam_zoom_in').mousehold(function(e, ctr){
  canvas_ui.camera.zoom(-20);
});

}

////////////////////// various custom inputs

// close canvas view
$('#motel_close_canvas').live('click', function(e){
  $('#motel_canvas_container').hide();
});

// toggle grid on canvas
$('#motel_toggle_grid_canvas').live('click', function(e){
  canvas_ui.setup_scene();
});

// view entities container info
$('.motel_entities_container').live('mouseenter', function(e){
  var container = $(e.currentTarget).attr('id');
  container = container.substring(6, container.length - 10);
  $('#' + container + '_list').show();
});

// hide entities container info
$('.motel_entities_container').live('mouseleave', function(e){
  var container = $(e.currentTarget).attr('id');
  container = container.substring(6, container.length - 10);
  $('#' + container + '_list').hide();
});

// show ship details
$('.command_view_ship').live('click', function(e){
  var ship;
  for(var loc in client.locations){
    var loco = client.locations[loc];
    if(loco.entity.json_class == "Manufactured::Ship" &&
       e.currentTarget.id == loco.entity.id){
         ship = loco.entity;
         break;
       }
  }
  controls.show_ship_details(ship);
});

// trigger jump gate
$('#command_jumpgate_trigger').live('click', function(e){
  //console.log("triggered");
  //console.log(controls.selected_gate.endpoint);

  // find remote system
  var remote_system = null;
  for(var loc in client.locations){
    var loco = client.locations[loc];
    if(loco.entity.json_class == "Cosmos::SolarSystem" &&
       loco.entity.name == controls.selected_gate.endpoint){
         remote_system = loco.entity;
         break;
    }
  }

  handlers.clear_callbacks();
  handlers.add_callback(handlers.handle_ships);

  // grab ships around gate in current system
  for(loc in client.locations){
    var loco = client.locations[loc];
    if(loco.entity.json_class == "Manufactured::Ship"  &&
       loco.entity.user_id == client.current_user.id   &&
       loco.entity.solar_system.name == client.current_system.name &&
       loco.within_distance(controls.selected_gate.location.x,
                            controls.selected_gate.location.y,
                            controls.selected_gate.location.z,
                            controls.selected_gate.trigger_distance)){
      // move to new system
      loco.parent_id = remote_system.location.id;
      client.move_entity(loco.entity.id, loco);
      break;
    }
  }
});

$('#command_selection_clear').live('click', function(e){
  $('#motel_entity_container').hide();
  for(var s in controls.selected_ships)
    controls.selected_ships[s].selected = false;
  controls.selected_ships = [];
  controls.selected_ship = null;
  controls.selected_gate = null;
  canvas_ui.setup_scene();
});

$('#command_fleet_create').live('click', function(e){
  handlers.clear_callbacks();

  var shnames = [];
  for(var s in controls.selected_ships)
    shnames.push(controls.selected_ships[s].id);
  client.create_entity(new JRObject('Manufactured::Fleet',
                                    {'id'      : 'fleet123',
                                     'user_id' : client.current_user.id,
                                     'ships'   : shnames}));
});

$('#command_ship_select_destination').live('click', function(e){
  // TODO also provide ability to auto-select coordinates of
  //      stations, gates, and other entities in current system
  var select = "Coordinates To Move To:<br/>";
  if(controls.selected_ships.length > 0 && client.current_system != null)
    select += "(currently @: "+controls.selected_ships[0].location.to_s()+")<br/><br/>"
  select += "x: <input type='text' id='destination_x_coord' class='destination_coord' />";
  select += "y: <input type='text' id='destination_y_coord' class='destination_coord' />";
  select += "z: <input type='text' id='destination_z_coord' class='destination_coord' /><br/>";
  select += "<input type='button' id='command_ship_move' value='move' />";
  $('#motel_dialog').html(select).dialog({show: 'explode'}).
                                  dialog('option', 'title', 'select destination').
                                  dialog('open');
});

$('#command_ship_move').live('click', function(e){
  var dest_x = parseFloat($('#destination_x_coord').attr('value'));
  var dest_y = parseFloat($('#destination_y_coord').attr('value'));
  var dest_z = parseFloat($('#destination_z_coord').attr('value'));
  $('#motel_dialog').dialog('close');

   var shi = 0;
   for(var sh in controls.selected_ships){
     var new_loc = new Location();
     new_loc.x = dest_x + (shi * 2); new_loc.y = dest_y + (shi * 2); new_loc.z = dest_z + (shi * 2);
     new_loc.id = controls.selected_ships[sh].location.id;
     new_loc.parent_id = client.current_system.location.id;
     client.move_entity(controls.selected_ships[sh].id, new_loc);
     shi = (shi + 1) * -1;
   }
});

$('#command_ship_select_target').live('click', function(e){
  var targets = "<ul>";
  for(var l in client.locations){
    var loc = client.locations[l];
    if(controls.selected_ship.location.within_distance(loc.x, loc.y, loc.z, controls.selected_ship.attack_distance) &&
       loc.entity && loc.entity.json_class == "Manufactured::Ship" &&
       loc.entity.system.name == client.current_system.name &&
       $.inArray(loc.entity, controls.selected_ships) == -1)
         targets += "<li id='"+loc.entity.id+"' class='command_ship_attack' ><a href='#'>" + loc.entity.id + "</a></li>"
  }
  targets += "</ul>";
  $('#motel_dialog').html(targets).dialog({show: 'explode'}).
                                   dialog('option', 'title', 'select attack target').
                                   dialog('open');
});

$('#command_ship_select_dock').live('click', function(e){
  var stations = "<ul>";
  for(var l in client.locations){
    var loc = client.locations[l];
    if(loc.entity && loc.entity.json_class == "Manufactured::Station" &&
       loc.entity.system.name == client.current_system.name &&
       controls.selected_ship.location.within_distance(loc.x, loc.y, loc.z, loc.entity.docking_distance))
         stations += "<li id='"+loc.entity.id+"' class='command_ship_dock' ><a href='#'>" + loc.entity.id + "</a></li>"
  }
  stations += "</ul>";
  $('#motel_dialog').html(stations).dialog({show: 'explode'}).
                                    dialog('option', 'title', 'select station to dock at').
                                    dialog('open');
});

$('.command_ship_attack').live('click', function(e){
  handlers.clear_callbacks();
  handlers.add_callback(handlers.handle_ships);
  handlers.add_method('manufactured::event_occurred', handlers.on_attacked_event);

  $('#motel_dialog').dialog('close');
  for(var s in controls.selected_ships)
    client.attack_entity(controls.selected_ships[s], e.currentTarget);
});

$('.command_ship_dock').live('click', function(e){
  handlers.clear_callbacks();
  handlers.add_callback(handlers.handle_ships);

  $('#motel_dialog').dialog('close');
  client.dock_ship(controls.selected_ship.id, e.currentTarget.id);
  $('#command_ship_undock').show();
  $('#command_ship_select_dock').hide();
  $('#command_ship_select_transfer_resource').show();
});

$('#command_ship_undock').live('click', function(e){
  handlers.clear_callbacks();
  handlers.add_callback(handlers.handle_ships);

  client.undock_ship(controls.selected_ship.id);
  $('#command_ship_undock').hide();
  $('#command_ship_select_dock').show();
  $('#command_ship_select_transfer_resource').hide();
});

$('#command_ship_select_transfer_resource').live('click', function(e){
  var transfer = 'Select resource to transfer';
  transfer += "<ul>";
  for(var resource in controls.selected_ship.resources){
    var quantity = controls.selected_ship.resources[resource];
    transfer += "<li><a href='#' class='command_ship_transfer_resource'"+
                "id='"+controls.selected_ship.id + ":" + controls.selected_ship.docked_at.id + ":" + resource + ":" + quantity +"'>"+
                quantity + " of " + resource + " -> " + controls.selected_ship.docked_at.id +
                "</a></li>";
  }
  for(var resource in controls.selected_ship.docked_at.resources){
    var quantity = controls.selected_ship.docked_at.resources[resource];
    transfer += "<li><a href='#' class='command_ship_transfer_resource'" +
                "id='"+controls.selected_ship.docked_at.id + ":" + controls.selected_ship.id + ":" + resource + ":" + quantity + "'>" +
                quantity + " of " + resource + " -> " + controls.selected_ship.id +
                "</a></li>";
  }
  transfer += "<ul>";
  $('#motel_dialog').html(transfer).dialog({show: 'explode'}).
                                    dialog('option', 'title', 'select resource to transfer').
                                    dialog('open');
});

$('.command_ship_transfer_resource').live('click', function(e){
  handlers.clear_callbacks();
  handlers.add_callback(handlers.handle_ships);
  handlers.add_callback(handlers.handle_stations);
  var tr = e.currentTarget.id.split(":");
  client.transfer_resource(tr[0], tr[1], tr[2], parseFloat(tr[3]));
  $('#motel_dialog').dialog('close');
});

$('#command_ship_select_mining').live('click', function(e){
  var mining = '<ul>';
  for(var l in client.locations){
    var loc = client.locations[l];
    if(controls.selected_ship.location.within_distance(loc.x, loc.y, loc.z, controls.selected_ship.mining_distance) &&
       loc.entity.json_class == "Cosmos::Asteroid" &&
       loc.entity.system.name == client.current_system.name){
         mining += "<li id='" + loc.entity.name + "' class='command_scan_asteroid'><a href='#'>" + loc.entity.name + "</a></li>";
    }
  }
  mining += "</ul>";
  $('#motel_dialog').html(mining).dialog({show: 'explode'}).
                                  dialog('option', 'title', 'select asteroid to scan').
                                  dialog('open');
});

$('.command_scan_asteroid').live('click', function(event){
  handlers.clear_callbacks();
  handlers.add_callback(handlers.handle_resource_sources);
  handlers.add_callback(handlers.populate_asteroid_resources);
  client.get_resource_sources(event.currentTarget.id);
});

$('.command_mine_resource_source').live('click', function(event){
  handlers.clear_callbacks();
  handlers.add_method('manufactured::event_occurred', handlers.on_mining_event);
  var rs = event.currentTarget.id.split(":");
  client.start_mining(controls.selected_ship, rs[0], rs[1]);
  $('#motel_dialog').dialog('close');
});

$('#command_station_select_construction').live('click', function(event){
  // TODO prompt user for which type of ship to construct
  handlers.clear_callbacks();
  handlers.add_callback(handlers.handle_ships);
  client.construct_ship(controls.selected_station);
});

$('.galaxy_title').live('click', function(event){
  handlers.set_galaxy(event.currentTarget.id);
});

$('.solar_system_title').live('click', function(event){
  handlers.set_system(event.currentTarget.id);
});

$('.fleet_title').live('click', function(event){
  handlers.set_system($(event.currentTarget).attr('system_id'));
});

$('.alliance_title').live('click', function(event){
  var entity_container = $('#motel_entity_container');
  var selected_alliance = $(event.currentTarget).attr('id');
  var allianceo = client.user_alliances[selected_alliance];
  entity_container.show();
  var entity_container_contents = "Alliance: " + selected_alliance +
                                  "<br/>Members: ";
  for(var m in allianceo.member_ids)
    entity_container_contents += allianceo.member_ids[m] + " "
  entity_container_contents += "<br/>Enemies: ";
  for(var e in allianceo.enemy_ids)
    entity_container_contents += allianceo.enemy_ids[e] + " "
  entity_container.html(entity_container_contents);
});

$('#motel_chat_input input[type=button]').live('click', function(event){
  var message = $('#motel_chat_input input[type=text]').attr('value');
  client.send_message(message);
  $("#motel_chat_output textarea").append(client.current_user.id + ": " + message + "\n");
  $('#motel_chat_input input[type=text]').attr('value', '');
});

$('#login_dialog_link').live('click', function(event){
  var html  = 'Username: <input type="text" id="user_username" />';
      html += 'Password: <input type="password" id="user_password" />';
      html += '<input type="button" id="login_link" value="login" />';
  $('#motel_dialog').html(html).dialog({ show: 'explode' }).
                                dialog('option', 'title', 'login').dialog('open');
});

$('#create_account_dialog_link').live('click', function(event){
  var html  = 'Username: <input type="text" id="user_username" />';
      html += '<br/>Password: <input type="password" id="user_password" />';
      html += '<br/>Email: <input type="text" id="user_email" />';
      html += '<br/><div id="omega_recaptcha"></div>';
      html += "<br/>By submitting this form, you are agreeing to The Omegaverse <a href='/wiki/Terms_of_Use'>Terms of Use</a><br/>";
      html += '<br/><input type="button" id="create_account_link" value="confirm" />';
  $('#motel_dialog').html(html).dialog({title: 'create account'}).dialog('open');
  // FIXME make recaptcha public key variable / configurable
  Recaptcha.create("6LflM9QSAAAAAHsPkhWc7OPrwV4_AYZfnhWh3e3n", "omega_recaptcha",
                   { theme: "red", callback: Recaptcha.focus_response_field});
});

$('#login_link').live('click', function(event){
  handlers.clear_callbacks();
  handlers.add_callback(handlers.create_session);

  $('#motel_dialog').dialog('close');

  // populate login details from dialog
  client.current_user.id = $('#user_username').attr('value');
  client.current_user.password = $('#user_password').attr('value');
  //client.current_user.id = 'mmorsi';
  //client.current_user.password = 'foobar';

  client.login();
});

$('#logout_link').live('click', function(event){
  handlers.clear_callbacks();

  client.logout();
});


$('#create_account_link').live('click', function(event){
  handlers.clear_callbacks();
  handlers.add_callback(handlers.create_account_confirmation);

  // populate login details from dialog
  client.current_user.id = $('#user_username').attr('value');
  client.current_user.password = $('#user_password').attr('value');
  client.current_user.email    = $('#user_email').attr('value');
  client.current_user.recaptcha_challenge = Recaptcha.get_challenge();
  client.current_user.recaptcha_response  = Recaptcha.get_response();

  client.create_account();
});

$('#account_info_update').live('click', function(event){
  handlers.clear_callbacks();
  handlers.add_callback(handlers.populate_user_info);

  var pass1 = $('#user_password').attr('value');
  var pass2 = $('#user_confirm_password').attr('value');
  if(pass1 != pass2){
    alert("passwords do not match");
    return;
  }

  // set email here so that it can just be pulled again when user is returned
  var email = $('#user_email').attr('value');

  client.current_user.email = email;
  client.current_user.password = pass1;
  client.update_account();
});

$('#.omega_display_stats').live('click', function(event){
  var selected_stat = $(event.currentTarget).attr('id');
  selected_stat = selected_stat.slice(6);
  $('#omega_stats_content div').hide();
  $('#omega_' + selected_stat + '_stats').show();
});
