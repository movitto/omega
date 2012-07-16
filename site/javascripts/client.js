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
    client.ws_node.onerror   = function(e){ if(handlers.onerror) handlers.onerror(e); };
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

  this.add_user = function(user){
    var key = user.id;
    if(!client.users[key])
      client.users[key] = new User();
    client.users[key].update(user);
  }

  this.track_movement = function(id, min_distance){
    client.ws_node.invoke_request('motel::track_movement', id, min_distance);
  }

  this.get_cosmos_entity = function(entity, name){
    if(name == null){
      client.web_node.invoke_request('cosmos::get_entity', 'of_type', entity);
    }else{
      client.web_node.invoke_request('cosmos::get_entity', 'of_type', entity, 'with_name', name);
    }
  }

  this.get_entities_under = function(parent_id){
    client.web_node.invoke_request('manufactured::get_entities', 'under', parent_id);
  }

  this.get_entities_for_user = function(user_id, entity_type){
    client.web_node.invoke_request('manufactured::get_entities', 'owned_by', user_id, 'of_type', entity_type);
  }

  this.move_entity = function(id, new_location){
    client.web_node.invoke_request('manufactured::move_entity', id, new_location);
  }

  this.create_entity = function(entity){
    client.web_node.invoke_request('manufactured::create_entity', entity);
  }

  this.get_users = function(){
    client.web_node.invoke_request('users::get_entities', 'of_type', 'Users::User');
  }

  this.get_user_info = function(){
    client.web_node.invoke_request('users::get_entity', 'with_id', client.current_user.id)
  }

  this.send_message = function(message){
    client.web_node.invoke_request('users::send_message', message);
  }

  this.subscribe_to_messages = function(){
    client.ws_node.invoke_request('users::subscribe_to_messages');
  }

  this.subscribe_to_attacked_events = function(defender){
    client.ws_node.invoke_request('manufactured::subscribe_to', defender.id, 'defended');
    client.ws_node.invoke_request('manufactured::subscribe_to', defender.id, 'defended_stop');
    client.ws_node.invoke_request('manufactured::subscribe_to', defender.id, 'destroyed');
  }

  this.attack_entity = function(attacker, defender){
    client.subscribe_to_attacked_events(defender);
    client.web_node.invoke_request('manufactured::attack_entity', attacker.id, defender.id);
  }

  this.dock_ship = function(ship, station){
    client.web_node.invoke_request('manufactured::dock', ship, station);
  }

  this.undock_ship = function(ship){
    client.web_node.invoke_request('manufactured::undock', ship);
  }

  this.transfer_resource = function(from_entity_id, to_entity_id, resource, quantity){
    client.web_node.invoke_request('manufactured::transfer_resource', from_entity_id, to_entity_id, resource, quantity);
  }

  this.get_resource_sources = function(entity_id){
    client.web_node.invoke_request('cosmos::get_resource_sources', entity_id);
  }

  this.construct_ship = function(station){
    client.web_node.invoke_request('manufactured::construct_entity', station.id, 'Manufactured::Ship');
  }

  this.subscribe_to_mining_events = function(ship){
    client.ws_node.invoke_request( 'manufactured::subscribe_to', ship.id, 'resource_collected');
    client.ws_node.invoke_request( 'manufactured::subscribe_to', ship.id, 'resource_depleted');
  }


  this.start_mining = function(ship, entity_id, resource_id){
    client.subscribe_to_mining_events(ship);
    client.web_node.invoke_request('manufactured::start_mining', ship.id, entity_id, resource_id);
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
