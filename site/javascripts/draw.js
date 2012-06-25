function CosmosCamera(){
  this.original_position = [];
  this.position = [];
  this.angle    = [];
  this.sin_angle = [];
  this.cos_angle = [];
  this.focal_length = 1000;

  this.move = function(direction, distance){
    var new_pos = this.position;

    if(direction == 'x'){
      var inc_x = this.cos_angle[2] * distance;
      var inc_y = this.sin_angle[2] * distance;
      var inc_z = this.sin_angle[1] * distance;
      new_pos[0] += inc_x;
      new_pos[1] += inc_y;
      new_pos[2] -= inc_z;

    }else if(direction == 'y'){
      var inc_x = this.sin_angle[2] * distance;
      var inc_y = this.cos_angle[2] * distance;
      var inc_z = this.sin_angle[1] * distance;
      new_pos[0] -= inc_x;
      new_pos[1] += inc_y;
      new_pos[2] -= inc_z;

    }else if(direction == 'z'){
      new_pos[2] += distance;
    }

    this.set_position(new_pos[0], new_pos[1], new_pos[2]);
  }

  this.rotate = function(axis, distance){
    var new_angle = this.angle;
    var new_pos   = this.position;

    if(axis == 'x'){
      new_angle[0] += distance;
      new_pos[1] = this.original_position[1] * Math.cos(new_angle[0]) -
                   this.original_position[2] * Math.sin(new_angle[0]);
      new_pos[2] = this.original_position[1] * Math.sin(new_angle[0]) +
                   this.original_position[2] * Math.cos(new_angle[0]);

    }else if(axis == 'y'){
      new_angle[1] += distance;
      new_pos[2] = this.original_position[2] * Math.cos(new_angle[1]) -
                   this.original_position[0] * Math.sin(new_angle[1]);
      new_pos[0] = this.original_position[2] * Math.sin(new_angle[1]) +
                   this.original_position[0] * Math.cos(new_angle[1]);
    }else if(axis == 'z'){
      new_angle[2] += distance;
      new_pos[0] = this.original_position[0] * Math.cos(new_angle[2]) -
                   this.original_position[1] * Math.sin(new_angle[2]);
      new_pos[1] = this.original_position[0] * Math.sin(new_angle[2]) +
                   this.original_position[1] * Math.cos(new_angle[2]);
    }

    for(var i = 0; i < 3; ++i){
      if(new_angle[i] > 6.28)
        new_angle[i] -= 6.28;
      else if(new_angle[i] < 0)
        new_angle[i] += 6.28;
    }

    this.set_position(new_pos[0], new_pos[1], new_pos[2]);
    this.set_angle(new_angle[0], new_angle[1], new_angle[2]);
  }

  this.set_original_position = function(x, y, z){
    this.original_position = [x, y, z];
    this.set_position(x, y, z);
  }

  this.set_position = function(x, y, z){
    this.position = [x, y, z];
    this.update_locations();
  }

  this.set_angle = function(x, y, z){
    this.angle = [x, y, z];
    this.sin_angle = [Math.sin(x), Math.sin(y), Math.sin(z)];
    this.cos_angle = [Math.cos(x), Math.cos(y), Math.cos(z)];
    this.update_locations();
  }

  this.update_location = function(loc){
    // 3d to 2d perspective projection
    // http://en.wikipedia.org/wiki/3D_projection#Perspective_projection
    var cx = loc.x - this.position[0];
    var cy = loc.y - this.position[1];
    var cz = loc.z - this.position[2];
    loc.cx = this.cos_angle[1] * (this.sin_angle[2] * cy + this.cos_angle[2] * cx) -
             this.sin_angle[1] * cz
    loc.cy = this.sin_angle[0] * (this.cos_angle[1] * cz + this.sin_angle[1] * (this.sin_angle[2] * cy + this.cos_angle[2] * cx)) +
             this.cos_angle[0] * (this.cos_angle[2] * cy - this.sin_angle[2] * cx)
    loc.cz = this.cos_angle[0] * (this.cos_angle[1] * cz + this.sin_angle[1] * (this.sin_angle[2] * cy + this.cos_angle[2] * cx)) -
             this.sin_angle[0] * (this.cos_angle[2] * cy - this.sin_angle[2] * cx);

    return loc;
  }

  this.update_locations = function(){
    for(loc in client.locations){
      var loco = client.locations[loc];
      client.locations[loc] = this.update_location(loco);
    }
  }

  this.set_original_position(0, 0, 1000);
  this.set_angle(0, 0, 0);
};

function CosmosUI(){
  this.canvas  = $('#motel_canvas');
  this.context = this.canvas[0].getContext('2d');
  this.width   = this.canvas.width();
  this.height  = this.canvas.height();
  this.camera  = new CosmosCamera();

  this.adjusted_x  = function(x, y, z){
    return (x * this.camera.focal_length / z) + canvas_ui.width / 2;
  }
  this.adjusted_y = function(x, y, z){
    return canvas_ui.height/2 - (y * this.camera.focal_length / z);
  }
  
  this.draw = function(){
    // clear drawing area
    canvas_ui.context.clearRect(0, 0, canvas_ui.width, canvas_ui.height);

    // sort locations based on z axis position
    var sorted_locations = [];
    for(loc in client.locations){
      var i = 0;
      for(; i < sorted_locations.length; ++i){
        if(sorted_locations[i].cz > client.locations[loc].cz)
          break;
      }
      sorted_locations.splice(i, 0, client.locations[loc]);
    }

    for(loc in sorted_locations){
      var loco = sorted_locations[loc];
      loco.draw(loco.entity);
    }

    // draw the controls
    controls.draw();
  }

  this.draw_nothing = function(entity){}

  this.draw_system = function(system){
    var loco = system.location;

    // draw jumpgates
    for(var j=0; j<system.jump_gates.length;++j){
      var jg = system.jump_gates[j];
      if(jg.endpoint_system != null){
        var endpoint = jg.endpoint_system.location;
        canvas_ui.context.beginPath();
        canvas_ui.context.strokeStyle = "#FFFFFF";
        canvas_ui.context.moveTo(canvas_ui.adjusted_x(loco.cx, loco.cy, loco.cz),
                                 canvas_ui.adjusted_y(loco.cx, loco.cy, loco.cz));
        canvas_ui.context.lineTo(canvas_ui.adjusted_x(endpoint.cx, endpoint.cy, endpoint.cz),
                                 canvas_ui.adjusted_y(endpoint.cx, endpoint.cy, endpoint.cz));
        canvas_ui.context.lineWidth = 2;
        canvas_ui.context.stroke();
      }
    }
  
    // draw circle representing system
    canvas_ui.context.beginPath();
    canvas_ui.context.fillStyle = "#FFFFFF";
    canvas_ui.context.arc(canvas_ui.adjusted_x(loco.cx, loco.cy, loco.cz),
                          canvas_ui.adjusted_y(loco.cx, loco.cy, loco.cz),
                   system.size, 0, Math.PI*2, true);
    canvas_ui.context.fill();
  
    // draw label
    canvas_ui.context.font = 'bold 16px sans-serif';
    canvas_ui.context.fillText(system.name,
                               canvas_ui.adjusted_x(loco.cx, loco.cy, loco.cz) - 25,
                               canvas_ui.adjusted_y(loco.cx, loco.cy, loco.cz) - 25);
  }

  this.draw_star = function(star){
    var loco = star.location;

    // draw circle representing star
    canvas_ui.context.beginPath();
    canvas_ui.context.fillStyle = "#" + star.color;
    canvas_ui.context.arc(canvas_ui.adjusted_x(loco.cx, loco.cy, loco.cz),
                          canvas_ui.adjusted_y(loco.cx, loco.cy, loco.cz),
                          star.size, 0, Math.PI*2, true);
    canvas_ui.context.fill();
  }

  this.draw_orbit = function(orbit){
    if(orbit.previous){
      var loco  = orbit.location;
      var ploco = orbit.previous.location;

      var aox = canvas_ui.adjusted_x(loco.cx,  loco.cy,  loco.cz);
      var aoy = canvas_ui.adjusted_y(loco.cx,  loco.cy,  loco.cz);
      var apx = canvas_ui.adjusted_x(ploco.cx, ploco.cy, ploco.cz);
      var apy = canvas_ui.adjusted_y(ploco.cx, ploco.cy, ploco.cz);

      canvas_ui.context.beginPath();
      canvas_ui.context.lineWidth = 2;
      canvas_ui.context.strokeStyle = "#AAAAAA";
      canvas_ui.context.moveTo(apx, apy);
      canvas_ui.context.lineTo(aox, aoy);
      canvas_ui.context.stroke();
    }
  }

  this.draw_planet = function(planet){
    var loco = planet.location;

    // draw circle representing planet
    canvas_ui.context.beginPath();
    canvas_ui.context.fillStyle = "#" + planet.color;
    canvas_ui.context.arc(canvas_ui.adjusted_x(loco.cx, loco.cy, loco.cz),
                          canvas_ui.adjusted_y(loco.cx, loco.cy, loco.cz),
                          planet.size, 0, Math.PI*2, true);
    canvas_ui.context.fill();
  
    // draw moons
    for(var m=0; m<planet.moons.length; ++m){
      var moon = planet.moons[m];
      canvas_ui.context.beginPath();
      canvas_ui.context.fillStyle = "#808080";
      canvas_ui.context.arc(canvas_ui.adjusted_x(loco.cx + moon.location.x, loco.cy + moon.location.y, loco.cz + moon.location.z),
                            canvas_ui.adjusted_y(loco.cx + moon.location.x, loco.cy + moon.location.y, loco.cz + moon.location.z),
                            5, 0, Math.PI*2, true);
      canvas_ui.context.fill();
    }
  }

  this.draw_asteroid = function(asteroid){
    var loco = asteroid.location;

    // draw asterisk representing the asteroid
    canvas_ui.context.fillStyle = "#FFFFFF";
    canvas_ui.context.font = 'bold 32px sans-serif';
    canvas_ui.context.textAlign = 'center';
    canvas_ui.context.textBaseline = 'middle';
    canvas_ui.context.fillText("*",
                               canvas_ui.adjusted_x(loco.cx, loco.cy, loco.cz),
                               canvas_ui.adjusted_y(loco.cx, loco.cy, loco.cz));
  }

  this.draw_gate = function(gate){
    var loco = gate.location;

    // draw triangle representing gate
    var py = 12; // used to draw traingle for gate
    canvas_ui.context.fillStyle = "#00CC00";
    canvas_ui.context.beginPath();
    canvas_ui.context.moveTo(canvas_ui.adjusted_x(loco.cx, loco.cy, loco.cz),
                             canvas_ui.adjusted_y(loco.cx, loco.cy, loco.cz) - py);
    canvas_ui.context.lineTo(canvas_ui.adjusted_x(loco.cx, loco.cy, loco.cz) - gate.size/2,
                             canvas_ui.adjusted_y(loco.cx, loco.cy, loco.cz) + py);
    canvas_ui.context.lineTo(canvas_ui.adjusted_x(loco.cx, loco.cy, loco.cz) + gate.size/2,
                             canvas_ui.adjusted_y(loco.cx, loco.cy, loco.cz) + py);
    canvas_ui.context.lineTo(canvas_ui.adjusted_x(loco.cx, loco.cy, loco.cz),
                             canvas_ui.adjusted_y(loco.cx, loco.cy, loco.cz) - py);
    canvas_ui.context.fill();

    if(gate == controls.selected_gate){
      // draw circle around gate representing 'trigger area' or
      // area in which ships will be picked up for transport
      canvas_ui.context.strokeStyle = "#808080";
      canvas_ui.context.beginPath();
      canvas_ui.context.arc(canvas_ui.adjusted_x(loco.cx, loco.cy, loco.cz),
                            canvas_ui.adjusted_y(loco.cx, loco.cy, loco.cz),
                            controls.gate_trigger_area, 0, Math.PI*2, false);
      canvas_ui.context.stroke();
    }
  
    // draw name of system gate is to
    canvas_ui.context.font = 'bold 16px sans-serif';
    canvas_ui.context.fillText(gate.endpoint,
                               canvas_ui.adjusted_x(loco.cx, loco.cy, loco.cz),
                               canvas_ui.adjusted_y(loco.cx, loco.cy, loco.cz) + 30);
 }

  this.draw_station = function(station){
    var loco = station.location;

    // draw crosshairs representing statin
    canvas_ui.context.beginPath();
    canvas_ui.context.strokeStyle = "#0000CC";
    canvas_ui.context.moveTo(canvas_ui.adjusted_x(loco.cx, loco.cy, loco.cz),
                             canvas_ui.adjusted_y(loco.cx, loco.cy, loco.cz) - station.size/2);
    canvas_ui.context.lineTo(canvas_ui.adjusted_x(loco.cx, loco.cy, loco.cz),
                             canvas_ui.adjusted_y(loco.cx, loco.cy, loco.cz) + station.size/2);
    canvas_ui.context.moveTo(canvas_ui.adjusted_x(loco.cx, loco.cy, loco.cz) - station.size/2,
                             canvas_ui.adjusted_y(loco.cx, loco.cy, loco.cz));
    canvas_ui.context.lineTo(canvas_ui.adjusted_x(loco.cx, loco.cy, loco.cz) + station.size/2,
                             canvas_ui.adjusted_y(loco.cx, loco.cy, loco.cz));
    canvas_ui.context.lineWidth = 4;
    canvas_ui.context.stroke();
  }
  
  this.draw_ship = function(ship){
    var loco = ship.location;

    // draw crosshairs representing ship
    canvas_ui.context.beginPath();
    if(ship.selected)
      canvas_ui.context.strokeStyle = "#FFFF00";
    else if(ship.docked_at)
      canvas_ui.context.strokeStyle = "#99FFFF";
    else
      canvas_ui.context.strokeStyle = "#00CC00";
    canvas_ui.context.moveTo(canvas_ui.adjusted_x(loco.cx, loco.cy, loco.cz),
                             canvas_ui.adjusted_y(loco.cx, loco.cy, loco.cz) - ship.size/2);
    canvas_ui.context.lineTo(canvas_ui.adjusted_x(loco.cx, loco.cy, loco.cz),
                             canvas_ui.adjusted_y(loco.cx, loco.cy, loco.cz) + ship.size/2);
    canvas_ui.context.moveTo(canvas_ui.adjusted_x(loco.cx, loco.cy, loco.cz) - ship.size/2,
                             canvas_ui.adjusted_y(loco.cx, loco.cy, loco.cz));
    canvas_ui.context.lineTo(canvas_ui.adjusted_x(loco.cx, loco.cy, loco.cz) + ship.size/2,
                             canvas_ui.adjusted_y(loco.cx, loco.cy, loco.cz));
    canvas_ui.context.lineWidth = 4;
    canvas_ui.context.stroke();
  
    // if ship is attacking another, draw line of attack
    if(ship.attacking){
      canvas_ui.context.beginPath();
      canvas_ui.context.strokeStyle = "#FF0000";
      canvas_ui.context.moveTo(canvas_ui.adjusted_x(loco.cx, loco.cy, loco.cz),
                               canvas_ui.adjusted_y(loco.cx, loco.cy, loco.cz));
      canvas_ui.context.lineTo(canvas_ui.adjusted_x(ship.attacking.location.cx, ship.attacking.location.cy, ship.attacking.location.cz),
                               canvas_ui.adjusted_y(ship.attacking.location.cx, ship.attacking.location.cy, ship.attacking.location.cz));
      canvas_ui.context.lineWidth = 2;
      canvas_ui.context.stroke();
    }

    // if ship is mining, draw line to mining target
    if(ship.mining){
      canvas_ui.context.beginPath();
      canvas_ui.context.strokeStyle = "#0000FF";
      canvas_ui.context.moveTo(canvas_ui.adjusted_x(loco.cx, loco.cy, loco.cz),
                               canvas_ui.adjusted_y(loco.cx, loco.cy, loco.cz));
      canvas_ui.context.lineTo(canvas_ui.adjusted_x(ship.mining.location.cx, ship.mining.location.cy, ship.mining.location.cz),
                               canvas_ui.adjusted_y(ship.mining.location.cx, ship.mining.location.cy, ship.mining.location.cz));
      canvas_ui.context.lineWidth = 2;
      canvas_ui.context.stroke();
    }
  }

};

function CosmosStatsUI(){
  this.cosmos_stats  = $('#omega_cosmos_stats');
  this.users_stats   = $('#omega_users_stats');
  this.actions_stats = $('#omega_actions_stats');
  this.draw = function(){
    var cs = '';
    var as = '<ul>';
    for(var l in client.locations){
      if(client.locations[l].entity.json_class == "Cosmos::Galaxy"){
        var gal = client.locations[l].entity;
        cs += '<ul><li>Galaxy: ' + gal.name + '<ul>';
        for(var s = 0; s < gal.solar_systems.length; ++s){
          var sys = gal.solar_systems[s];
          cs += "<li><span id='"+sys.name+"' class='entity_title solar_system_title'>System: " + sys.name + "</span><ul>";
          if(sys.star){
            cs += "<li>Star: " + sys.star.name + "</li>";
          }
          for(var p = 0; p < sys.planets.length; ++p){
            var planet = sys.planets[p];
            cs += "<li>Planet: " + planet.name + " (@ " + planet.location.to_s() + ") <ul>";
            for(var m = 0; m < planet.moons.length; ++m){
              var moon = planet.moons[m];
              cs += "<li>Moon: " + moon.name + "</li>";
            }
            cs += "</ul></li>";
          }
          for(var a = 0; a < sys.asteroids.length; ++a){
            var asteroid = sys.asteroids[a];
            cs += "<li>Asteroid: " + asteroid.name + "<ul>";
            if(asteroid.resources){
              for(var r in asteroid.resources){
                var res = asteroid.resources[r];
                cs += "<li>" + res.resource.id + " (" + res.quantity + ")</li>";
              }
            }
            cs += "</ul></li>";
          }
          cs += "</ul></li>";
        }
        cs += '</ul></li></ul>';

      }else if(client.locations[l].entity.json_class == "Manufactured::Ship"){
        var ship = client.locations[l].entity;
        if(ship.attacking){
          as += "<li>" + ship.id + " attacking " + ship.attacking.id + "</li>";
        }

        if(ship.mining){
          as += "<li>" + ship.id + " mining " + ship.mining.name + "</li>";
        }
      }
    }

    as += "</ul>";

    var us = '<ul>';
    for(var u in client.users){
      var user = client.users[u];
      us += "<li>" + user.id + "<ul>";
      for(var s in user.ships){
        us += "<li>" + user.ships[s].id + " (@" + user.ships[s].location.to_s() + ")<ul>";
        us += "</ul></li>";
      }
      us += "</ul></li>";
    }
    us += "</ul>"

    stats_ui.cosmos_stats.html(cs);
    stats_ui.users_stats.html(us);
    stats_ui.actions_stats.html(as);
  };
};
