function CosmosControls(){
  // selected entities
  this.selected_ships = [];
  this.selected_ship = null; // will point to first selected ship, null if none
  this.selected_gate  = null;

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

  this.draw = function(){
    if(this.select_box_top_left_x && this.select_box_top_left_y &&
       this.select_box_width      && this.select_box_height){
        ui.context.beginPath();
        ui.context.fillStyle = "rgba(142, 214, 255, 0.5)";
        ui.context.rect(this.select_box_top_left_x + ui.width/2, ui.height/2 - this.select_box_top_left_y,
                     this.select_box_width, this.select_box_height);
        ui.context.fill();
    }
  }

  this.unregistered_click = function(click_event, entity) {}

  this.clicked_system  = function(click_event, system) {
    client.set_system(system.name);
  }

  this.clicked_planet  = function(click_event, planet) {
    var entity_container = $('#motel_entity_container');
    entity_container.show();
    entity_container.html("Planet: " + planet.name);
  }

  this.clicked_gate    = function(click_event, gate) {
    var entity_container = $('#motel_entity_container');
    controls.selected_gate = gate;
    entity_container.show();
    entity_container.html("JumpGate to: " + gate.endpoint +
                          "<br/><div class='command_icon' id='command_jumpgate_trigger'>Trigger</div>");
  }

  this.clicked_ship    = function(click_event, ship) {
    var entity_container = $('#motel_entity_container');
    if(!click_event.shiftKey){
      for(var s in controls.selected_ships)
        controls.selected_ships[s].selected = false;
      controls.selected_ships = [];
      controls.selected_ship  = null;
    }
    ship.selected = true;
    if(controls.selected_ships.length == 0) controls.selected_ship = ship;
    controls.selected_ships.push(ship);
    entity_container.show();
    var entity_container_contents = controls.selected_ships.length > 1 ? 'Ships:' : 'Ship:';
    for(var s in controls.selected_ships)
      entity_container_contents += " " + controls.selected_ships[s].id +
                                   " (" + controls.selected_ships[s].type + ")"
    entity_container_contents += "<br/><div class='command_icon' id='command_selection_clear'>clear selection</div>";
    entity_container_contents += "<div class='command_icon' id='command_ship_select_target'>attack</div>";
    entity_container_contents += "<div class='command_icon' id='command_ship_select_dock'>dock</div>";
    entity_container_contents += "<div class='command_icon' id='command_ship_undock'>undock</div>";
    if(controls.selected_ships.length > 1)
      entity_container_contents += "<br/><a href='#' id='command_fleet_create'>create fleet</a>";
    entity_container.html(entity_container_contents);

    if(!controls.selected_ship.docked_at)
      $('#command_ship_undock').hide();
    else
      $('#command_ship_select_dock').hide();
  }

  this.clicked_station = function(click_event, station) {
    var html = "Station: " + station.id +
               "<br/>Type: " + station.type

    var entity_container = $('#motel_entity_container');
    entity_container.show();
    entity_container.html(html);
  }

  this.clicked_space = function(x, y){
    if(controls.selected_ships.length > 0 && client.current_system != null){
      var shi = 0;
      for(var sh in controls.selected_ships){
        var new_loc = new Location();
        new_loc.x = x + (shi * 2); new_loc.y = y + (shi * 2);
        new_loc.id = controls.selected_ships[sh].location.id;
        new_loc.parent_id = client.current_system.location.id;
        client.move_entity(controls.selected_ships[sh].id, new_loc);
        client.track_movement(controls.selected_ships[sh].location.id, 25);
        shi = (shi + 1) * -1;
        // FIXME when ship arrives on location, unregister handler
      }
    }
  }
}

// handle click input
$('#motel_canvas').live('click', function(e){
  var x = Math.floor(e.pageX-$("#motel_canvas").offset().left - ui.width / 2);
  var y = Math.floor(ui.height / 2 - (e.pageY-$("#motel_canvas").offset().top));
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
  controls.mouse_current_x = Math.floor(e.pageX-$("#motel_canvas").offset().left - ui.width / 2);
  controls.mouse_current_y = Math.floor(ui.height / 2 - (e.pageY-$("#motel_canvas").offset().top));
  controls.update_select_box();
});

// handle mouse down event
$('#motel_canvas').live('mousedown', function(e){
  controls.mouse_down_x = Math.floor(e.pageX-$("#motel_canvas").offset().left - ui.width / 2);
  controls.mouse_down_y = Math.floor(ui.height / 2 - (e.pageY-$("#motel_canvas").offset().top));
  controls.update_select_box();
//console.log("coords: " + x + " / " + y);
});

// handle mouse up event
$('#motel_canvas').live('mouseup', function(e){
  controls.mouse_down_x = null; controls.mouse_down_y = null;
  controls.update_select_box();
});


////////////////////// various custom inputs

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

  // grab ships around gate in current system
  // TODO only current user's ships
  for(loc in client.locations){
    var loco = client.locations[loc];
    if(loco.entity.json_class == "Manufactured::Ship"  &&
       loco.entity.solar_system.name == client.current_system.name &&
       loco.within_distance(controls.selected_gate.location.x,
                            controls.selected_gate.location.y,
                            50)){
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
});

$('#command_fleet_create').live('click', function(e){
  var shnames = [];
  for(var s in controls.selected_ships)
    shnames.push(controls.selected_ships[s].id);
  client.create_entity(new JRObject('Manufactured::Fleet',
                                    {'id'      : 'fleet123',
                                     'user_id' : client.current_user.id,
                                     'ships'   : shnames}));
});

$('#command_ship_select_target').live('click', function(e){
  var targets = "<ul>";
  for(var l in client.locations){
    var loc = client.locations[l];
    // FIXME variable attack distance
    if(controls.selected_ships[0].location.within_distance(loc.x, loc.y, 100) &&
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
    if(controls.selected_ship.location.within_distance(loc.x, loc.y, 100) &&
       loc.entity && loc.entity.json_class == "Manufactured::Station" &&
       loc.entity.system.name == client.current_system.name)
         stations += "<li id='"+loc.entity.id+"' class='command_ship_dock' ><a href='#'>" + loc.entity.id + "</a></li>"
  }
  stations += "</ul>";
  $('#motel_dialog').html(stations).dialog({show: 'explode', title: 'select station to dock at'}).dialog('open');
});

$('.command_ship_attack').live('click', function(e){
  $('#motel_dialog').dialog('close');
  for(var s in controls.selected_ships)
    client.attack_entity(controls.selected_ships[s].id, e.currentTarget.id);
});

$('.command_ship_dock').live('click', function(e){
  $('#motel_dialog').dialog('close');
  client.dock_ship(controls.selected_ship.id, e.currentTarget.id);
  $('#command_ship_undock').show();
  $('#command_ship_select_dock').hide();
});

$('#command_ship_undock').live('click', function(e){
  client.undock_ship(controls.selected_ship.id);
  $('#command_ship_undock').hide();
  $('#command_ship_select_dock').show();
});

$('.galaxy_title').live('click', function(event){
  client.set_galaxy(event.currentTarget.id);
});

$('.solar_system_title').live('click', function(event){
  client.set_system(event.currentTarget.id);
});

$('.fleet_title').live('click', function(event){
  client.set_system($(event.currentTarget).attr('system_id'));
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

$('#login_link').live('click', function(event){
  client.login();
  $('#logout_link').show();
  $('#login_link').hide();
});

$('#logout_link').live('click', function(event){
  client.logout();
  $('#login_link').show();
  $('#logout_link').hide();
});
