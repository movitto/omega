// helper to determine if entity is an array
// http://www.hunlock.com/blogs/Mastering_Javascript_Arrays#quickIDX34
function isArray(testObject) {  
  return testObject && !(testObject.propertyIsEnumerable('length')) && typeof testObject === 'object' && typeof testObject.length === 'number';
}

function OmegaHandlers(){
  this.onopen  = null;
  this.onlogin = null;
  this.onlogout = null;

  this.callbacks = [];
  this.error_handlers = [];
  this.methods   = {};

  this.add_callback = function(callback){
    this.callbacks.push(callback);
  };
  this.clear_callbacks = function(){
    this.callbacks = [];
  };
  this.add_method = function(method, handler){
    if(!this.methods[method])
      this.methods[method] = [];
    this.methods[method].push(handler);
  };
  this.add_error_handler = function(handler){
    this.error_handlers.push(handler);
  }

  this.invoke_callbacks = function(result){
    for(var c in this.callbacks){
      this.callbacks[c](result);
    }
  };
  this.invoke_error_handlers = function(error, msg){
    for(var h in this.error_handlers){
      this.error_handlers[h](error, msg);
    }
  };
  this.invoke_methods = function(method, params){
    if(this.methods[method]){
      for(var m in this.methods[method]){
        this.methods[method][m](params);
      }
    }
  };

  ///////////////////////////////// top level handlers
  // TODO better place to put these ?

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
          client.track_movement(loco.id, 7);
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

    $('#motel_canvas_container canvas').css('background', 'url("http://localhost/wotel/images/'+ client.current_system.background +'.png") no-repeat');
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
    }

    $('#motel_canvas_container canvas').css('background', 'url("http://localhost/wotel/images/' + client.current_galaxy.background + '.png") no-repeat');
    // FIXME also need to stop tracking ship and planet locations
  }

  /////////////////// registerable callbacks

  this.handle_galaxies = function(galaxies){
    if(galaxies != null && isArray(galaxies) && galaxies.length > 0){
      for(var g = 0; g < galaxies.length; ++g){
        var galaxy = galaxies[g];
        if(galaxy.json_class == "Cosmos::Galaxy"){
          galaxy.location.entity = galaxy;
          client.add_location(galaxy.location);

          var galaxy_systems = []
          var galaxy_gates   = [];
          for(var s = 0; s < galaxy.solar_systems.length; ++s){
            var system = galaxy.solar_systems[s];
            galaxy_systems.push(system);
            system.galaxy = galaxy;
            system.location.entity = system;
            system.size = 15;
            client.add_location(system.location);

            system.star.system = system;
            system.star.location.entity = system.star;
            client.add_location(system.star.location);

            for(var p=0; p<system.planets.length; ++p){
              var planet = system.planets[p];
              planet.system = system;
              planet.location.entity = planet;
              client.add_location(planet.location);

              var pname = galaxy.solar_systems[s].planets[p].name;
            }

            for(var j=0; j<system.jump_gates.length; ++j){
              var gate = system.jump_gates[j];
              galaxy_gates.push(gate);
              gate.system = system;
              gate.location.entity = gate;
              gate.size = 20;
              client.add_location(gate.location);
            }

            // get ships/stations/fleets in each system
            // TODO should this go in a better location ? 
            client.get_entities_under(system.name);
          }

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
      }
    }
  }

  this.populate_locations_container = function(galaxies){
    if(galaxies != null && isArray(galaxies) && galaxies.length > 0){
      var num_galaxies = 0;
      var data  = "<span class='motel_entities_container_title'>Locations:</span><ul>"
      for(var g = 0; g < galaxies.length; ++g){
        var galaxy = galaxies[g];
        if(galaxy.json_class == "Cosmos::Galaxy"){
          num_galaxies += 1;
          data += "<li><span id='" + galaxy.name + "' class='entity_title galaxy_title'>" + galaxy.name + "</span></li>";
          data += "<ul>";

          for(var s = 0; s < galaxy.solar_systems.length; ++s){
            var system = galaxy.solar_systems[s];
            var sname = system.name;
            data += "<li>";
            data += "<span id='" + sname + "'class='entity_title solar_system_title'>" + sname + "</span>";
            data += "<ul>";

            for(var p=0; p<system.planets.length; ++p){
              var planet = system.planets[p];
              var pname = planet.name;
              data += "<li>" + pname + "</li>";
            }
            data += "</ul>";
          }
          data += "</ul>";
        }
      }
      if(num_galaxies > 0) $("#motel_locations_container").html(data);
    }
  }

  this.handle_ships = function(ships){
    if(ships != null && ships.json_class == "Manufactured::Ship"){
      ships.selected = controls.update_selected_ship(result);
      ships = [ships];
    }

    if(ships != null && isArray(ships) && ships.length > 0){
      var num_ships = 0;
      for(var s = 0; s < ships.length; ++s){
        var ship = ships[s];
        if(ship.json_class == "Manufactured::Ship"){
          num_ships += 1;
          ship.location.entity = ship;
          ship.system = ship.solar_system
          client.add_location(ship.location);
        }
      }

      // refresh current system
      // XXX hack this is here for when we move ships between systems
      if(client.current_system && num_ships > 0)
        handlers.set_system(client.current_system.name);
    }

  }

  this.handle_stations = function(stations){
    if(stations != null && isArray(stations) && stations.length > 0){
      for(var s = 0; s < stations.length; ++s){
        var station = stations[s];
        if(station.json_class == "Manufactured::Station"){
          station.location.entity = station;
          station.system = station.solar_system
          client.add_location(station.location);
        }
      }
    }
  }

  this.set_player_manufactured_entities = function(entities){
    if(entities != null && isArray(entities) && entities.length > 0){
      var data = '';
      for(var e = 0; e < entities.length; ++e){
        var entity = entities[e];
        if(data != "") data += ", ";
        data += entity.id;
      }

      if(entities[0].json_class == "Manufactured::Ship")
        $('#player_ships').html(data);
      else if(entities[0].json_class == "Manufactured::Station")
        $('#player_stations').html(data);
    }
  }

  this.populate_fleets_container = function(fleets){
    if(fleets != null && isArray(fleets) && fleets.length > 0){
      var num_fleets = 0;
      var data  = "<span class='motel_entities_container_title'>Fleets:</span><ul>"
      for(var f=0;f<fleets.length;++f){
        var fleet = fleets[f];
        if(fleet.json_class == "Manufactured::Fleet"){
          num_fleets += 1;
          var fleet = fleets[f];
          data += "<li><span id='" + fleet.id + "' class='entity_title fleet_title' system_id='"+fleet.solar_system+"'>" + fleet.id + " (" + fleet.solar_system + ") </span></li>";
        }
      }
      data += "</ul>";
      if(num_fleets) $("#motel_fleets_container").html(data);
    }
  }

  this.populate_alliances_container = function(user){
    if(user != null && user.json_class == "Users::User"){
      var data  = "<span class='motel_entities_container_title'>Alliances:</span><ul>";
      for(var a in user.alliances){
        var alliance = user.alliances[a];
        client.user_alliances[alliance.id] = alliance;
        data += '<li><span id="' + alliance.id + '" class="entity_title alliance_title">' + alliance.id + '</span></li>';

        //for(var e in user.enemies_ids){
        //  var enemy = user.enemies[e];
        //  // TODO send request for enemy alliance info, store in client.enemy_alliances and client.enemy_users
        //}
      }

      data += "</ul>";
      $('#motel_alliances_container').html(data);
    }
  }

  this.populate_user_info = function(user){
    if(user != null && user.json_class == "Users::User"){
      $('#user_username').attr('value', user.id);
      $('#user_email').attr('value', user.email);
    }
  }

  this.create_account_confirmation = function(user){
    if(user!= null && user.json_class == "Users::User"){
      $('#motel_dialog').html("creating account, you should receive a confirmation email momentarily");
    }
  }

  this.create_session = function(session){
    if(session != null && session.json_class == "Users::Session"){
      client.current_user.create_session(session.id, session.user_id, client);
    }
  }

  /////////////////// registerable error handlers

  this.print_error_to_console = function(error, msg){
    console.log(error);
    console.log(msg);
  }

  this.show_error = function(error, msg){
    alert("error: " + msg);
  }

  /////////////////// registerable method handlers

  this.on_movement = function(params){
    client.add_location(params[0]);
  }

  this.on_message = function(params){
    $("#motel_chat_output textarea").append(params[0].nick + ": " + params[0].message + "\n");
  }

  this.on_attacked_event = function(params){
    if(params[0] == "attacked"){
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
