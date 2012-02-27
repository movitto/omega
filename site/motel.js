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

  this.toJSON = function(){ return new JRObject("Motel::Location", this).toJSON(); };
  //JRObject.class_registry['Motel::Location'] = Location;
};

function CosmosClient() {
  var client = this;
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
};

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
          context.moveTo(loco.x     + width/2, loco.y     + height/2);
          context.lineTo(endpoint.x + width/2, endpoint.y + height/2);
          context.stroke();
        }
      }

      // draw circle representing system
      context.beginPath();
      context.strokeStyle = "#FFFFFF";
      context.arc(loco.x + width/2, loco.y + height/2, 15, 0, Math.PI*2, true);
      context.fill();

    }else if(loco.entity.json_class == "Cosmos::Planet"){
      // draw orbit path
      var orbit = loco.movement_strategy.orbit;
      context.beginPath();
      for(orbiti in orbit){
        var orbito = orbit[orbiti];
        context.lineTo(orbito[0] + width/2, orbito[1] + height/2);
      }
      context.strokeStyle = "#AAAAAA";
      context.stroke();

      // draw circle representing planet
      context.beginPath();
      context.fillStyle = "#" + loco.entity.color;
      context.arc(loco.x + width/2, loco.y + height/2, 15, 0, Math.PI*2, true);
      context.fill();

    }else if(loco.entity.json_class == "Cosmos::Star"){
      // draw circle representing star
      context.beginPath();
      context.fillStyle = "#FFFF00";
      context.arc(loco.x + width/2, loco.y + height/2, 15, 0, Math.PI*2, true);
      context.fill();
    }
  }
}

$(document).ready(function(){
  setInterval(draw, 5);
});
