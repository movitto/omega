function CosmosControls(){
  // selected entities
  this.selected_ships = [];
  this.selected_gate  = null;

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
}

// handle click input
$('#motel_canvas').live('click', function(e){
  var x = Math.floor(e.pageX-$("#motel_canvas").offset().left - ui.width / 2);
  var y = Math.floor(ui.height / 2 - (e.pageY-$("#motel_canvas").offset().top));
  var clicked_on_entity = false;

  for(loc in client.locations){
    var loco = client.locations[loc];
    if(loco && loco.within_distance(x, y, 25)){
// FIXME also ensure loco is in current galaxy/system
      clicked_on_entity = true;
      if(loco.entity.json_class == "Cosmos::SolarSystem"){
        client.set_system(loco.entity.name);

      }else if(loco.entity.json_class == "Cosmos::Planet"){
        var entity_container = $('#motel_entity_container');
        entity_container.show();
        entity_container.html("Planet: " + loco.entity.name);

      }else if(loco.entity.json_class == "Manufactured::Ship"){
        var entity_container = $('#motel_entity_container');
        if(!e.shiftKey){
          for(var s in controls.selected_ships)
            controls.selected_ships[s].selected = false;
          controls.selected_ships = [];
        }
        loco.entity.selected = true;
        controls.selected_ships.push(loco.entity);
        entity_container.show();
        var entity_container_contents = controls.selected_ships.length > 1 ? 'Ships:' : 'Ship:';
        for(var s in controls.selected_ships)
          entity_container_contents += " " + controls.selected_ships[s].id;
        entity_container_contents += "<br/><a href='#' id='command_selection_clear'>clear selection</a>";
        entity_container_contents += "<br/><a href='#' id='command_ship_select_target'>attack</a>";
        if(controls.selected_ships.length > 1)
          entity_container_contents += "<br/><a href='#' id='command_fleet_create'>create fleet</a>";
        entity_container.html(entity_container_contents);

      }else if(loco.entity.json_class == "Manufactured::Station"){
        var entity_container = $('#motel_entity_container');
        entity_container.show();
        entity_container.html("Station: " + loco.entity.id);

      }else if(loco.entity.json_class == "Cosmos::JumpGate"){
        var entity_container = $('#motel_entity_container');
        controls.selected_gate = loco.entity;
        entity_container.show();
        entity_container.html("JumpGate to: " + loco.entity.endpoint +
                              "<br/><a href='#' id='command_jumpgate_trigger'>Trigger</a>");
      }
    }
  }

  if(!clicked_on_entity){
    if(controls.selected_ships.length > 0 && client.current_system != null){
      var shi = 0;
      for(var sh in controls.selected_ships){
        var new_loc = new Location();
        new_loc.x = x + (shi * 2); new_loc.y = y + (shi * 2);
        client.move_entity(controls.selected_ships[sh].id, client.current_system.name, new_loc);
        client.track_location(controls.selected_ships[sh].location.id, 25);
        shi = (shi + 1) * -1;
        // FIXME when ship arrives on location, unregister handler
      }
    }
  }
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
  //console.log(controls.selected_gate);

  // grab ships around gate in current system
  // TODO only current user's ships
  var current_system = null;
  for(loc in client.locations){
    var loco = client.locations[loc];
    if(loco.entity.json_class == "Manufactured::Ship"  &&
       loco.entity.solar_system.name == client.current_system.name &&
       loco.within_distance(controls.selected_gate.location.x,
                            controls.selected_gate.location.y,
                            50)){
      //current_system = client.current_system;
      // move to new system
      client.move_entity(loco.entity.id, controls.selected_gate.endpoint);
      break;
    }
  }
});

$('#command_selection_clear').live('click', function(e){
  $('#motel_entity_container').hide();
  for(var s in controls.selected_ships)
    controls.selected_ships[s].selected = false;
  controls.selected_ships = [];
});

$('#command_fleet_create').live('click', function(e){
  var shnames = [];
  for(var s in controls.selected_ships)
    shnames.push(controls.selected_ships[s].id);
  client.create_entity(new JRObject('Manufactured::Fleet',
                                    {'id'      : 'fleet123',
                                     'user_id' : client.current_user,
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

$('.command_ship_attack').live('click', function(e){
  $('#motel_dialog').dialog('close');
  for(var s in controls.selected_ships)
    client.attack_entity(controls.selected_ships[s].id, e.currentTarget.id);
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
