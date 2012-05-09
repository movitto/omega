function CosmosCamera(){
  this.position = [];
  this.angle    = [];
  this.sin_angle = [];
  this.cos_angle = [];
  this.focal_length = 1000;

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

    // XXX hack take care of planet orbit here
    if(loc.movement_strategy && loc.movement_strategy.orbit){
      for(orbiti in loc.movement_strategy.orbit){
        var orbito = loc.movement_strategy.orbit[orbiti];

        // XXX hack use update_location to update the orbit
        var oloc = new Location();
        oloc.x = orbito[0]; oloc.y = orbito[1]; oloc.z = orbito[2];
        this.update_location(oloc);
        loc.movement_strategy.orbit[orbiti][0] = oloc.cx;
        loc.movement_strategy.orbit[orbiti][1] = oloc.cy;
        loc.movement_strategy.orbit[orbiti][2] = oloc.cz;
      }
    }

    return loc;
  }

  this.update_locations = function(){
    for(loc in client.locations){
      var loco = client.locations[loc];
      client.locations[loc] = this.update_location(loco);
    }
  }

  this.set_position(0, 0, 1000);
  this.set_angle(0, 0, 0);
};

function CosmosUI(){
  this.canvas  = $('#motel_canvas');
  this.context = this.canvas[0].getContext('2d');
  this.width   = this.canvas.width();
  this.height  = this.canvas.height();
  this.camera  = new CosmosCamera();

  this.adjusted_x  = function(x, y, z){
    return (x * this.camera.focal_length / z) + ui.width / 2;
  }
  this.adjusted_y = function(x, y, z){
    return ui.height/2 - (y * this.camera.focal_length / z);
  }
  
  this.draw = function(){
    // clear drawing area
    ui.context.clearRect(0, 0, ui.width, ui.height);

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

    // TODO draw orbits first
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
        ui.context.beginPath();
        ui.context.strokeStyle = "#FFFFFF";
        ui.context.moveTo(ui.adjusted_x(loco.cx, loco.cy, loco.cz),
                          ui.adjusted_y(loco.cx, loco.cy, loco.cz));
        ui.context.lineTo(ui.adjusted_x(endpoint.cx, endpoint.cy, endpoint.cz),
                          ui.adjusted_y(endpoint.cx, endpoint.cy, endpoint.cz));
        ui.context.lineWidth = 2;
        ui.context.stroke();
      }
    }
  
    // draw circle representing system
    ui.context.beginPath();
    ui.context.fillStyle = "#FFFFFF";
    ui.context.arc(ui.adjusted_x(loco.cx, loco.cy, loco.cz),
                   ui.adjusted_y(loco.cx, loco.cy, loco.cz),
                   system.size, 0, Math.PI*2, true);
    ui.context.fill();
  
    // draw label
    ui.context.font = 'bold 16px sans-serif';
    ui.context.fillText(system.name,
                        ui.adjusted_x(loco.cx, loco.cy, loco.cz) - 25,
                        ui.adjusted_y(loco.cx, loco.cy, loco.cz) - 25);
  }

  this.draw_star = function(star){
    var loco = star.location;

    // draw circle representing star
    ui.context.beginPath();
    ui.context.fillStyle = "#" + star.color;
    ui.context.arc(ui.adjusted_x(loco.cx, loco.cy, loco.cz),
                   ui.adjusted_y(loco.cx, loco.cy, loco.cz),
                   star.size, 0, Math.PI*2, true);
    ui.context.fill();
  }

  this.draw_orbit = function(planet){
    var loco = planet.location;

    // draw orbit path
    var orbit = loco.movement_strategy.orbit;
    ui.context.beginPath();
    ui.context.lineWidth = 2;
    for(orbiti in orbit){
      var orbito = orbit[orbiti];
      ui.context.lineTo(ui.adjusted_x(orbito[0], orbito[1], orbito[2]),
                        ui.adjusted_y(orbito[0], orbito[1], orbito[2]));
    }
    ui.context.strokeStyle = "#AAAAAA";
    ui.context.stroke();
  }

  this.draw_planet = function(planet){
    var loco = planet.location;

    this.draw_orbit(planet);

    // draw circle representing planet
    ui.context.beginPath();
    ui.context.fillStyle = "#" + planet.color;
    ui.context.arc(ui.adjusted_x(loco.cx, loco.cy, loco.cz),
                   ui.adjusted_y(loco.cx, loco.cy, loco.cz),
                   planet.size, 0, Math.PI*2, true);
    ui.context.fill();
  
    // draw moons
    for(var m=0; m<planet.moons.length; ++m){
      var moon = planet.moons[m];
      ui.context.beginPath();
      ui.context.fillStyle = "#808080";
      ui.context.arc(ui.adjusted_x(loco.cx + moon.location.x, loco.cy + moon.location.y, loco.cz + moon.location.z),
                     ui.adjusted_y(loco.cx + moon.location.x, loco.cy + moon.location.y, loco.cz + moon.location.z),
                     5, 0, Math.PI*2, true);
      ui.context.fill();
    }
  }

  this.draw_asteroid = function(asteroid){
    var loco = asteroid.location;

    // draw asterisk representing the asteroid
    ui.context.fillStyle = "#FFFFFF";
    ui.context.font = 'bold 32px sans-serif';
    ui.context.fillText("*",
                        ui.adjusted_x(loco.cx, loco.cy, loco.cz),
                        ui.adjusted_y(loco.cx, loco.cy, loco.cz));
  }

  this.draw_gate = function(gate){
    var loco = gate.location;

    // draw triangle representing gate
    var py = 12; // used to draw traingle for gate
    ui.context.fillStyle = "#00CC00";
    ui.context.beginPath();
    ui.context.moveTo(ui.adjusted_x(loco.cx, loco.cy, loco.cz),
                      ui.adjusted_y(loco.cx, loco.cy, loco.cz) - py);
    ui.context.lineTo(ui.adjusted_x(loco.cx, loco.cy, loco.cz) - gate.size/2,
                      ui.adjusted_y(loco.cx, loco.cy, loco.cz) + py);
    ui.context.lineTo(ui.adjusted_x(loco.cx, loco.cy, loco.cz) + gate.size/2,
                      ui.adjusted_y(loco.cx, loco.cy, loco.cz) + py);
    ui.context.lineTo(ui.adjusted_x(loco.cx, loco.cy, loco.cz),
                      ui.adjusted_y(loco.cx, loco.cy, loco.cz) - py);
    ui.context.fill();

    if(gate == controls.selected_gate){
      // draw circle around gate representing 'trigger area' or
      // area in which ships will be picked up for transport
      ui.context.strokeStyle = "#808080";
      ui.context.beginPath();
      ui.context.arc(ui.adjusted_x(loco.cx, loco.cy, loco.cz),
                     ui.adjusted_y(loco.cx, loco.cy, loco.cz),
                     controls.gate_trigger_area, 0, Math.PI*2, false);
      ui.context.stroke();
    }
  
    // draw name of system gate is to
    ui.context.font = 'bold 16px sans-serif';
    var text_offset = gate.endpoint.length * 5;
    ui.context.fillText(gate.endpoint,
                        ui.adjusted_x(loco.cx, loco.cy, loco.cz) - text_offset,
                        ui.adjusted_y(loco.cx, loco.cy, loco.cz) + 30);
 }

  this.draw_station = function(station){
    var loco = station.location;

    // draw crosshairs representing statin
    ui.context.beginPath();
    ui.context.strokeStyle = "#0000CC";
    ui.context.moveTo(ui.adjusted_x(loco.cx, loco.cy, loco.cz),
                      ui.adjusted_y(loco.cx, loco.cy, loco.cz) - station.size/2);
    ui.context.lineTo(ui.adjusted_x(loco.cx, loco.cy, loco.cz),
                      ui.adjusted_y(loco.cx, loco.cy, loco.cz) + station.size/2);
    ui.context.moveTo(ui.adjusted_x(loco.cx, loco.cy, loco.cz) - station.size/2,
                      ui.adjusted_y(loco.cx, loco.cy, loco.cz));
    ui.context.lineTo(ui.adjusted_x(loco.cx, loco.cy, loco.cz) + station.size/2,
                      ui.adjusted_y(loco.cx, loco.cy, loco.cz));
    ui.context.lineWidth = 4;
    ui.context.stroke();
  }
  
  this.draw_ship = function(ship){
    var loco = ship.location;

    // draw crosshairs representing ship
    ui.context.beginPath();
    if(ship.selected)
      ui.context.strokeStyle = "#FFFF00";
    else if(ship.docked_at)
      ui.context.strokeStyle = "#99FFFF";
    else
      ui.context.strokeStyle = "#00CC00";
    ui.context.moveTo(ui.adjusted_x(loco.cx, loco.cy, loco.cz),
                      ui.adjusted_y(loco.cx, loco.cy, loco.cz) - ship.size/2);
    ui.context.lineTo(ui.adjusted_x(loco.cx, loco.cy, loco.cz),
                      ui.adjusted_y(loco.cx, loco.cy, loco.cz) + ship.size/2);
    ui.context.moveTo(ui.adjusted_x(loco.cx, loco.cy, loco.cz) - ship.size/2,
                      ui.adjusted_y(loco.cx, loco.cy, loco.cz));
    ui.context.lineTo(ui.adjusted_x(loco.cx, loco.cy, loco.cz) + ship.size/2,
                      ui.adjusted_y(loco.cx, loco.cy, loco.cz));
    ui.context.lineWidth = 4;
    ui.context.stroke();
  
    // if ship is attacking another, draw line of attack
    if(ship.attacking){
      ui.context.beginPath();
      ui.context.strokeStyle = "#FF0000";
      ui.context.moveTo(ui.adjusted_x(loco.cx, loco.cy, loco.cz),
                        ui.adjusted_y(loco.cx, loco.cy, loco.cz));
      ui.context.lineTo(ui.adjusted_x(ship.attacking.location.cx, ship.attacking.location.cy, ship.attacking.location.cz),
                        ui.adjusted_y(ship.attacking.location.cx, ship.attacking.location.cy, ship.attacking.location.cz));
      ui.context.lineWidth = 2;
      ui.context.stroke();
    }
  }

};
