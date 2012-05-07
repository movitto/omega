function CosmosCamera(){
  this.position = [];
  this.angle    = [];
  this.sin_angle = [];
  this.cos_angle = [];
  this.focal_length = 1000;

  this.set_position = function(x, y, z){
    this.position = [x, y, z];
  }

  this.set_angle = function(x, y, z){
    this.angle = [x, y, z];
    this.sin_angle = [Math.sin(x), Math.sin(y), Math.sin(z)];
    this.cos_angle = [Math.cos(x), Math.cos(y), Math.cos(z)];
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

  this.base_adjusted = function(x, y, z){
    // 3d to 2d perspective projection
    // http://en.wikipedia.org/wiki/3D_projection#Perspective_projection
    var cx = x - this.camera.position[0];
    var cy = y - this.camera.position[1];
    var cz = z - this.camera.position[2];
    var dx = this.camera.cos_angle[1] * (this.camera.sin_angle[2] * cy + this.camera.cos_angle[2] * cx) - 
             this.camera.sin_angle[1] * cz
    var dy = this.camera.sin_angle[0] * (this.camera.cos_angle[1] * cz + this.camera.sin_angle[1] * (this.camera.sin_angle[2] * cy + this.camera.cos_angle[2] * cx)) +
             this.camera.cos_angle[0] * (this.camera.cos_angle[2] * cy - this.camera.sin_angle[2] * cx)
    var dz = this.camera.cos_angle[0] * (this.camera.cos_angle[1] * cz + this.camera.sin_angle[1] * (this.camera.sin_angle[2] * cy + this.camera.cos_angle[2] * cx)) -
             this.camera.sin_angle[0] * (this.camera.cos_angle[2] * cy - this.camera.sin_angle[2] * cx);
    return [dx*(this.camera.focal_length/dz),
            dy*(this.camera.focal_length/dz)];
  }

  this.adjusted_x  = function(x, y, z){
    var ba = this.base_adjusted(x, y, z);
    return ba[0] + ui.width/2;
    //return x + ui.width/2;
  }
  this.adjusted_y = function(x, y, z){
    var ba = this.base_adjusted(x, y, z);
    return ui.height/2 - ba[1]
    //return ui.height/2 - y;
  }
  
  this.draw = function(){
    // clear drawing area
    ui.context.clearRect(0, 0, ui.width, ui.height);
  
    for(loc in client.locations){
      loco = client.locations[loc];
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
        ui.context.moveTo(ui.adjusted_x(loco.x, loco.y, loco.z),
                          ui.adjusted_y(loco.x, loco.y, loco.z));
        ui.context.lineTo(ui.adjusted_x(endpoint.x, endpoint.y, endpoint.z),
                          ui.adjusted_y(endpoint.x, endpoint.y, endpoint.z));
        ui.context.lineWidth = 2;
        ui.context.stroke();
      }
    }
  
    // draw circle representing system
    ui.context.beginPath();
    ui.context.fillStyle = "#FFFFFF";
    ui.context.arc(ui.adjusted_x(loco.x, loco.y, loco.z),
                   ui.adjusted_y(loco.x, loco.y, loco.z),
                   system.size, 0, Math.PI*2, true);
    ui.context.fill();
  
    // draw label
    ui.context.font = 'bold 16px sans-serif';
    ui.context.fillText(system.name,
                        ui.adjusted_x(loco.x, loco.y, loco.z) - 25,
                        ui.adjusted_y(loco.x, loco.y, loco.z) - 25);
  }

  this.draw_star = function(star){
    var loco = star.location;

    // draw circle representing star
    ui.context.beginPath();
    ui.context.fillStyle = "#" + star.color;
    ui.context.arc(ui.adjusted_x(loco.x, loco.y, loco.z),
                   ui.adjusted_y(loco.x, loco.y, loco.z),
                   star.size, 0, Math.PI*2, true);
    ui.context.fill();
  }

  this.draw_planet = function(planet){
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
  
    // draw circle representing planet
    ui.context.beginPath();
    ui.context.fillStyle = "#" + planet.color;
    ui.context.arc(ui.adjusted_x(loco.x, loco.y, loco.z),
                   ui.adjusted_y(loco.x, loco.y, loco.z),
                   planet.size, 0, Math.PI*2, true);
    ui.context.fill();
  
    // draw moons
    for(var m=0; m<planet.moons.length; ++m){
      var moon = planet.moons[m];
      ui.context.beginPath();
      ui.context.fillStyle = "#808080";
      ui.context.arc(ui.adjusted_x(loco.x + moon.location.x, loco.y + moon.location.y, loco.z + moon.location.z),
                     ui.adjusted_y(loco.x + moon.location.x, loco.y + moon.location.y, loco.z + moon.location.z),
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
                        ui.adjusted_x(loco.x, loco.y, loco.z),
                        ui.adjusted_y(loco.x, loco.y, loco.z));
  }

  this.draw_gate = function(gate){
    var loco = gate.location;

    // draw triangle representing gate
    var py = 12; // used to draw traingle for gate
    ui.context.fillStyle = "#00CC00";
    ui.context.beginPath();
    ui.context.moveTo(ui.adjusted_x(loco.x, loco.y, loco.z),
                      ui.adjusted_y(loco.x, loco.y, loco.z) - py);
    ui.context.lineTo(ui.adjusted_x(loco.x, loco.y, loco.z) - gate.size/2,
                      ui.adjusted_y(loco.x, loco.y, loco.z) + py);
    ui.context.lineTo(ui.adjusted_x(loco.x, loco.y, loco.z) + gate.size/2,
                      ui.adjusted_y(loco.x, loco.y, loco.z) + py);
    ui.context.lineTo(ui.adjusted_x(loco.x, loco.y, loco.z),
                      ui.adjusted_y(loco.x, loco.y, loco.z) - py);
    ui.context.fill();

    if(gate == controls.selected_gate){
      // draw circle around gate representing 'trigger area' or
      // area in which ships will be picked up for transport
      ui.context.strokeStyle = "#808080";
      ui.context.beginPath();
      ui.context.arc(ui.adjusted_x(loco.x, loco.y, loco.z),
                     ui.adjusted_y(loco.x, loco.y, loco.z),
                     controls.gate_trigger_area, 0, Math.PI*2, false);
      ui.context.stroke();
    }
  
    // draw name of system gate is to
    ui.context.font = 'bold 16px sans-serif';
    var text_offset = gate.endpoint.length * 5;
    ui.context.fillText(gate.endpoint,
                        ui.adjusted_x(loco.x, loco.y, loco.z) - text_offset,
                        ui.adjusted_y(loco.x, loco.y, loco.z) + 30);
 }

  this.draw_station = function(station){
    // draw crosshairs representing statin
    ui.context.beginPath();
    ui.context.strokeStyle = "#0000CC";
    ui.context.moveTo(ui.adjusted_x(loco.x, loco.y, loco.z),
                      ui.adjusted_y(loco.x, loco.y, loco.z) - station.size/2);
    ui.context.lineTo(ui.adjusted_x(loco.x, loco.y, loco.z),
                      ui.adjusted_y(loco.x, loco.y, loco.z) + station.size/2);
    ui.context.moveTo(ui.adjusted_x(loco.x, loco.y, loco.z) - station.size/2,
                      ui.adjusted_y(loco.x, loco.y, loco.z));
    ui.context.lineTo(ui.adjusted_x(loco.x, loco.y, loco.z) + station.size/2,
                      ui.adjusted_y(loco.x, loco.y, loco.z));
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
    ui.context.moveTo(ui.adjusted_x(loco.x, loco.y, loco.z),
                      ui.adjusted_y(loco.x, loco.y, loco.z) - ship.size/2);
    ui.context.lineTo(ui.adjusted_x(loco.x, loco.y, loco.z),
                      ui.adjusted_y(loco.x, loco.y, loco.z) + ship.size/2);
    ui.context.moveTo(ui.adjusted_x(loco.x, loco.y, loco.z) - ship.size/2,
                      ui.adjusted_y(loco.x, loco.y, loco.z));
    ui.context.lineTo(ui.adjusted_x(loco.x, loco.y, loco.z) + ship.size/2,
                      ui.adjusted_y(loco.x, loco.y, loco.z));
    ui.context.lineWidth = 4;
    ui.context.stroke();
  
    // if ship is attacking another, draw line of attack
    if(ship.attacking){
      ui.context.beginPath();
      ui.context.strokeStyle = "#FF0000";
      ui.context.moveTo(ui.adjusted_x(loco.x, loco.y, loco.z),
                        ui.adjusted_y(loco.x, loco.y, loco.z));
      ui.context.lineTo(ui.adjusted_x(ship.attacking.location.x, ship.attacking.location.y, ship.attacking.location.z),
                        ui.adjusted_y(ship.attacking.location.x, ship.attacking.location.y, ship.attacking.location.z));
      ui.context.lineWidth = 2;
      ui.context.stroke();
    }
  }

};
