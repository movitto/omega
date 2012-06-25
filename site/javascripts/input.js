function CosmosControls(){
  // selected entities
  this.selected_ships = [];
  this.selected_ship = null; // will point to first selected ship, null if none
  this.selected_gate  = null;

  this.gate_trigger_area = 100;

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
      this.selected_gate = null;
    }
  }

  this.clear_selected_ship = function(){
    this.set_selected_ship(null, true);
  }

  this.set_selected_gate = function(gate){
    this.selected_gate = gate;
    this.clear_selected_ship();
  }

  this.set_selected_station = function(station){
    this.selected_station = station;
    this.clear_selected_ship();
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
         this.select_box_width  = this.select_box_bottom_right_x - this.select_box_top_left_x;
         this.select_box_height = this.select_box_top_left_y     - this.select_box_bottom_right_y
    }else{
      this.select_box_top_left_x     = null;
      this.select_box_top_left_y     = null;
      this.select_box_bottom_right_x = null;
      this.select_box_bottom_right_y = null;
      this.select_box_width          = null;
      this.select_box_height         = null;
    }
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
    if(this.select_box_top_left_x && this.select_box_top_left_y &&
       this.select_box_width      && this.select_box_height){
        canvas_ui.context.beginPath();
        canvas_ui.context.fillStyle = "rgba(142, 214, 255, 0.5)";
        canvas_ui.context.rect(this.select_box_top_left_x + canvas_ui.width/2, canvas_ui.height/2 - this.select_box_top_left_y,
                     this.select_box_width, this.select_box_height);
        canvas_ui.context.fill();
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

  this.clicked_asteroid  = function(click_event, asteroid) {
    var entity_container = $('#motel_entity_container');
    var asteroid_data = "Asteroid: " + asteroid.name +
                        " ( @ " + asteroid.location.to_s() + ")" +
                        "<br/>";
    for(var r in asteroid.resources){
      asteroid_data += r.quantity + " of " + r.name + " (" + r.type + ")<br/>";
    }
    this.clear_selected_ship();
    entity_container.show();
    entity_container.html(asteroid_data);
  }

  this.clicked_gate    = function(click_event, gate) {
    var entity_container = $('#motel_entity_container');
    controls.selected_gate = gate;
    controls.set_selected_gate(gate);
    controls.clear_selected_ship();
    entity_container.show();
    entity_container.html("JumpGate to: " + gate.endpoint +
                          "<br/> (@ "+ gate.location.to_s()+")" +
                          "<br/><div class='command_icon' id='command_selection_clear'>clear selection</div>" +
                          "<div class='command_icon' id='command_jumpgate_trigger'>Trigger</div>");
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

  this.clicked_station = function(click_event, station) {
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

    html += "<div class='command_icon' id='command_station_select_construction'>construct ship</div>";

    this.clear_selected_ship();
    var entity_container = $('#motel_entity_container');
    entity_container.show();
    entity_container.html(html);
  }

  this.clicked_space = function(x, y){}
}

// handle click input
$('#motel_canvas').live('click', function(e){
  var x = Math.floor(e.pageX-$("#motel_canvas").offset().left);
  var y = Math.floor(e.pageY-$("#motel_canvas").offset().top);
  var clicked_on_entity = false;

  for(loc in client.locations){
    var loco = client.locations[loc];
    if(loco.check_clicked(x, y)){
      clicked_on_entity = true;
      loco.clicked(e, loco.entity);
    }
  }

  if(!clicked_on_entity)
    controls.clicked_space(x, y);

});

$('#motel_canvas').live('mousemove', function(e){
  controls.mouse_current_x = Math.floor(e.pageX-$("#motel_canvas").offset().left - canvas_ui.width / 2);
  controls.mouse_current_y = Math.floor(canvas_ui.height / 2 - (e.pageY-$("#motel_canvas").offset().top));
  controls.update_select_box();
});

// handle mouse down event
$('#motel_canvas').live('mousedown', function(e){
  controls.mouse_down_x = Math.floor(e.pageX-$("#motel_canvas").offset().left - canvas_ui.width / 2);
  controls.mouse_down_y = Math.floor(canvas_ui.height / 2 - (e.pageY-$("#motel_canvas").offset().top));
  controls.update_select_box();
//console.log("coords: " + x + " / " + y);
});

// handle mouse up event
$('#motel_canvas').live('mouseup', function(e){
  controls.mouse_down_x = null; controls.mouse_down_y = null;
  controls.update_select_box();
});

/////////////////////// camera controls

if(jQuery.fn.mousehold){

$('#cam_inc_x_angle').mousehold(function(e, ctr){
  canvas_ui.camera.rotate('x', 0.01);
});

$('#cam_dec_x_angle').mousehold(function(e, ctr){
  canvas_ui.camera.rotate('x', -0.01);
});

$('#cam_inc_y_angle').mousehold(function(e, ctr){
  canvas_ui.camera.rotate('y', 0.01);
});

$('#cam_dec_y_angle').mousehold(function(e, ctr){
  canvas_ui.camera.rotate('y', -0.01);
});

$('#cam_inc_z_angle').mousehold(function(e, ctr){
  canvas_ui.camera.rotate('z', 0.01);
});

$('#cam_dec_z_angle').mousehold(function(e, ctr){
  canvas_ui.camera.rotate('z', -0.01);
});

$('#cam_inc_x_position').mousehold(function(e, ctr){
  canvas_ui.camera.move('x', 20);
});

$('#cam_dec_x_position').mousehold(function(e, ctr){
  canvas_ui.camera.move('x', -20);
});

$('#cam_inc_y_position').mousehold(function(e, ctr){
  canvas_ui.camera.move('y', 20);
});

$('#cam_dec_y_position').mousehold(function(e, ctr){
  canvas_ui.camera.move('y', -20);
});

$('#cam_inc_z_position').mousehold(function(e, ctr){
  canvas_ui.camera.move('z', 20);
});

$('#cam_dec_z_position').mousehold(function(e, ctr){
  canvas_ui.camera.move('z', -20);
});

}

////////////////////// various custom inputs

// close canvas view
$('#motel_close_canvas').live('click', function(e){
  $('#motel_canvas_container').hide();
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
  // TODO only current user's ships
  for(loc in client.locations){
    var loco = client.locations[loc];
    if(loco.entity.json_class == "Manufactured::Ship"  &&
       loco.entity.solar_system.name == client.current_system.name &&
       loco.within_distance(controls.selected_gate.location.x,
                            controls.selected_gate.location.y,
                            controls.selected_gate.location.z,
                            controls.gate_trigger_area)){
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
  $('#motel_dialog').html(select).dialog({show: 'explode', title: 'select destination'}).dialog('open');
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
     client.track_movement(controls.selected_ships[sh].location.id, 25);
     shi = (shi + 1) * -1;
     // FIXME when ship arrives on location, unregister handler
   }
});

$('#command_ship_select_target').live('click', function(e){
  var targets = "<ul>";
  for(var l in client.locations){
    var loc = client.locations[l];
    // FIXME variable attack distance
    if(controls.selected_ships[0].location.within_distance(loc.x, loc.y, loc.z, 100) &&
       loc.entity && loc.entity.json_class == "Manufactured::Ship" &&
       loc.entity.system.name == client.current_system.name &&
       $.inArray(loc.entity, controls.selected_ships) == -1)
         targets += "<li id='"+loc.entity.id+"' class='command_ship_attack' ><a href='#'>" + loc.entity.id + "</a></li>"
  }
  targets += "</ul>";
  $('#motel_dialog').html(targets).dialog({show: 'explode', title: 'select attack target'}).dialog('open');
});

$('#command_ship_select_dock').live('click', function(e){
  var stations = "<ul>";
  for(var l in client.locations){
    var loc = client.locations[l];
    // FIXME variable docking distance
    if(controls.selected_ship.location.within_distance(loc.x, loc.y, loc.z, 100) &&
       loc.entity && loc.entity.json_class == "Manufactured::Station" &&
       loc.entity.system.name == client.current_system.name)
         stations += "<li id='"+loc.entity.id+"' class='command_ship_dock' ><a href='#'>" + loc.entity.id + "</a></li>"
  }
  stations += "</ul>";
  $('#motel_dialog').html(stations).dialog({show: 'explode', title: 'select station to dock at'}).dialog('open');
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
console.log(controls.selected_ship);
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
  $('#motel_dialog').html(transfer).dialog({show: 'explode', title: 'select resource to transfer'}).dialog('open');
});

$('.command_ship_transfer_resource').live('click', function(e){
  var tr = e.currentTarget.id.split(":");
  client.transfer_resource(tr[0], tr[1], tr[2], tr[3]);
  $('#motel_dialog').dialog('close');
});

$('#command_ship_select_mining').live('click', function(e){
  var mining = '<ul>';
  for(var l in client.locations){
    var loc = client.locations[l];
    // FIXME variable mining distance
    if(controls.selected_ship.location.within_distance(loc.x, loc.y, loc.z, 100) &&
       loc.entity.json_class == "Cosmos::Asteroid" &&
       loc.entity.system.name == client.current_system.name){
         mining += "<li id='" + loc.entity.name + "' class='command_scan_asteroid'><a href='#'>" + loc.entity.name + "</a></li>";
    }
  }
  mining += "</ul>";
  $('#motel_dialog').html(mining).dialog({show: 'explode', title: 'select asteroid to scan'}).dialog('open');
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
  client.start_mining(controls.selected_ship, event.currentTarget.id);
  $('#motel_dialog').dialog('close');
});

$('#command_station_select_construction').live('click', function(event){
  // TODO prompt user for which type of ship to construct, verify resources are sufficient
  handlers.clear_callbacks();
  client.construct_ship(controls.selected_station);
  //handlers.set_system(client.current_system.name); // TODO add ship to list and/or refresh ships in system
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
  $('#motel_dialog').html(html).dialog({title: 'login'}).dialog('open');
});

$('#create_account_dialog_link').live('click', function(event){
  var html  = 'Username: <input type="text" id="user_username" />';
      html += 'Password: <input type="password" id="user_password" />';
      html += 'Email: <input type="text" id="user_email" />';
      html += "<br/>By submitting this form, you are agreeing to The Omegaverse <a href='/wiki/Terms_of_Use'>Terms of Use</a><br/>";
      html += '<input type="button" id="create_account_link" value="confirm" />';
  // TODO recaptcha
  $('#motel_dialog').html(html).dialog({title: 'create account'}).dialog('open');
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

  client.current_user.password = pass1;
  client.update_account();
});

$('#.omega_display_stats').live('click', function(event){
  var selected_stat = $(event.currentTarget).attr('id');
  selected_stat = selected_stat.slice(6);
  $('#omega_stats_content div').hide();
  $('#omega_' + selected_stat + '_stats').show();
});
