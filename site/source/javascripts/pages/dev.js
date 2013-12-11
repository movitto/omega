/* Omega Dev Page JS
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/canvas"
//= require "ui/effects_player"
//= require "omega/gen"

Omega.Pages.Dev = function(){
  this.config  = Omega.Config;
  this.node    = new Omega.Node(this.config);
  this.canvas  = new Omega.UI.Canvas({page: this});
  this.effects_player = new Omega.UI.EffectsPlayer({page: this});
};

Omega.Pages.Dev.prototype = {
  wire_up : function(){
    this.canvas.wire_up();
    this.effects_player.wire_up();
  },

  custom_operations : function(){
    var station1 = new Omega.Station({id : 'st1', type : 'manufacturing',
      location : new Omega.Location({x: 1250, y: 1250, z: 300,
                                     orientation_x : 1,
                                     orientation_y : 0,
                                     orientation_z : 0})});
    var ship1 = new Omega.Ship({id : 'sh1', type : 'corvette',
      location : new Omega.Location({id : 'ship1',
                                     x:1250, y:-250, z :300,
                                     orientation_x : 1,
                                     orientation_y : 0,
                                     orientation_z : 0,
                                     movement_strategy : {json_class : 'Motel::MovementStrategies::Linear',
                                                          speed: 100, dx : 1, dy : 0, dz : 0}})});

    var ship2 = new Omega.Ship({id : 'sh2', type : 'mining',
      location : new Omega.Location({id : 'ship2',
                                     x:-1450, y:-1450, z :300,
                                     orientation_x : 0.82,
                                     orientation_y : -0.57,
                                     orientation_z : 0.04,
                                     movement_strategy : {json_class : 'Motel::MovementStrategies::Stopped' }})});

    //ship1.attacking = ship2;

    var star1 = new Omega.Star();
    var star2 = new Omega.Star();

    var orbit_nrml = {x : 0, y : 0, z : 1};
    //var orbit_nrml = {x : 0.68, y : -0.56, z : 0.45};

    var planet1 = new Omega.Planet({location :
      new Omega.Location({id : 'pl1', x:500, y:500, z:500,
        movement_strategy:
          Omega.Gen.elliptical_ms(orbit_nrml,
            {p: 3000, speed: 0.01, e : 0.7}) })});
      
    var gate1 = new Omega.JumpGate({location:
      new Omega.Location({x:-1000, y:50, z:500})});

    var ast1 = new Omega.Asteroid({location:
      new Omega.Location({x:-1500, y:-1500, z:200})});

    ship1.mining = ast1;

    var system1 = new Omega.SolarSystem({id : 'sys1', name : 'sys1',
        location : new Omega.Location({x: 500, y : 250, z: 500}),
        children : [star1, ast1, gate1, planet1, station1, ship1, ship2]});
    var system2 = new Omega.SolarSystem({id : 'sys2', name : 'sys2',
        location : new Omega.Location({x : -400, y : 250, z : -400}),
        children : [star2]});

    var galaxy = new Omega.Galaxy({children : [system1, system2]});

    this.effects_player.start();
    this.canvas.setup();
    this.canvas.set_scene_root(system1);
    //this.canvas.add(galaxy);

    //system1.add_interconn(system2);
    //this.canvas.reload(system1);

    this.canvas.add(this.canvas.skybox);
    this.canvas.skybox.set('galaxy2')

    this.canvas.animate();
  }
};

$(document).ready(function(){
  var dev = new Omega.Pages.Dev();
  dev.wire_up();
  dev.custom_operations();
});
