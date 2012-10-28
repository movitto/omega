function roundTo(number, places){
  return Math.round(number * Math.pow(10,places)) / Math.pow(10,places);
}

function OmegaLocation(entity){
  // initialize location
  var loc = {};
  if(entity != null){
    if(entity.location != null){
      loc.id = entity.location.id;
      loc.x = entity.location.x;
      loc.y = entity.location.y;
      loc.z = entity.location.z
    }
    loc.entity = entity;
    entity.scene_location = loc;
  }

  loc.scene_object = null; // used to detect clicks
  loc.scene_entities = []; // should be removed from scene upon clearing
  loc.dirty = true;        // bool indicating if loc was updated / should be redrawn
  loc.draw  = null;        // draw method
  loc.click  = null;       // clicked handler

  // should be used to update coordinates so as to set dirty bit
  loc.update = function(x,y,z){
    if(x != null){
      this.x = x;
      this.dirty = true;
    }
    if(y != null){
      this.y = y;
      this.dirty = true;
    }
    if(z != null){
      this.z = z;
      this.dirty = true;
    }
    if(this.entity != null){
      this.entity.location.x = this.x;
      this.entity.location.y = this.y;
      this.entity.location.z = this.z;
    }
    return this;
  }

  loc.render = function(scene){
    if(this.dirty){
      for(var scene_entity in this.scene_entities){
        scene._scene.remove(this.scene_entities[scene_entity]);
        delete this.scene_entities[scene_entity];
      }
      this.scene_entities = [];
      if(this.draw != null) this.draw(scene._scene);
      scene.animate();
    }
    this.dirty = false;
  }

  loc.to_s = function(){ return roundTo(this.x, 2) + "/" + roundTo(this.y, 2) + "/" + roundTo(this.z, 2); }

  loc.toJSON = function(){ return new JRObject("Motel::Location", this, 
      ["toJSON", "json_class", "entity", "movement_strategy", "notifications",
       "movement_callbacks", "proximity_callbacks"]).toJSON(); };
  if(entity != null && entity.location != null)
    entity.location.toJSON = loc.toJSON;

  return loc;
}

$camera = {
  _camera : new THREE.PerspectiveCamera(75, 900 / 400, 1, 1000 ),
  //camera = new THREE.OrthographicCamera(-500, 500, 500, -500, -1000, 1000);

  zoom : function(distance){
    var x = this._camera.position.x,
        y = this._camera.position.y,
        z = this._camera.position.z;
    var dist  = Math.sqrt(Math.pow(x, 2) + Math.pow(y, 2) + Math.pow(z, 2));
    var phi = Math.atan2(x,z);
    var theta   = Math.acos(y/dist);

    dist += distance;

    z = dist * Math.sin(theta) * Math.cos(phi);
    x = dist * Math.sin(theta) * Math.sin(phi);
    y = dist * Math.cos(theta);

    this._camera.position.x = x;
    this._camera.position.y = y;
    this._camera.position.z = z;

    this._camera.lookAt($scene._scene.position);
    $scene.setup();
  },

  rotate : function(theta_distance, phi_distance){
    var x = this._camera.position.x,
        y = this._camera.position.y,
        z = this._camera.position.z;
    var dist  = Math.sqrt(Math.pow(x, 2) + Math.pow(y, 2) + Math.pow(z, 2));
    var phi = Math.atan2(x,z);
    var theta   = Math.acos(y/dist);
    if(z < 0) theta = 2 * Math.PI - theta; // adjust for acos loss

    theta += theta_distance;
    phi   += phi_distance;

    if(z < 0) theta = 2 * Math.PI - theta; // readjust for acos loss

    // prevent camera from going too far up / down
    if(theta < 0.5)
      theta = 0.5;
    else if(theta > (Math.PI - 0.5))
      theta = Math.PI - 0.5;

    z = dist * Math.sin(theta) * Math.cos(phi);
    x = dist * Math.sin(theta) * Math.sin(phi);
    y = dist * Math.cos(theta);

    this._camera.position.x = x;
    this._camera.position.y = y;
    this._camera.position.z = z;

    this._camera.lookAt($scene._scene.position);
    this._camera.updateMatrix();
    $scene.setup(); // would rather just 'animate' but components in scene may depend on camera orientation
  }
}

$grid = {
  size : 250,
  step : 100,
  geometry : new THREE.Geometry(),
  material : new THREE.LineBasicMaterial( { color: 0xcccccc, opacity: 0.4 } ),

  init : function(){
    for ( var i = - this.size; i <= this.size; i += this.step ) {
      for ( var j = - this.size; j <= this.size; j += this.step ) {
        this.geometry.vertices.push( new THREE.Vector3( - this.size, j, i ) );
        this.geometry.vertices.push( new THREE.Vector3(   this.size, j, i ) );

        this.geometry.vertices.push( new THREE.Vector3( i, j, - this.size ) );
        this.geometry.vertices.push( new THREE.Vector3( i, j,   this.size ) );

        this.geometry.vertices.push( new THREE.Vector3( i, -this.size, j ) );
        this.geometry.vertices.push( new THREE.Vector3( i, this.size,  j ) );
      }
    }

    this.grid_line = new THREE.Line( this.geometry, this.material, THREE.LinePieces );
    this.showing_grid = false;
  },

  show : function(){
    $scene._scene.add( this.grid_line );
    this.showing_grid = true;
  },

  hide : function(){
    $scene._scene.remove(this.grid_line);
    this.showing_grid = false;
  },

  toggle : function(){
    var toggle_grid = $('#toggle_grid_canvas');
    if(toggle_grid){
      if(toggle_grid.is(':checked'))
        this.show();
      else
        this.hide();
    }
    $scene.setup();
  }
};

$scene = {
  init : function(){
    this._canvas   = $('#omega_canvas').get()[0];
    this._scene    = new THREE.Scene();
    this._renderer = new THREE.CanvasRenderer({canvas: this._canvas});
    this._renderer.setSize( 900, 400 );
    $camera._camera.position.z = 500;

    this.target = null;
    this.locations = [];

    // preload textures & other resources
    this.textures  = {jump_gate : THREE.ImageUtils.loadTexture("/womega/images/jump_gate.png")};
    this.materials = {line      : new THREE.LineBasicMaterial({color: 0xFFFFFF}),
                      system    : new THREE.MeshLambertMaterial({color: 0x996600, blending: THREE.AdditiveBlending}),
                      system_label : new THREE.MeshBasicMaterial( { color: 0x3366FF, overdraw: true } ),
                      orbit : new THREE.LineBasicMaterial({color: 0xAAAAAA}),
                      moon : new THREE.MeshLambertMaterial({color: 0x808080, blending: THREE.AdditiveBlending}),
                      asteroid : new THREE.MeshBasicMaterial( { color: 0xffffff, overdraw: true }),
                      jump_gate : new THREE.MeshBasicMaterial( { map: $scene.textures['jump_gate'] } ),
                      jump_gate_selected : new THREE.MeshLambertMaterial({color: 0xffffff, transparent: true, opacity: 0.4}),
                      ship_surface : new THREE.LineBasicMaterial( { } ), // new THREE.MeshFaceMaterial({ });
                      ship_attacking : new THREE.LineBasicMaterial({color: 0xFF0000}),
                      ship_mining : new THREE.LineBasicMaterial({color: 0x0000FF}),
                      station_surface : new THREE.LineBasicMaterial( { } )
                      };
    // relatively new for three.js (mesh.doubleSided = true is old way):
    this.materials['jump_gate'].side = THREE.DoubleSide;
    this.materials['ship_surface'].side = THREE.DoubleSide;
    this.materials['station_surface'].side = THREE.DoubleSide;

    var mnradius = 5, mnsegments = 32, mnrings = 32;
    this.geometries = {asteroid : new THREE.TextGeometry( "*", {height: 20, curveSegments: 2, font: 'helvetiker', size: 32}),
                       moon     : new THREE.SphereGeometry(mnradius, mnsegments, mnrings),};

    return this;
  },

  set_target : function(new_target){
    this.clear();
    this.target = new_target;
  },

  add_entity : function(entity){
    var oloc = new OmegaLocation(entity);
    set_callback_methods(oloc);
    this.locations.push(oloc);
    return oloc;
  },

  update_location : function(loc){
    for(var lloc in this.locations){
      if(this.locations[lloc].id == loc.id){
        return this.locations[lloc].update(loc.x, loc.y, loc.z);
      }
    }
  },

  remove_location : function(loc){
    this.locations.splice(this.locations.indexOf(loc), 1);
  },

  clear : function(){
    for(var loc in this.locations){
      for(var scene_entity in this.locations[loc].scene_entities){
        this._scene.remove(this.locations[loc].scene_entities[scene_entity]);
      }
      delete this.locations[loc];
    }
    this.locations = [];
  },

  setup : function(){
    for(var loc in this.locations){
      this.locations[loc].render(this);
    }
  },

  animate : function(){
    requestAnimationFrame(this.render);
  },

  render : function(){
    $scene._renderer.render($scene._scene, $camera._camera);
  }

}

//////////////////////// draw methods, use three.js to draw entities

function draw_cosmos_system(scene){
  var loc = this;
  var system = loc.entity;

  for(var j=0; j<system.jump_gates.length;++j){
    var jg = system.jump_gates[j];
    var endpoint = $entity_tracker[jg.endpoint].location;
    var geometry = new THREE.Geometry();
    geometry.vertices.push(new THREE.Vector3(loc.x, loc.y, loc.z));
    geometry.vertices.push(new THREE.Vector3(endpoint.x, endpoint.y, endpoint.z));
    var line = new THREE.Line(geometry, $scene.materials['line']);
    loc.scene_entities.push(line);
    scene.add(line);
  }
  
  // draw sphere representing system
  var radius = system.size, segments = 32, rings = 32;
  var sphere = new THREE.Mesh(new THREE.SphereGeometry(radius, segments, rings), $scene.materials['system']);
  sphere.position.x = loc.x ; sphere.position.y = loc.y ; sphere.position.z = loc.z ;
  loc.scene_object = sphere;
  loc.scene_entities.push(sphere);
  scene.add(sphere);

  // draw label
  var text3d = new THREE.TextGeometry( system.name, {height: 10, width: 3, curveSegments: 2, font: 'helvetiker', size: 16});
  var text = new THREE.Mesh( text3d, $scene.materials['system_label'] );
  text.position.x = loc.x - 50 ; text.position.y = loc.y - 50 ; text.position.z = loc.z - 50;
  text.lookAt($camera._camera.position);
  loc.scene_entities.push(text);
  scene.add(text);
}

function clicked_cosmos_system(system){
  // XXX really ugly depends on bot.js
  set_root_entity(system.name);
}

function draw_cosmos_star(scene){
  var loc = this;
  var star = loc.entity;

  var radius = star.size, segments = 32, rings = 32;

  if($scene.materials['star' + star.color] == null)
    $scene.materials['star' + star.color] = new THREE.MeshLambertMaterial({color: parseInt('0x' + star.color), blending: THREE.AdditiveBlending })
  var sphere = new THREE.Mesh(new THREE.SphereGeometry(radius, segments, rings), $scene.materials['star' + star.color]);
  sphere.position.x = loc.x ; sphere.position.y = loc.y ; sphere.position.z = loc.z ;
  loc.scene_object = sphere;
  loc.scene_entities.push(sphere);
  scene.add(sphere);
}

function clicked_cosmos_star(star){
}

function draw_cosmos_planet(scene){
  var loc = this;
  var planet = loc.entity;

  // draw sphere representing planet
  var radius = planet.size, segments = 32, rings = 32;
  if($scene.geometries['planet' + radius] == null)
    $scene.geometries['planet' + radius] = new THREE.SphereGeometry(radius, segments, rings);
  if($scene.materials['planet' + planet.color] == null)
    $scene.materials['planet' + planet.color] = new THREE.MeshLambertMaterial({color: parseInt('0x' + planet.color), blending: THREE.AdditiveBlending});
  var sphere = new THREE.Mesh($scene.geometries['planet' + radius],
                              $scene.materials['planet' + planet.color]);
  sphere.position.x = loc.x ; sphere.position.y = loc.y ; sphere.position.z = loc.z ;
  loc.scene_object = sphere;
  loc.scene_entities.push(sphere);
  scene.add(sphere);

  // draw orbit
  var geometry = new THREE.Geometry();
  for(var o in planet.orbit){
    if(o != 0 & (o % 20 == 0)){
      var orbit  = planet.orbit[o];
      var porbit = planet.orbit[o-1];
      geometry.vertices.push(new THREE.Vector3(orbit[0],  orbit[1],  orbit[2]));
      geometry.vertices.push(new THREE.Vector3(porbit[0], porbit[1], porbit[2]));
    }
  }
  var line = new THREE.Line(geometry, $scene.materials['orbit']);
  loc.scene_entities.push(line);
  loc.scene_entities.push(geometry);
  //scene.add(line);
  
  // draw moons
  for(var m=0; m<planet.moons.length; ++m){
    var moon = planet.moons[m];
    var sphere = new THREE.Mesh($scene.geometries['moon'], $scene.materials['moon']);
    sphere.position.x = loc.x + moon.location.x ; sphere.position.y = loc.y + moon.location.y; sphere.position.z = loc.z + moon.location.z;
    loc.scene_entities.push(sphere);
    scene.add(sphere);
  }
}

function clicked_cosmos_planet(planet){
}

function draw_cosmos_asteroid(scene){
  var loc = this;
  var asteroid = loc.entity;

  var text = new THREE.Mesh( $scene.geometries['asteroid'], $scene.materials['asteroid'] );
  text.position.x = loc.x ; text.position.y = loc.y ; text.position.z = loc.z;
  loc.scene_object = text;
  loc.scene_entities.push(text);
  scene.add(text);
}

function clicked_cosmos_asteroid(asteroid){
  var details = ['Asteroid: ' + asteroid.name + "<br/>",
                 '@ ' + asteroid.scene_location.to_s() + '<br/>',
                 'Resources: <br/>'];
  show_entity_container(details);

  omega_web_request('cosmos::get_resource_sources', asteroid.name, function(resource_sources, error){
    if(error == null){
      var details = [];
      for(var r in resource_sources){
        var res = resource_sources[r];
        details.push(res.quantity + " of " + res.resource.name + " (" + res.resource.type + ")<br/>");
      }
      append_to_entity_container(details);
    }
  });
}

function draw_cosmos_jump_gate(scene){
  var loc = this;
  var gate = loc.entity;

  var geometry = new THREE.PlaneGeometry( 50, 50 );
  var mesh = new THREE.Mesh( geometry, $scene.materials['jump_gate'] );
  mesh.position.set( loc.x, loc.y, loc.z );
  loc.scene_entities.push(mesh);
  loc.scene_entities.push(geometry);
  scene.add( mesh );

  // if selected draw sphere around gate trigger radius
  if(gate.selected){
    var radius = gate.trigger_distance, segments = 32, rings = 32;
    var sphere = new THREE.Mesh(new THREE.SphereGeometry(radius, segments, rings), $scene.materials['jump_gate_selected'] );
    sphere.position.x = loc.x ; sphere.position.y = loc.y ; sphere.position.z = loc.z ;
    scene.add(sphere);
    loc.scene_entities.push(sphere);
    loc.scene_object = sphere;
  }else{
    loc.scene_object = mesh;
  }
}

function unselect_jump_gate(jump_gate){
  $selected_entity = null;
  jump_gate.selected = false;
  jump_gate.scene_location.dirty = true;
  $scene.setup();
  $entity_container_callback = null;
}

function clicked_cosmos_jump_gate(jump_gate){
  // TODO wire up trigger handler
  var details =
    ['Jump Gate to ' + jump_gate.endpoint + '<br/>',
     '@ ' + jump_gate.scene_location.to_s() + "<br/><br/>",
     "<div class='cmd_icon' id='ship_trigger_jg'>Trigger</div>"];
  $selected_entity = jump_gate;
  jump_gate.selected = true;
  jump_gate.scene_location.dirty = true;
  $scene.setup();
  show_entity_container(details);
  $entity_container_callback = function(){ unselect_jump_gate(jump_gate); };
}

function draw_manufactured_ship(scene){
  var loc = this;
  var ship = loc.entity;

  // draw crosshairs representing ship
  var color = '0x';
  if(ship.selected)
    color += "FFFF00";
  else if(ship.docked_at)
    color += "99FFFF";
  else
    color += "00CC00";

  if($scene.materials['ship' + color] == null)
    $scene.materials['ship' + color] = new THREE.LineBasicMaterial({color: parseInt(color)});

  var geometry = new THREE.Geometry();
  geometry.vertices.push(new THREE.Vector3(loc.x - ship.size/2, loc.y, loc.z));
  geometry.vertices.push(new THREE.Vector3(loc.x + ship.size/2, loc.y, loc.z));
  var line = new THREE.Line(geometry, $scene.materials['ship' + color]);
  loc.scene_entities.push(line);
  loc.scene_entities.push(geometry);
  scene.add(line);

  var geometry = new THREE.Geometry();
  geometry.vertices.push(new THREE.Vector3(loc.x, loc.y - ship.size/2, loc.z));
  geometry.vertices.push(new THREE.Vector3(loc.x, loc.y + ship.size/2, loc.z));
  var line = new THREE.Line(geometry, $scene.materials['ship' + color]);
  loc.scene_entities.push(line);
  loc.scene_entities.push(geometry);
  scene.add(line);

  var geometry = new THREE.PlaneGeometry( ship.size, ship.size );
  //var texture = new THREE.MeshFaceMaterial();
  var mesh = new THREE.Mesh(geometry, $scene.materials['ship_surface']);
  mesh.position.set(loc.x, loc.y, loc.z);
  loc.scene_entities.push(mesh);
  loc.scene_entities.push(geometry);
  scene.add(mesh);

  loc.scene_object = mesh;

  // if ship is attacking another, draw line of attack
  if(ship.attacking){
    geometry = new THREE.Geometry();
    geometry.vertices.push(new THREE.Vector3(loc.x, loc.y, loc.z));
    geometry.vertices.push(new THREE.Vector3(ship.attacking.location.x, ship.attacking.location.y + 25, ship.attacking.location.z));
    line = new THREE.Line(geometry, $scene.materials['ship_attacking']);
    loc.scene_entities.push(line);
    loc.scene_entities.push(geometry);
    scene.add(line);
  }

  // if ship is mining, draw line to mining target
  if(ship.mining){
    geometry = new THREE.Geometry();
    geometry.vertices.push(new THREE.Vector3(loc.x, loc.y, loc.z));
    geometry.vertices.push(new THREE.Vector3(ship.mining.location.x, ship.mining.location.y + 25, ship.mining.location.z));
    line = new THREE.Line(geometry, $scene.materials['ship_mining']);
    loc.scene_entities.push(line);
    loc.scene_entities.push(geometry);
    scene.add(line);
  }
}

function unselect_ship(ship){
  $selected_entity = null;
  ship.selected = false;
  ship.scene_location.dirty = true;
  $scene.setup();
  $entity_container_callback = null;
}

function clicked_manufactured_ship(ship){
  var details = ['Ship: ' + ship.id + "<br/>", '@ ' + ship.scene_location.to_s() + '<br/>'];

  var txt = 'Resources: <br/>';
  for(var r in ship.resources){
    txt += ship.resources[r] + " of " + r + ", ";
  }
  details.push(txt);

  // TODO wire up handlers
  details.push("<div class='cmd_icon' id='ship_select_move'>move</div>");
  details.push("<div class='cmd_icon' id='ship_select_target'>attack</div>");
  details.push("<div class='cmd_icon' id='ship_select_dock'>dock</div>");
  details.push("<div class='cmd_icon' id='ship_undock'>undock</div>");
  details.push("<div class='cmd_icon' id='ship_select_transfer'>transfer</div>");
  details.push("<div class='cmd_icon' id='ship_select_mine'>mine</div>");
  show_entity_container(details);

  if(!ship.docked_at){
    $('#ship_select_dock').show();
    $('#ship_undock').hide();
    $('#ship_select_transfer').hide();
  }else{
    $('#ship_select_dock').hide();
    $('#ship_undock').show();
    $('#ship_select_transfer').show();
  }

  $selected_entity = ship;
  ship.selected = true;
  ship.scene_location.dirty = true;
  $entity_container_callback = function(){ unselect_ship(ship); };
  $scene.setup();
}

function draw_manufactured_station(scene){
  var loc = this;
  var station = loc.entity;

  var color = '0x';
  if(station.selected)
    color += "FFFF00";
  else
    color += "0000CC";

  if($scene.materials['station' + color] == null)
    $scene.materials['station' + color] = new THREE.LineBasicMaterial({color: parseInt(color)});

  var geometry = new THREE.Geometry();
  geometry.vertices.push(new THREE.Vector3(loc.x - station.size/2, loc.y, loc.z));
  geometry.vertices.push(new THREE.Vector3(loc.x + station.size/2, loc.y, loc.z));
  var line = new THREE.Line(geometry, $scene.materials['station'+color]);
  loc.scene_entities.push(line);
  scene.add(line);

  var geometry = new THREE.Geometry();
  geometry.vertices.push(new THREE.Vector3(loc.x, loc.y - station.size/2, loc.z));
  geometry.vertices.push(new THREE.Vector3(loc.x, loc.y + station.size/2, loc.z));
  var line = new THREE.Line(geometry, $scene.materials['station'+color]);
  loc.scene_entities.push(line);
  loc.scene_entities.push(geometry);
  scene.add(line);

  var geometry = new THREE.PlaneGeometry( station.size, station.size );
  var mesh = new THREE.Mesh(geometry, $scene.materials['station_surface']);
  mesh.position.set(loc.x, loc.y, loc.z);
  loc.scene_entities.push(mesh);
  loc.scene_entities.push(geometry);
  scene.add(mesh);

  loc.scene_object = mesh;
}

function unselect_station(station){
  $selected_entity = null;
  station.selected = false;
  station.scene_location.dirty = true;
  $scene.setup();
  $entity_container_callback = null;
}

function clicked_manufactured_station(station){
  var details = ['Station: ' + station.id + "<br/>", '@' + station.scene_location.to_s() + '<br/>'];

  var txt = 'Resources: <br/>';
  for(var r in station.resources){
    txt += station.resources[r] + " of " + r + ", ";
  }
  details.push(txt);

  // TODO wire up construction handler
  details.push("<div class='cmd_icon' id='station_select_construction'>construct</div>");
  show_entity_container(details);

  $selected_entity = station;
  station.selected = true;
  station.scene_location.dirty = true;
  $entity_container_callback = function(){ unselect_station(station); };
  $scene.setup();
}

function set_callback_methods(loc){
  if(loc.entity.json_class == "Cosmos::SolarSystem"){
    loc.click = clicked_cosmos_system;
    loc.draw  = draw_cosmos_system;

  }else if(loc.entity.json_class == "Cosmos::Star"){
    loc.click = clicked_cosmos_star;
    loc.draw  = draw_cosmos_star;

  }else if(loc.entity.json_class == "Cosmos::Planet"){
    loc.click = clicked_cosmos_planet;
    loc.draw  = draw_cosmos_planet;

  }else if(loc.entity.json_class == "Cosmos::Asteroid"){
    loc.click = clicked_cosmos_asteroid;
    loc.draw  = draw_cosmos_asteroid;

  }else if(loc.entity.json_class == "Cosmos::JumpGate"){
    loc.click = clicked_cosmos_jump_gate;
    loc.draw = draw_cosmos_jump_gate;

  }else if(loc.entity.json_class == "Manufactured::Ship"){
    loc.click = clicked_manufactured_ship;
    loc.draw  = draw_manufactured_ship;

  }else if(loc.entity.json_class == "Manufactured::Station"){
    loc.click = clicked_manufactured_station;
    loc.draw  = draw_manufactured_station;
  }
}

function setup_command_handlers(){
  $('#ship_trigger_jg').live('click', function(e){
    trigger_jump_gate($selected_entity);
  });

  $('#ship_select_move').live('click', function(e){
    select_ship_destination($selected_entity);
  });

  $('#ship_move_to').live('click', function(e){
    move_ship_to($selected_entity, $('#dest_x').attr('value'),
                                   $('#dest_y').attr('value'),
                                   $('#dest_z').attr('value'));
  });

  $('#ship_select_target').live('click', function(e){
    select_ship_target($selected_entity);
  });

  $('#ship_launch_attack').live('click', function(e){
    ship_launch_attack($selected_entity, 'TODO');
  });

  $('#ship_select_dock').live('click', function(e){
    ship_select_dock($selected_entity);
  });

  $('.ship_dock_at').live('click', function(e){
    ship_dock_at($selected_entity, $(e.currentTarget).html());
  });

  $('#ship_undock').live('click', function(e){
    ship_undock($selected_entity);
  });

  $('#ship_select_transfer').live('click', function(e){
    ship_select_transfer($selected_entity);
  });

  $('.ship_transfer').live('click', function(e){
    ship_transfer($selected_entity, $(e.currentTarget).html());
  });

  $('#ship_select_mine').live('click', function(e){
    ship_select_mining($selected_entity);
  });

  $('#ship_start_mining').live('click', function(e){
    ship_start_mining($selected_entity, 'TODO');
  });

  $('#station_select_construction').live('click', function(e){
    station_construct($selected_entity);
  });

}

//////////////////////////////////////////////////////////

$(document).ready(function(){ 
  setup_command_handlers();
  $grid.init();
  $scene.init().render();
});
