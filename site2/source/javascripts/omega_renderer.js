function OmegaLocation(iloc){
  // initialize location
  var loc = {};
  if(iloc != null){
    loc.x = iloc.x; loc.y = iloc.y; loc.z = iloc.z
    loc.entity = iloc.entity;
  }

  loc.scene_object = null; // used to detect clicks
  loc.scene_entities = []; // should be removed from scene upon clearing
  loc.dirty = true;        // bool indicating if loc was updated / should be redrawn
  loc.draw  = null;        // draw method

  // should be used to update coordinates so as to set dirty bit
  loc.update = function(x,y,z){
    if(x != null){
      loc.x = x;
      loc.dirty = true;
    }
    if(y != null){
      loc.y = y;
      loc.dirty = true;
    }
    if(z != null){
      loc.x = z;
      loc.dirty = true;
    }
  }

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

    // preload textures
    this.textures = {jump_gate : THREE.ImageUtils.loadTexture("/womega/images/jump_gate.png")};

    return this;
  },

  set_target : function(new_target){
    this.clear();
    this.target = new_target;
  },

  add_location : function(loc){
    var oloc = new OmegaLocation(loc);
    set_draw_method(oloc);
    this.locations.push(oloc);
    return oloc;
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
      var loco = this.locations[loc];
      if(loco.dirty){
        for(var scene_entity in loco.scene_entities){
          this._scene.remove(loco.scene_entities[scene_entity]);
          delete loco.scene_entities[scene_entity];
        }
        loco.scene_entities = [];
        if(loco.draw != null)
          loco.draw(this._scene);
      }
      loco.dirty = false;
    }

    // TODO setup grid again

    this.animate();
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

  var material = new THREE.LineBasicMaterial({color: 0xFFFFFF});
  for(var j=0; j<system.jump_gates.length;++j){
    var jg = system.jump_gates[j];
    var endpoint = $entity_tracker[jg.endpoint].location;
    var geometry = new THREE.Geometry();
    geometry.vertices.push(new THREE.Vector3(loc.x, loc.y, loc.z));
    geometry.vertices.push(new THREE.Vector3(endpoint.x, endpoint.y, endpoint.z));
    var line = new THREE.Line(geometry, material);
    loc.scene_entities.push(line);
    scene.add(line);
  }
  
  // draw sphere representing system
  var radius = system.size, segments = 32, rings = 32;
  var sphereMaterial = new THREE.MeshLambertMaterial({color: 0x996600, blending: THREE.AdditiveBlending});
  var sphere = new THREE.Mesh(new THREE.SphereGeometry(radius, segments, rings), sphereMaterial);
  sphere.position.x = loc.x ; sphere.position.y = loc.y ; sphere.position.z = loc.z ;
  loc.scene_object = sphere;
  loc.scene_entities.push(sphere);
  scene.add(sphere);

  // draw label
  var text3d = new THREE.TextGeometry( system.name, {height: 10, width: 3, curveSegments: 2, font: 'helvetiker', size: 16});
  var textMaterial = new THREE.MeshBasicMaterial( { color: 0x3366FF, overdraw: true } );
  var text = new THREE.Mesh( text3d, textMaterial );
  text.position.x = loc.x - 50 ; text.position.y = loc.y - 50 ; text.position.z = loc.z - 50;
  text.lookAt($camera._camera.position);
  loc.scene_entities.push(text);
  scene.add(text);
}

function draw_cosmos_star(scene){
  var loc = this;
  var star = loc.entity;

  var radius = star.size, segments = 32, rings = 32;
  var sphereMaterial = new THREE.MeshLambertMaterial({color: parseInt('0x' + star.color), blending: THREE.AdditiveBlending });
  var sphere = new THREE.Mesh(new THREE.SphereGeometry(radius, segments, rings), sphereMaterial);
  sphere.position.x = loc.x ; sphere.position.y = loc.y ; sphere.position.z = loc.z ;
  loc.scene_object = sphere;
  loc.scene_entities.push(sphere);
  loc.scene_entities.push(sphereMaterial);
  scene.add(sphere);
}

function draw_cosmos_planet(scene){
  var loc = this;
  var planet = loc.entity;

  // draw sphere representing planet
  var radius = planet.size, segments = 32, rings = 32;
  var sphereMaterial = new THREE.MeshLambertMaterial({color: parseInt('0x' + planet.color), blending: THREE.AdditiveBlending});
  var sphere = new THREE.Mesh(new THREE.SphereGeometry(radius, segments, rings), sphereMaterial);
  sphere.position.x = loc.x ; sphere.position.y = loc.y ; sphere.position.z = loc.z ;
  loc.scene_object = sphere;
  loc.scene_entities.push(sphereMaterial);
  loc.scene_entities.push(sphere);
  scene.add(sphere);

  // draw orbit
  var material = new THREE.LineBasicMaterial({color: 0xAAAAAA});
  var geometry = new THREE.Geometry();
  for(var o in planet.orbit){
    if(o != 0){
      var orbit  = planet.orbit[o];
      var porbit = planet.orbit[o-1];
      geometry.vertices.push(new THREE.Vector3(orbit[0],  orbit[1],  orbit[2]));
      geometry.vertices.push(new THREE.Vector3(porbit[0], porbit[1], porbit[2]));
    }
  }
  var line = new THREE.Line(geometry, material);
  loc.scene_entities.push(line);
  loc.scene_entities.push(material);
  loc.scene_entities.push(geometry);
  scene.add(line);
  
  // draw moons
  for(var m=0; m<planet.moons.length; ++m){
    var moon = planet.moons[m];
    radius = 5, segments = 32, rings = 32;
    var sphereMaterial = new THREE.MeshLambertMaterial({color: 0x808080, blending: THREE.AdditiveBlending});
    var sphere = new THREE.Mesh(new THREE.SphereGeometry(radius, segments, rings), sphereMaterial);
    sphere.position.x = loc.x + moon.location.x ; sphere.position.y = loc.y + moon.location.y; sphere.position.z = loc.z + moon.location.z;
    //moon.scene_object = sphere;
    loc.scene_entities.push(sphere);
    loc.scene_entities.push(sphereMaterial);
    scene.add(sphere);
  }
}

function draw_cosmos_asteroid(scene){
  var loc = this;
  var asteroid = loc.entity;

  var text3d = new THREE.TextGeometry( "*", {height: 20, curveSegments: 2, font: 'helvetiker', size: 32});
  var textMaterial = new THREE.MeshBasicMaterial( { color: 0xffffff, overdraw: true } );
  var text = new THREE.Mesh( text3d, textMaterial );
  text.position.x = loc.x ; text.position.y = loc.y ; text.position.z = loc.z;
  loc.scene_object = text;
  loc.scene_entities.push(text);
  loc.scene_entities.push(textMaterial);
  loc.scene_entities.push(text3d);
  scene.add(text);
}

function draw_cosmos_jump_gate(scene){
  var loc = this;
  var gate = loc.entity;

  var planeMat = new THREE.MeshBasicMaterial( { map: $scene.textures['jump_gate'] } );

  var geometry = new THREE.PlaneGeometry( 50, 50 );
  var mesh = new THREE.Mesh( geometry, planeMat );
  planeMat.side = THREE.DoubleSide; // relatively new for three.js (mesh.doubleSided = true is old way)
  mesh.position.set( loc.x, loc.y, loc.z );
  loc.scene_entities.push(mesh);
  loc.scene_entities.push(geometry);
  loc.scene_entities.push(planeMat);
  scene.add( mesh );

  // if selected draw sphere around gate trigger radius
//  if(gate == controls.selected_gate){
//    var radius = gate.trigger_distance, segments = 32, rings = 32;
//    var sphereMaterial = new THREE.MeshLambertMaterial({color: 0xffffff, transparent: true, opacity: 0.4});
//    var sphere = new THREE.Mesh(new THREE.SphereGeometry(radius, segments, rings), sphereMaterial);
//    sphere.position.x = loc.x ; sphere.position.y = loc.y ; sphere.position.z = loc.z ;
//    scene.add(sphere);
//    loc.scene_entities.push(sphere);
//    loc.scene_entities.push(sphereMaterial);
//    gate.scene_object = sphere;
//  }else{
    loc.scene_object = mesh;
//  }
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
  var material = new THREE.LineBasicMaterial({color: parseInt(color)});

  var geometry = new THREE.Geometry();
  geometry.vertices.push(new THREE.Vector3(loc.x - ship.size/2, loc.y, loc.z));
  geometry.vertices.push(new THREE.Vector3(loc.x + ship.size/2, loc.y, loc.z));
  var line = new THREE.Line(geometry, material);
  loc.scene_entities.push(line);
  loc.scene_entities.push(geometry);
  scene.add(line);

  var geometry = new THREE.Geometry();
  geometry.vertices.push(new THREE.Vector3(loc.x, loc.y - ship.size/2, loc.z));
  geometry.vertices.push(new THREE.Vector3(loc.x, loc.y + ship.size/2, loc.z));
  var line = new THREE.Line(geometry, material);
  loc.scene_entities.push(line);
  loc.scene_entities.push(geometry);
  scene.add(line);

  var geometry = new THREE.PlaneGeometry( ship.size, ship.size );
  var texture = new THREE.LineBasicMaterial( { } );
  //var texture = new THREE.MeshFaceMaterial();
  var mesh = new THREE.Mesh(geometry, texture);
  texture.side = THREE.DoubleSide;
  mesh.position.set(loc.x, loc.y, loc.z);
  loc.scene_entities.push(mesh);
  loc.scene_entities.push(geometry);
  loc.scene_entities.push(texture);
  scene.add(mesh);

  loc.scene_object = mesh;

  // if ship is attacking another, draw line of attack
  if(ship.attacking){
    material = new THREE.LineBasicMaterial({color: 0xFF0000});
    geometry = new THREE.Geometry();
    geometry.vertices.push(new THREE.Vector3(loc.x, loc.y, loc.z));
    geometry.vertices.push(new THREE.Vector3(ship.attacking.location.x, ship.attacking.location.y + 25, ship.attacking.location.z));
    line = new THREE.Line(geometry, material);
    loc.scene_entities.push(line);
    loc.scene_entities.push(material);
    loc.scene_entities.push(geometry);
    scene.add(line);
  }

  // if ship is mining, draw line to mining target
  if(ship.mining){
    material = new THREE.LineBasicMaterial({color: 0x0000FF});
    geometry = new THREE.Geometry();
    geometry.vertices.push(new THREE.Vector3(loc.x, loc.y, loc.z));
    geometry.vertices.push(new THREE.Vector3(ship.mining.location.x, ship.mining.location.y + 25, ship.mining.location.z));
    line = new THREE.Line(geometry, material);
    loc.scene_entities.push(line);
    loc.scene_entities.push(material);
    loc.scene_entities.push(geometry);
    scene.add(line);
  }
}

function draw_manufactured_station(scene){
  var loc = this;
  var station = loc.entity;

  var material = new THREE.LineBasicMaterial({color: 0x0000CC});
  var geometry = new THREE.Geometry();
  geometry.vertices.push(new THREE.Vector3(loc.x - station.size/2, loc.y, loc.z));
  geometry.vertices.push(new THREE.Vector3(loc.x + station.size/2, loc.y, loc.z));
  var line = new THREE.Line(geometry, material);
  loc.scene_entities.push(line);
  loc.scene_entities.push(material);
  scene.add(line);

  var geometry = new THREE.Geometry();
  geometry.vertices.push(new THREE.Vector3(loc.x, loc.y - station.size/2, loc.z));
  geometry.vertices.push(new THREE.Vector3(loc.x, loc.y + station.size/2, loc.z));
  var line = new THREE.Line(geometry, material);
  loc.scene_entities.push(line);
  loc.scene_entities.push(geometry);
  scene.add(line);

  var geometry = new THREE.PlaneGeometry( station.size, station.size );
  var texture = new THREE.LineBasicMaterial( { } );
  //var texture = new THREE.MeshFaceMaterial({ });
  var mesh = new THREE.Mesh(geometry, texture);
  texture.side = THREE.DoubleSide;
  mesh.position.set(loc.x, loc.y, loc.z);
  loc.scene_entities.push(mesh);
  loc.scene_entities.push(geometry);
  loc.scene_entities.push(texture);
  scene.add(mesh);

  loc.scene_object = mesh;
}

// TODO implement these methods (take since entity, create scene objects,
//      add to scene and local entity
function set_draw_method(loc){
  if(loc.entity.json_class == "Cosmos::SolarSystem"){
    loc.draw = draw_cosmos_system;

  }else if(loc.entity.json_class == "Cosmos::Star"){
    loc.draw = draw_cosmos_star;

  }else if(loc.entity.json_class == "Cosmos::Planet"){
    loc.draw = draw_cosmos_planet;

  }else if(loc.entity.json_class == "Cosmos::Asteroid"){
    loc.draw = draw_cosmos_asteroid;

  }else if(loc.entity.json_class == "Cosmos::JumpGate"){
    loc.draw = draw_cosmos_jump_gate;

  }else if(loc.entity.json_class == "Manufactured::Ship"){
    loc.draw = draw_manufactured_ship;

  }else if(loc.entity.json_class == "Manufactured::Station"){
    loc.draw = draw_manufactured_station;
  }
}

//////////////////////////////////////////////////////////

$(document).ready(function(){ 
  $grid.init();
  $scene.init().render();
});
