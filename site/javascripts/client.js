// helper to determine if entity is an array
// http://www.hunlock.com/blogs/Mastering_Javascript_Arrays#quickIDX34
function isArray(testObject) {  
  return testObject && !(testObject.propertyIsEnumerable('length')) && typeof testObject === 'object' && typeof testObject.length === 'number';
}

function onopen(client){
  client.get_cosmos_entity('galaxy');
  client.get_entities_for_user(client.current_user.id, 'Manufactured::Fleet');
  client.get_user_info();
  client.subscribe_to_messages();
}

function onsuccess(client, result){
  if(result == null)
    return;

  if(isArray(result)){
    if(result.length < 1)
      return;

    // returned when we invoke client.get_cosmos_entity('galaxy')
    else if(result[0].json_class == "Cosmos::Galaxy"){
      var data  = "<span class='motel_entities_container_title'>Locations:</span><ul>"

      for(var g = 0; g < result.length; ++g){
        var galaxy = result[g];
        data += "<li><span id='" + galaxy.name + "' class='entity_title galaxy_title'>" + galaxy.name + "</span></li>";
        data += "<ul>";

        var galaxy_systems = []
        var galaxy_gates   = [];
        for(var s = 0; s < galaxy.solar_systems.length; ++s){
          var system = galaxy.solar_systems[s];
          galaxy_systems.push(system);
          system.galaxy = galaxy;
          system.location.entity = system;
          system.size = 15;
          client.add_location(system.location);

          var sname = system.name;
          data += "<li>";
          data += "<span id='" + sname + "'class='entity_title solar_system_title'>" + sname + "</span>";
          data += "<ul>";

          system.star.system = system;
          system.star.location.entity = system.star;
          system.star.size = 15;
          client.add_location(system.star.location);

          for(var p=0; p<system.planets.length; ++p){
            var planet = system.planets[p];
            planet.system = system;
            planet.location.entity = planet;
            planet.size = 15;
            client.add_location(planet.location);

            var pname = galaxy.solar_systems[s].planets[p].name;
            data += "<li>" + pname + "</li>";
          }
          data += "</ul>";

          for(var j=0; j<system.jump_gates.length; ++j){
            var gate = system.jump_gates[j];
            galaxy_gates.push(gate);
            gate.system = system;
            gate.location.entity = gate;
            gate.size = 30;
            client.add_location(gate.location);
          }

          // get ships/stations/fleets in each system
          // TODO should this go in a better location ? 
          client.get_entities_under(system.name);
        }
        data += "</ul>";

        // wire up gates
        for(var gg in galaxy_gates){
          var gate = galaxy_gates[gg];
          for(var s in galaxy_systems){
            var system = galaxy_systems[s];
            if(gate.endpoint == system.name){
              gate.endpoint_system = system;
              break;
            }
          }
        }

      }
      data += "</ul>";
      $("#motel_locations_container").html(data);

    //}else if(result.json_class == 'Motel::Location'){
    //  result.draw = ui.draw_nothing;
    //  client.add_location(result);

    // returned when get invoke client.get_entities_under(system)
    }else if((result[0].json_class == "Manufactured::Ship" ||
              result[0].json_class == "Manufactured::Station")){
      for(var e=0;e<result.length;++e){
        var entity = result[e];
        // XXX hack this array can contain fleets too as
        // this will be invoked when get_entites_under is called
        if(entity.location){
          entity.location.entity = entity;
          entity.system = entity.solar_system;
          entity.size = 30;
          client.add_location(entity.location);
        }
      }

    // returned when get invoke client.get_enities_for_user(current_user, fleet)
    }else if(result[0].json_class == "Manufactured::Fleet"){
      data  = "<span class='motel_entities_container_title'>Fleets:</span><ul>"
      for(var f=0;f<result.length;++f){
        var fleet = result[f];
        data += "<li><span id='" + fleet.id + "' class='entity_title fleet_title' system_id='"+fleet.solar_system+"'>" + fleet.id + " (" + fleet.solar_system + ") </span></li>";
      }
      data += "</ul>";
      $("#motel_fleets_container").html(data);
    }

  // returned when we invoke client.move_entity
  }else if(result.json_class == "Manufactured::Ship"){
    result.location.entity = result;
    result.system = result.solar_system;
    result.size = 30;
    client.add_location(result.location);

    // refresh current system
    // XXX hack this is here for when we move ships between systems
    if(client.current_system) client.set_system(client.current_system.name);

  // returned when we invoke client.get_user_info
  }else if(result.json_class == "Users::User"){
    client.users[result.id] = result;
    var data  = "<span class='motel_entities_container_title'>Alliances:</span><ul>";
    for(var a in result.alliances){
      var alliance = result.alliances[a];
      client.user_alliances[alliance.id] = alliance;
      data += '<li><span id="' + alliance.id + '" class="entity_title alliance_title">' + alliance.id + '</span></li>';

      //for(var e in result.enemies_ids){
      //  var enemy = result.enemies[e];
      //  // TODO send request for enemy alliance info, store in client.enemy_alliances and client.enemy_users
      //}
    }

    data += "</ul>";
    $('#motel_alliances_container').html(data);

  // returned when we invoke client.login
  }else if(result.json_class == "Users::Session"){
    client.current_user.create_session(result.id, client);
  }
}

function onfailed(client, error, msg){
  //console.log(error);
  //console.log(msg);
}

function invoke_method(client, method, params){
  if(isArray(params)){
    if(params.length < 1)
      return

    else if(method == 'track_location')
      client.add_location(params[0]);

    else if(method == "users::subscribe_to_messages")
      $("#motel_chat_output textarea").append(params[0].nick + ": " + params[0].message + "\n");

    else if(params[0] == "attacked"){
      //console.log('attacked event');
      var attacker = null;
      var defender = null;
      for(var s in client.locations){
        if(client.locations[s].entity.id == params[2].id)
          defender = client.locations[s].entity;
        else if(client.locations[s].entity.id == params[1].id)
          attacker = client.locations[s].entity;
      }
      attacker.attacking = defender;

    }else if(params[0] == "attacked_stop"){
      //console.log('attack_stopped event');

      for(var s in client.locations){
        if(client.locations[s].entity.id == params[1].id){
          client.locations[s].entity.attacking = null;
          break;
        }
      }

    }else if(params[0] == "destroyed"){
      //console.log('destroyed event');
      var remove = null;
      for(var s in client.locations){
        if(client.locations[s].entity.id == params[2].id){
          remove = s;
          break;
        }
      }
      if(remove != null) delete client.locations[remove];
    }
  }
}

function message_received(client, msg){
  //console.log(msg);
}

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

    client.ws_node.onopen    = function(){ onopen(client); };
    client.ws_node.onsuccess = function(result)     { onsuccess(client, result);     }
    client.ws_node.onfailed  = function(error, msg) { onfailed(client, error, msg);  }
    client.ws_node.message_received = function(msg) { message_received(client, msg); }
    client.ws_node.invoke_method  = function(method, params){ invoke_method(client, method, params); }
        
    client.web_node.onsuccess = function(result)     { onsuccess(client, result);     }
    client.web_node.onfailed  = function(error, msg) { onfailed(client, error, msg);  }
    client.web_node.message_received = function(msg) { message_received(client, msg); }
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

  this.set_galaxy = function(galaxy_name){
    client.current_system = null;

    for(var l in client.locations){
      var loco = client.locations[l];
      var entity = loco.entity;

      if(entity.json_class == "Cosmos::Galaxy"){
        if(entity.name == galaxy_name)
          client.current_galaxy = entity;
        loco.draw    = ui.draw_nothing;
        loco.clicked = controls.unregistered_click;

      }else if(entity.json_class == "Cosmos::SolarSystem"){
        if(entity.galaxy.name == galaxy_name){
          loco.draw = function(system) { ui.draw_system(system); }
          loco.clicked = function(clicked_event, system) { controls.clicked_system(clicked_event, system); }
        }else{
          loco.draw    = ui.draw_nothing;
          loco.clicked = controls.unregistered_click;
        }

      }else if(entity.json_class == "Cosmos::Star"       ||
               entity.json_class == "Cosmos::Planet"     ||
               entity.json_class == "Cosmos::JumpGate"   ||
               entity.json_class == "Manufactured::Ship" ||
               entity.json_class == "Manufactured::Station"){
        entity.location.draw    = ui.draw_nothing;
        entity.location.clicked = controls.unregistered_click;
      }

      $('#motel_canvas_container canvas').css('background', 'url("http://localhost/wotel/images/galaxy.png") no-repeat');
      // FIXME also need to stop tracking ship and planet locations
    }
  }

  this.set_system = function(system_name){
    client.current_galaxy = null;
    for(var l in client.locations){
      var loco = client.locations[l];
      var entity = loco.entity;

      if(entity.json_class == "Cosmos::SolarSystem"){
        if(entity.name == system_name)
          client.current_system = entity;
        entity.location.draw    = ui.draw_nothing;
        entity.location.clicked = controls.unregistered_click;

      }else if(entity.json_class == "Cosmos::Star"){
        if(entity.system.name == system_name){
          entity.location.draw = function(star){ ui.draw_star(star); }
          //entity.location.clicked = function(clicked_event, star) { controls.clicked_star(clicked_event, star); }
        }else{
          loco.draw = ui.draw_nothing;
          loco.clicked = controls.unregistered_click;
        }

      }else if(entity.json_class == "Cosmos::Planet"){
        if(entity.system.name == system_name){
          // FIXME update planets location locally automatically,
          // track location at a larger distance for a periodic resync
          client.track_location(loco.id, 7);
          entity.location.draw   = function(planet){ ui.draw_planet(planet); }
          entity.location.clicked = function(clicked_event, planet) { controls.clicked_planet(clicked_event, planet); }
        }else{
          loco.draw = ui.draw_nothing;
          loco.clicked = controls.unregistered_click;
        }

      }else if(entity.json_class == "Cosmos::JumpGate"){
        if(entity.system.name == system_name){
          entity.location.draw = function(gate){ ui.draw_gate(gate); }
          entity.location.clicked = function(clicked_event, gate) { controls.clicked_gate(clicked_event, gate); }
        }else{
          loco.draw = ui.draw_nothing;
          loco.clicked = controls.unregistered_click;
        }

      }else if(entity.json_class == "Manufactured::Ship"){
        if(entity.system.name == system_name){
          entity.location.draw = function(ship){ ui.draw_ship(ship); }
          entity.location.clicked = function(clicked_event, ship) { controls.clicked_ship(clicked_event, ship); }
        }else{
          loco.draw = ui.draw_nothing;
          loco.clicked = controls.unregistered_click;
        }

      }else if(entity.json_class == "Manufactured::Station"){
        if(entity.system.name == system_name){
          entity.location.draw = function(station){ ui.draw_station(station); }
          entity.location.clicked = function(clicked_event, station) { controls.clicked_station(clicked_event, station); }
        }else{
          loco.draw = ui.draw_nothing;
          loco.clicked = controls.unregistered_click;
        }
      }
    }

    $('#motel_canvas_container canvas').css('background', 'url("http://localhost/wotel/images/system.png") no-repeat');
  }

  this.track_location = function(id, min_distance){
    client.ws_node.invoke_request('track_location', id, min_distance);
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

  this.move_entity = function(id, parent_id, new_location){
    client.web_node.invoke_request('manufactured::move_entity', id, parent_id, new_location);
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

  this.login = function(){
    client.web_node.invoke_request('users::login', client.current_user);
  }

  this.logout = function(){
    client.web_node.invoke_request('users::login', client.current_user.session_id);
    client.current_user.destroy_session();
  }

};
