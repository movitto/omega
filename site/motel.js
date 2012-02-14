function Location(){
  this.x = 0;
  this.y = 0;
  this.z = 0;
  this.movement_stategy = null;
  this.toJSON = function(){ return new JRObject("Motel::Location", this).toJSON(); };
};

function CosmosClient() {
  client = this;
  this.locations = [];
  this.web_node = new WebNode('http://localhost/motel');
  this.ws_node  = new WSNode('127.0.0.1', '8080');
  this.ws_node.open();
  this.ws_node.onopen = function(){
    if(client.onopen)
      client.onopen();
  };
  this.ws_node.onsuccess = function(result){
    if(client.onsuccess)
      client.onsuccess(result);
  };
  this.web_node.onsuccess = function(result){
    if(client.onsuccess)
      client.onsuccess(result);
  };
  this.ws_node.onfailed = function(error, msg){
    if(client.onfailed)
      client.onfailed(error, msg);
  };
  this.web_node.onfailed = function(error, msg){
    if(client.onfailed)
      client.onfailed(error, msg);
  };
  this.ws_node.message_received = function(msg){
    if(client.message_received)
      client.message_received(msg);
  };
  this.web_node.message_received = function(msg){
    if(clientmessage_receivedonfailed)
      client.message_received(msg);
  };
  this.ws_node.invoke_callback = function(method, params){
    if(method == 'track_location')
      client.add_location(params[0]);
    if(client.invoke_callback)
      client.invoke_callback(method, params);
  };
  this.get_locations = function(){ 
    return this.locations;
  }
  this.add_location  = function(loc){
    this.locations["l" + loc.id] = loc;
  }

  this.track_location = function(id, min_distance){
    this.ws_node.invoke_request('track_location', id, min_distance);
  }

  this.get_entity = function(entity, name){
    this.web_node.invoke_request('get_entity', entity, name);
  }
};

function draw(){
  canvas  = $('#motel_canvas')
  context = canvas[0].getContext('2d');
  width   = canvas.width();
  height  = canvas.height();

  // clear drawing area
  context.fillStyle = '#fff';
  context.fillRect(0, 0, width, height);

  for(loc in client.get_locations()){
    loco = client.locations[loc];
    context.beginPath();
    context.fillStyle = "#000";
    context.arc(loco.x + width/2, loco.y + height/2, 15, 0, Math.PI*2, true);
    context.fill();
  }
}

$(document).ready(function(){
  setInterval(draw, 5);
});
