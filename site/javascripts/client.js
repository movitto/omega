function CosmosClient() {
  var client = this;
  this.current_user   = new User();
  this.current_galaxy = null;
  this.current_system = null;

  this.locations = [];
  this.users     = [];
  this.user_alliances  = [];
  //this.allied_users  = [];
  //this.enemy_alliances = [];
  //this.enemy_users     = [];

  this.connect = function(){
    client.web_node = new WebNode('http://localhost/motel');
    client.ws_node  = new WSNode('127.0.0.1', '8080');
    client.ws_node.open();

    client.ws_node.onopen    = function(){ if(handlers.onopen) handlers.onopen(); };
    client.ws_node.onsuccess = function(result)     { handlers.invoke_callbacks(result); }
    client.ws_node.onfailed  = function(error, msg) { handlers.invoke_error_handlers(error, msg);  }
    //client.ws_node.message_received = function(msg) { }
    client.ws_node.invoke_method  = function(method, params){ handlers.invoke_methods(method, params); }
        
    client.web_node.onsuccess = function(result)     { handlers.invoke_callbacks(result); }
    client.web_node.onfailed  = function(error, msg) { handlers.invoke_error_handlers(error, msg);  }
    //client.web_node.message_received = function(msg) { }
  };
  this.disconnect = function(){
    client.ws_node.close();
  }

  this.clear_locations = function(){
    client.locations = [];
  }
  this.add_location  = function(loc){
    var key = "l" + loc.id;
    if(!client.locations[key])
      client.locations[key] = new Location();
    client.locations[key].update(loc);
  }

  this.track_movement = function(id, min_distance){
    client.ws_node.invoke_request('track_movement', id, min_distance);
  }

  this.get_cosmos_entity = function(entity, name){
    client.web_node.invoke_request('cosmos::get_entity', entity, name);
  }

  this.get_entities_under = function(parent_id){
    client.web_node.invoke_request('manufactured::get_entities_under', parent_id);
  }

  this.get_entities_for_user = function(user_id, entity_type){
    client.web_node.invoke_request('manufactured::get_entities_for_user', user_id, entity_type);
  }

  this.move_entity = function(id, new_location){
    client.web_node.invoke_request('manufactured::move_entity', id, new_location);
  }

  this.create_entity = function(entity){
    client.web_node.invoke_request('manufactured::create_entity', entity);
  }

  this.get_user_info = function(){
    client.web_node.invoke_request('users::get_entity', client.current_user.id)
  }

  this.send_message = function(message){
    client.web_node.invoke_request('users::send_message', client.current_user.id, message);
  }

  this.subscribe_to_messages = function(){
    client.ws_node.invoke_request('users::subscribe_to_messages', client.current_user.id);
  }

  this.attack_entity = function(attacker, defender){
    // TODO should subscribe to these events in another location
    client.ws_node.invoke_request('manufactured::subscribe_to', defender, 'attacked');
    client.ws_node.invoke_request('manufactured::subscribe_to', defender, 'attacked_stop');
    client.ws_node.invoke_request('manufactured::subscribe_to', defender, 'destroyed');
    client.web_node.invoke_request('manufactured::attack_entity', attacker, defender);
  }

  this.dock_ship = function(ship, station){
    client.web_node.invoke_request('manufactured::dock', ship, station);
  }

  this.undock_ship = function(ship){
    client.web_node.invoke_request('manufactured::undock', ship);
  }

  this.login = function(){
    client.web_node.invoke_request('users::login', client.current_user);
  }

  this.logout = function(){
    client.web_node.invoke_request('users::logout', client.current_user.session_id);
    client.current_user.destroy_session(client);
  }

  this.create_account = function(){
    client.web_node.invoke_request('users::register', client.current_user);
  }

  this.update_account = function(){
    client.web_node.invoke_request('users::update_user', client.current_user);
  }

};