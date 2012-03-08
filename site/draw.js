function CosmosUI(){
  this.canvas  = $('#motel_canvas');
  this.context = this.canvas[0].getContext('2d');
  this.width   = this.canvas.width();
  this.height  = this.canvas.height();
  
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
        ui.context.moveTo(loco.x     + ui.width/2, ui.height/2 - loco.y    );
        ui.context.lineTo(endpoint.x + ui.width/2, ui.height/2 - endpoint.y);
        ui.context.lineWidth = 2;
        ui.context.stroke();
      }
    }
  
    // draw circle representing system
    ui.context.beginPath();
    ui.context.fillStyle = "#FFFFFF";
    ui.context.arc(loco.x + ui.width/2, ui.height/2 - loco.y, 15, 0, Math.PI*2, true);
    ui.context.fill();
  
    // draw label
    ui.context.font = 'bold 16px sans-serif';
    ui.context.fillText(system.name, loco.x + ui.width/2 - 25, ui.height/2 - loco.y - 25);
  }

  this.draw_star = function(star){
    var loco = star.location;

    // draw circle representing star
    ui.context.beginPath();
    ui.context.fillStyle = "#FFFF00";
    ui.context.arc(loco.x + ui.width/2, ui.height/2 - loco.y, 15, 0, Math.PI*2, true);
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
      ui.context.lineTo(orbito[0] + ui.width/2, ui.height/2 - orbito[1]);
    }
    ui.context.strokeStyle = "#AAAAAA";
    ui.context.stroke();
  
    // draw circle representing planet
    ui.context.beginPath();
    ui.context.fillStyle = "#" + planet.color;
    ui.context.arc(loco.x + ui.width/2, ui.height/2 - loco.y, 15, 0, Math.PI*2, true);
    ui.context.fill();
  
    // draw moons
    for(var m=0; m<planet.moons.length; ++m){
      var moon = planet.moons[m];
      ui.context.beginPath();
      ui.context.fillStyle = "#808080";
      ui.context.arc(loco.x + moon.location.x + ui.width/2,
                  ui.height/2 - (loco.y + moon.location.y),
                  5, 0, Math.PI*2, true);
      ui.context.fill();
    }
  }

  this.draw_gate = function(gate){
    var loco = gate.location;

    // draw triangle representing gate
    ui.context.beginPath();
    ui.context.fillStyle = "#00CC00";
    ui.context.moveTo(loco.x + ui.width/2,      ui.height/2 - loco.y - 15);
    ui.context.lineTo(loco.x + ui.width/2 - 15, ui.height/2 - loco.y + 15);
    ui.context.lineTo(loco.x + ui.width/2 + 15, ui.height/2 - loco.y + 15);
    ui.context.lineTo(loco.x + ui.width/2,      ui.height/2 - loco.y - 15);
    ui.context.fill();
  
    // draw name of system gate is to
    ui.context.font = 'bold 16px sans-serif';
    ui.context.fillText(gate.endpoint, loco.x   + ui.width/2 - 25,
                                           ui.height/2 - loco.y  - 25);
  }

  this.draw_station = function(station){
    // draw crosshairs representing statin
    ui.context.beginPath();
    ui.context.strokeStyle = "#0000CC";
    ui.context.moveTo(loco.x + ui.width/2 + 15, ui.height/2 - loco.y);
    ui.context.lineTo(loco.x + ui.width/2 + 15, ui.height/2 - loco.y - 30);
    ui.context.moveTo(loco.x + ui.width/2,      ui.height/2 - loco.y - 15);
    ui.context.lineTo(loco.x + ui.width/2 + 30, ui.height/2 - loco.y - 15);
    ui.context.lineWidth = 4;
    ui.context.stroke();
  }
  
  this.draw_ship = function(ship){
    var loco = ship.location;

    // draw crosshairs representing ship
    ui.context.beginPath();
    if(ship.selected)
      ui.context.strokeStyle = "#FFFF00";
    else
      ui.context.strokeStyle = "#00CC00";
    ui.context.moveTo(loco.x + ui.width/2 + 15, ui.height/2 - loco.y);
    ui.context.lineTo(loco.x + ui.width/2 + 15, ui.height/2 - loco.y - 30);
    ui.context.moveTo(loco.x + ui.width/2,      ui.height/2 - loco.y - 15);
    ui.context.lineTo(loco.x + ui.width/2 + 30, ui.height/2 - loco.y - 15);
    ui.context.lineWidth = 4;
    ui.context.stroke();
  
    // if ship is attacking another, draw line of attack
    if(ship.attacking){
      ui.context.beginPath();
      ui.context.strokeStyle = "#FF0000";
      ui.context.moveTo(loco.x + ui.width/2 + 15, ui.height/2 - loco.y);
      ui.context.lineTo(ship.attacking.location.x + ui.width/2 + 30,
                     ui.height/2 - ship.attacking.location.y - 15);
      ui.context.lineWidth = 2;
      ui.context.stroke();
    }
  }

};
