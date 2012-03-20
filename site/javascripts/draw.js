function CosmosUI(){
  this.canvas  = $('#motel_canvas');
  this.context = this.canvas[0].getContext('2d');
  this.width   = this.canvas.width();
  this.height  = this.canvas.height();

  this.adjusted_x  = function(x){
    return x + ui.width/2;
  }
  this.adjusted_y = function(y){
    return ui.height/2 - y;
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
        ui.context.moveTo(ui.adjusted_x(loco.x),     ui.adjusted_y(loco.y)    );
        ui.context.lineTo(ui.adjusted_x(endpoint.x), ui.adjusted_y(endpoint.y));
        ui.context.lineWidth = 2;
        ui.context.stroke();
      }
    }
  
    // draw circle representing system
    ui.context.beginPath();
    ui.context.fillStyle = "#FFFFFF";
    ui.context.arc(ui.adjusted_x(loco.x), ui.adjusted_y(loco.y), system.size, 0, Math.PI*2, true);
    ui.context.fill();
  
    // draw label
    ui.context.font = 'bold 16px sans-serif';
    ui.context.fillText(system.name, ui.adjusted_x(loco.x) - 25, ui.adjusted_y(loco.y) - 25);
  }

  this.draw_star = function(star){
    var loco = star.location;

    // draw circle representing star
    ui.context.beginPath();
    ui.context.fillStyle = "#" + star.color;
    ui.context.arc(ui.adjusted_x(loco.x), ui.adjusted_y(loco.y), star.size, 0, Math.PI*2, true);
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
      ui.context.lineTo(ui.adjusted_x(orbito[0]), ui.adjusted_y(orbito[1]));
    }
    ui.context.strokeStyle = "#AAAAAA";
    ui.context.stroke();
  
    // draw circle representing planet
    ui.context.beginPath();
    ui.context.fillStyle = "#" + planet.color;
    ui.context.arc(ui.adjusted_x(loco.x), ui.adjusted_y(loco.y), planet.size, 0, Math.PI*2, true);
    ui.context.fill();
  
    // draw moons
    for(var m=0; m<planet.moons.length; ++m){
      var moon = planet.moons[m];
      ui.context.beginPath();
      ui.context.fillStyle = "#808080";
      ui.context.arc(ui.adjusted_x(loco.x + moon.location.x),
                     ui.adjusted_y(loco.y + moon.location.y),
                     5, 0, Math.PI*2, true);
      ui.context.fill();
    }
  }

  this.draw_gate = function(gate){
    var loco = gate.location;

    // draw triangle representing gate
    var py = 12; // used to draw traingle for gate
    ui.context.fillStyle = "#00CC00";
    ui.context.beginPath();
    ui.context.moveTo(ui.adjusted_x(loco.x), ui.adjusted_y(loco.y) - py);
    ui.context.lineTo(ui.adjusted_x(loco.x) - gate.size/2, ui.adjusted_y(loco.y) + py);
    ui.context.lineTo(ui.adjusted_x(loco.x) + gate.size/2, ui.adjusted_y(loco.y) + py);
    ui.context.lineTo(ui.adjusted_x(loco.x), ui.adjusted_y(loco.y) - py);
    ui.context.fill();

    if(gate == controls.selected_gate){
      // draw circle around gate representing 'trigger area' or
      // area in which ships will be picked up for transport
      ui.context.strokeStyle = "#808080";
      ui.context.beginPath();
      ui.context.arc(ui.adjusted_x(loco.x), ui.adjusted_y(loco.y),
                     controls.gate_trigger_area, 0, Math.PI*2, false);
      ui.context.stroke();
    }
  
    // draw name of system gate is to
    ui.context.font = 'bold 16px sans-serif';
    var text_offset = gate.endpoint.length * 5;
    ui.context.fillText(gate.endpoint, ui.adjusted_x(loco.x) - text_offset,
                                       ui.adjusted_y(loco.y) + 30);
 }

  this.draw_station = function(station){
    // draw crosshairs representing statin
    ui.context.beginPath();
    ui.context.strokeStyle = "#0000CC";
    ui.context.moveTo(ui.adjusted_x(loco.x), ui.adjusted_y(loco.y) - station.size/2);
    ui.context.lineTo(ui.adjusted_x(loco.x), ui.adjusted_y(loco.y) + station.size/2);
    ui.context.moveTo(ui.adjusted_x(loco.x) - station.size/2, ui.adjusted_y(loco.y));
    ui.context.lineTo(ui.adjusted_x(loco.x) + station.size/2, ui.adjusted_y(loco.y));
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
    ui.context.moveTo(ui.adjusted_x(loco.x), ui.adjusted_y(loco.y) - ship.size/2);
    ui.context.lineTo(ui.adjusted_x(loco.x), ui.adjusted_y(loco.y) + ship.size/2);
    ui.context.moveTo(ui.adjusted_x(loco.x) - ship.size/2, ui.adjusted_y(loco.y));
    ui.context.lineTo(ui.adjusted_x(loco.x) + ship.size/2, ui.adjusted_y(loco.y));
    ui.context.lineWidth = 4;
    ui.context.stroke();
  
    // if ship is attacking another, draw line of attack
    if(ship.attacking){
      ui.context.beginPath();
      ui.context.strokeStyle = "#FF0000";
      ui.context.moveTo(ui.adjusted_x(loco.x), ui.adjusted_y(loco.y));
      ui.context.lineTo(ui.adjusted_x(ship.attacking.location.x),
                        ui.adjusted_y(ship.attacking.location.y));
      ui.context.lineWidth = 2;
      ui.context.stroke();
    }
  }

};
