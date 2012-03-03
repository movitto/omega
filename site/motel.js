function Location(){
  this.x = 0;
  this.y = 0;
  this.z = 0;
  this.movement_strategy = null;
  this.entity = null;

  this.update = function(new_location){
    this.x = new_location.x;
    this.y = new_location.y;
    this.z = new_location.z;

    if(new_location.movement_strategy)
      this.movement_strategy = new_location.movement_strategy;

    if(new_location.entity)
      this.entity = new_location.entity;
  };

  this.within_distance = function(x, y, distance){
    return Math.sqrt(Math.pow(this.x - x, 2) + Math.pow(this.y - y, 2)) < distance;
  };

  this.toJSON = function(){ return new JRObject("Motel::Location", this).toJSON(); };
  //JRObject.class_registry['Motel::Location'] = Location;
};

function CosmosClient() {
  var client = this;
  this.current_galaxy = null;
  this.current_system = null;
  this.selected_ship  = null;
  this.selected_gate  = null;

  this.locations = [];
  this.connect = function(){
    client.web_node = new WebNode('http://localhost/motel');
    client.ws_node  = new WSNode('127.0.0.1', '8080');
    client.ws_node.open();
    client.ws_node.onopen = function(){
      if(client.onopen)
        client.onopen();
    };
    client.ws_node.onsuccess = function(result){
      if(client.onsuccess)
        client.onsuccess(result);
    };
    client.web_node.onsuccess = function(result){
      if(result.json_class == 'Motel::Location')
        client.add_location(result);

      if(client.onsuccess)
        client.onsuccess(result);
    };
    client.ws_node.onfailed = function(error, msg){
      if(client.onfailed)
        client.onfailed(error, msg);
    };
    client.web_node.onfailed = function(error, msg){
      if(client.onfailed)
        client.onfailed(error, msg);
    };
    client.ws_node.message_received = function(msg){
      if(client.message_received)
        client.message_received(msg);
    };
    client.web_node.message_received = function(msg){
      if(client.onfailed)
        client.message_received(msg);
    };
    client.ws_node.invoke_callback = function(method, params){
      if(method == 'track_location')
        client.add_location(params[0]);

      if(client.invoke_callback)
        client.invoke_callback(method, params);
    };
  };
  this.disconnect = function(){
    client.ws_node.close();
  }

  this.clear_locations = function(){
    client.locations = [];
  }
  this.get_locations = function(){ 
    return client.locations;
  }
  this.add_location  = function(loc){
    var key = "l" + loc.id;
    if(!client.locations[key])
      client.locations[key] = new Location();
    client.locations[key].update(loc);
  }

  this.get_location = function(id){
    client.web_node.invoke_request('get_location', id);
  }

  this.track_location = function(id, min_distance){
    client.ws_node.invoke_request('track_location', id, min_distance);
  }

  this.get_entity = function(entity, name){
    client.web_node.invoke_request('get_entity', entity, name);
  }

  this.get_entities = function(parent_id){
    client.web_node.invoke_request('manufactured::get_entities_under', parent_id);
  }

  this.move_entity = function(id, parent_id, new_location){
    client.web_node.invoke_request('manufactured::move_entity', id, parent_id, new_location);
  }
};

// initialize mouse input
mouse_down_x          = null;
mouse_down_y          = null;
mouse_current_x       = null;
mouse_current_y       = null;

// initialize select box
select_box_top_left_x = null;
select_box_top_left_y = null;
select_box_width      = null;
select_box_height     = null;

function draw(){
  canvas  = $('#motel_canvas')
  context = canvas[0].getContext('2d');
  width   = canvas.width();
  height  = canvas.height();

  // clear drawing area
  context.clearRect(0, 0, width, height);

  for(loc in client.get_locations()){
    loco = client.locations[loc];

    if(loco.entity.json_class == "Cosmos::SolarSystem"){
      // draw jumpgates
      for(var j=0; j<loco.entity.jump_gates.length;++j){
        var jg = loco.entity.jump_gates[j];
        var endpoint = null;
        for(eloc in client.locations){
          if(jg.endpoint == client.locations[eloc].entity.name){
            endpoint = client.locations[eloc];
            break;
          }
        }
        if(endpoint != null){
          context.beginPath();
          context.fillStyle = "#FFFFFF";
          context.moveTo(loco.x     + width/2, height/2 - loco.y    );
          context.lineTo(endpoint.x + width/2, height/2 - endpoint.y);
          context.lineWidth = 2;
          context.stroke();
        }
      }

      // draw circle representing system
      context.beginPath();
      context.strokeStyle = "#FFFFFF";
      context.arc(loco.x + width/2, height/2 - loco.y, 15, 0, Math.PI*2, true);
      context.fill();

      // draw label
      context.font = 'bold 16px sans-serif';
      context.fillText(loco.entity.name, loco.x + width/2 - 25, height/2 - loco.y - 25);

    }else if(loco.entity.json_class == "Cosmos::Planet"){
      // draw orbit path
      var orbit = loco.movement_strategy.orbit;
      context.beginPath();
      context.lineWidth = 2;
      for(orbiti in orbit){
        var orbito = orbit[orbiti];
        context.lineTo(orbito[0] + width/2, height/2 - orbito[1]);
      }
      context.strokeStyle = "#AAAAAA";
      context.stroke();

      // draw circle representing planet
      context.beginPath();
      context.fillStyle = "#" + loco.entity.color;
      context.arc(loco.x + width/2, height/2 - loco.y, 15, 0, Math.PI*2, true);
      context.fill();

      // draw moons
      for(var m=0; m<loco.entity.moons.length; ++m){
        var moon = loco.entity.moons[m];
        context.beginPath();
        context.fillStyle = "#808080";
        context.arc(loco.x + moon.location.x + width/2,
                    height/2 - (loco.y + moon.location.y),
                    5, 0, Math.PI*2, true);
        context.fill();
      }

    }else if(loco.entity.json_class == "Cosmos::Star"){
      // draw circle representing star
      context.beginPath();
      context.fillStyle = "#FFFF00";
      context.arc(loco.x + width/2, height/2 - loco.y, 15, 0, Math.PI*2, true);
      context.fill();
    }else if(loco.entity.json_class == "Cosmos::JumpGate"){
      // draw triangle representing gate
      context.beginPath();
      context.fillStyle = "#00CC00";
      context.moveTo(loco.x + width/2,      height/2 - loco.y - 15);
      context.lineTo(loco.x + width/2 - 15, height/2 - loco.y + 15);
      context.lineTo(loco.x + width/2 + 15, height/2 - loco.y + 15);
      context.lineTo(loco.x + width/2,      height/2 - loco.y - 15);
      context.fill();

      // draw name of system gate is to
      context.font = 'bold 16px sans-serif';
      context.fillText(loco.entity.endpoint, loco.x   + width/2 - 25,
                                             height/2 - loco.y  - 25);

    }else if(loco.entity.json_class == "Manufactured::Ship"){
      // draw crosshairs representing ship
      context.beginPath();
      context.strokeStyle = "#00CC00";
      context.moveTo(loco.x + width/2 + 15, height/2 - loco.y);
      context.lineTo(loco.x + width/2 + 15, height/2 - loco.y - 30);
      context.moveTo(loco.x + width/2,      height/2 - loco.y - 15);
      context.lineTo(loco.x + width/2 + 30, height/2 - loco.y - 15);
      context.lineWidth = 4;
      context.stroke();

    }else if(loco.entity.json_class == "Manufactured::Station"){
      // draw crosshairs representing statin
      context.beginPath();
      context.strokeStyle = "#0000CC";
      context.moveTo(loco.x + width/2 + 15, height/2 - loco.y);
      context.lineTo(loco.x + width/2 + 15, height/2 - loco.y - 30);
      context.moveTo(loco.x + width/2,      height/2 - loco.y - 15);
      context.lineTo(loco.x + width/2 + 30, height/2 - loco.y - 15);
      context.lineWidth = 4;
      context.stroke();
    }
  }

  // draw the select box
  if(select_box_top_left_x && select_box_top_left_y &&
     select_box_width      && select_box_height){
      context.beginPath();
      context.fillStyle = "rgba(142, 214, 255, 0.5)";
      context.rect(select_box_top_left_x + width/2, height/2 - select_box_top_left_y,
                   select_box_width, select_box_height);
      context.fill();
  }
}

function update_select_box(){
  if(mouse_down_x    && mouse_down_y &&
     mouse_current_x && mouse_current_y){
       if(mouse_current_x < mouse_down_x){
         select_box_top_left_x     = mouse_current_x;
         select_box_bottom_right_x = mouse_down_x;
       }else{
         select_box_top_left_x     = mouse_down_x;
         select_box_bottom_right_x = mouse_current_x;
       }

       if(mouse_current_y < mouse_down_y){
         select_box_top_left_y     = mouse_current_y;
         select_box_bottom_right_y = mouse_down_y;
       }else{
         select_box_top_left_y     = mouse_down_y;
         select_box_bottom_right_y = mouse_current_y;
       }
       select_box_width  = select_box_bottom_right_x - select_box_top_left_x;
       select_box_height = select_box_top_left_y     - select_box_bottom_right_y
  }else{
    select_box_top_left_x     = null;
    select_box_top_left_y     = null;
    select_box_bottom_right_x = null;
    select_box_bottom_right_y = null;
    select_box_width          = null;
    select_box_height         = null;
  }
}

// handle click input
$('#motel_canvas').live('click', function(e){
  var canvas  = $('#motel_canvas')
  var width   = canvas.width();
  var height  = canvas.height();
  var x = Math.floor(e.pageX-$("#motel_canvas").offset().left - width / 2);
  var y = Math.floor(height / 2 - (e.pageY-$("#motel_canvas").offset().top));
  var clicked_on_entity = false;

  for(loc in client.get_locations()){
    loco = client.locations[loc];
    if(loco && loco.within_distance(x, y, 25)){
      clicked_on_entity = true;
console.log("clicked on ");
console.log(loco.entity);
      if(loco.entity.json_class == "Cosmos::SolarSystem"){
        client.current_galaxy = null;
        client.current_system = loco.entity.name;
        client.disconnect();
        client.clear_locations();
        client.connect();

      }else if(loco.entity.json_class == "Cosmos::Planet"){
        var entity_container = $('#motel_entity_container');
        entity_container.show();
        entity_container.html("Planet: " + loco.entity.name);

      }else if(loco.entity.json_class == "Manufactured::Ship"){
        var entity_container = $('#motel_entity_container');
        client.selected_ship = loco.entity;
        entity_container.show();
        entity_container.html("Ship: " + loco.entity.id);

      }else if(loco.entity.json_class == "Manufactured::Station"){
        var entity_container = $('#motel_entity_container');
        entity_container.show();
        entity_container.html("Station: " + loco.entity.id);

      }else if(loco.entity.json_class == "Cosmos::JumpGate"){
        var entity_container = $('#motel_entity_container');
        client.selected_gate = loco.entity;
        entity_container.show();
        entity_container.html("JumpGate to: " + loco.entity.endpoint +
                              "<br/><a href='#' id='command_jumpgate_trigger'>Trigger</a>");
      }
    }
  }

  if(!clicked_on_entity){
    if(client.selected_ship != null && client.current_system != null){
      console.log("moving ship");
      var new_loc = new Location();
      new_loc.x = x; new_loc.y = y;
      client.move_entity(client.selected_ship.id, client.current_system, new_loc);
      client.track_location(client.selected_ship.location.id, 25);
      // FIXME when ship arrives on location, unregister handler
    }
  }
});

$('#motel_canvas').live('mousemove', function(e){
  mouse_current_x = Math.floor(e.pageX-$("#motel_canvas").offset().left - width / 2);
  mouse_current_y = Math.floor(height / 2 - (e.pageY-$("#motel_canvas").offset().top));
  update_select_box();
});

// handle mouse down event
$('#motel_canvas').live('mousedown', function(e){
  canvas  = $('#motel_canvas')
  width   = canvas.width();
  height  = canvas.height();
  mouse_down_x = Math.floor(e.pageX-$("#motel_canvas").offset().left - width / 2);
  mouse_down_y = Math.floor(height / 2 - (e.pageY-$("#motel_canvas").offset().top));
  update_select_box();
//console.log("coords: " + x + " / " + y);
});

// handle mouse up event
$('#motel_canvas').live('mouseup', function(e){
  mouse_down_x = null; mouse_down_y = null;
  update_select_box();
});


////////////////////// various custom inputs

// trigger jump gate
$('#command_jumpgate_trigger').live('click', function(e){
  //console.log("triggered");
  //console.log(client.selected_gate);

  // grab ships around gate in current system
  // TODO only current user's ships
  var current_system = null;
  for(loc in client.get_locations()){
    var loco = client.locations[loc];
    if(loco.entity.json_class == "Manufactured::Ship"  &&
       loco.entity.solar_system.name == client.current_system &&
       loco.within_distance(client.selected_gate.location.x,
                            client.selected_gate.location.y,
                            50)){
      //current_system = client.current_system;
      // move to new system
      client.move_entity(loco.entity.id, client.selected_gate.endpoint);

      // refresh current system
      client.disconnect();
      client.clear_locations();
      client.connect();
      break;
    }
  }

  // grab ships around gate & move to new system, refresh old system
});

/////////////////////
$(document).ready(function(){
  setInterval(draw, 5);
});
