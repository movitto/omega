// renders omega components using the three.js 3D javascript library
//
// Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
// Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

function OmegaCamera(){
  this.scene_camera = new THREE.PerspectiveCamera(75, 900 / 400, 1, 1000 );
  //this.scene_camera = new THREE.OrthographicCamera(-500, 500, 500, -500, -1000, 1000);
  this.scene_camera.position.z = 500;

  this.zoom = function(distance){
    var x = canvas_ui.camera.scene_camera.position.x,
        y = canvas_ui.camera.scene_camera.position.y,
        z = canvas_ui.camera.scene_camera.position.z;
    var dist  = Math.sqrt(Math.pow(x, 2) + Math.pow(y, 2) + Math.pow(z, 2));
    var phi = Math.atan2(x,z);
    var theta   = Math.acos(y/dist);

    dist += distance;

    z = dist * Math.sin(theta) * Math.cos(phi);
    x = dist * Math.sin(theta) * Math.sin(phi);
    y = dist * Math.cos(theta);

    canvas_ui.camera.scene_camera.position.x = x;
    canvas_ui.camera.scene_camera.position.y = y;
    canvas_ui.camera.scene_camera.position.z = z;

    canvas_ui.camera.scene_camera.lookAt(canvas_ui.scene.position);
    canvas_ui.setup_scene();
  }
  this.rotate = function(theta_distance, phi_distance){
    var x = canvas_ui.camera.scene_camera.position.x,
        y = canvas_ui.camera.scene_camera.position.y,
        z = canvas_ui.camera.scene_camera.position.z;
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

    canvas_ui.camera.scene_camera.position.x = x;
    canvas_ui.camera.scene_camera.position.y = y;
    canvas_ui.camera.scene_camera.position.z = z;

    canvas_ui.camera.scene_camera.lookAt(canvas_ui.scene.position);
    canvas_ui.camera.scene_camera.updateMatrix();
    canvas_ui.setup_scene(); // would rather just 'animate' but components in scene may depend on camera orientation
  }
}

function OmegaUI(){
  this.canvas_container = $('#motel_canvas_container');
  this.canvas           = $('#motel_canvas');
  this.scene = new THREE.Scene();
  this.camera = new OmegaCamera();
  this.scene.add(this.camera.scene_camera);
  this.renderer = new THREE.CanvasRenderer({canvas: this.canvas.get()[0]});
  this.renderer.setSize( 900, 400 );
  this.canvas_container.append(this.renderer.domElement);

  this.scene_locations = [];

  this.clear_scene = function(){
    for(var loc in canvas_ui.scene_locations){
      canvas_ui.scene_locations[loc].remove_from_scene(canvas_ui.scene);
    }
    canvas_ui.scene_locations = [];
  }

  this.setup_scene = function(){
    for(loc in canvas_ui.scene_locations){
      var loco = canvas_ui.scene_locations[loc];
      loco.setup_in_scene(canvas_ui.scene);
    }

    var toggle_grid = $('#motel_toggle_grid_canvas');
    if(toggle_grid){
      if(canvas_ui.showing_grid && (!toggle_grid.is(':checked') ||
         (client.current_system == null && client.current_galaxy == null)))
          canvas_ui.clear_grid();
      else if(toggle_grid.is(':checked') && !canvas_ui.showing_grid)
         canvas_ui.draw_grid();
    }

    canvas_ui.animate();
  }

  this.animate = function(){
    requestAnimationFrame(canvas_ui.render);
  }

  this.render = function(){
    canvas_ui.renderer.render(canvas_ui.scene, canvas_ui.camera.scene_camera);
  };

  this.clear_grid = function(){
    if(canvas_ui.grid_lines){
      for(var gl in canvas_ui.grid_lines){
        canvas_ui.scene.remove(canvas_ui.grid_lines[gl]);
        delete canvas_ui.grid_lines[gl];
      }
    }
    canvas_ui.grid_lines = [];
    canvas_ui.showing_grid = false;
  };

  this.draw_grid = function(){
    var size = 250, step = 100;

    var geometry = new THREE.Geometry();
    var material = new THREE.LineBasicMaterial( { color: 0xcccccc, opacity: 0.4 } );

    for ( var i = - size; i <= size; i += step ) {
      for ( var j = - size; j <= size; j += step ) {
        geometry.vertices.push( new THREE.Vector3( - size, j, i ) );
        geometry.vertices.push( new THREE.Vector3(   size, j, i ) );

        geometry.vertices.push( new THREE.Vector3( i, j, - size ) );
        geometry.vertices.push( new THREE.Vector3( i, j,   size ) );

        geometry.vertices.push( new THREE.Vector3( i, -size, j ) );
        geometry.vertices.push( new THREE.Vector3( i, size,  j ) );
      }
    }

    var line = new THREE.Line( geometry, material, THREE.LinePieces );
    canvas_ui.grid_lines = [];
    canvas_ui.grid_lines.push(line);
    canvas_ui.scene.add( line );
    canvas_ui.showing_grid = true;
  }

  this.draw_nothing = function(entity){};

  this.draw_system = function(system){
    // draw jumpgates
    var material = new THREE.LineBasicMaterial({color: 0xFFFFFF});
    for(var j=0; j<system.jump_gates.length;++j){
      var jg = system.jump_gates[j];
      if(jg.endpoint_system != null){
        var endpoint = jg.endpoint_system.location;
        var geometry = new THREE.Geometry();
        geometry.vertices.push(new THREE.Vector3(system.location.x, system.location.y, system.location.z));
        geometry.vertices.push(new THREE.Vector3(endpoint.x, endpoint.y, endpoint.z));
        var line = new THREE.Line(geometry, material);
        system.location.scene_entities.push(line);
        canvas_ui.scene.add(line);
      }
    }
  
    // draw sphere representing system
    var radius = system.size, segments = 32, rings = 32;
    var sphereMaterial = new THREE.MeshLambertMaterial({color: 0x996600, blending: THREE.AdditiveBlending});
    var sphere = new THREE.Mesh(new THREE.SphereGeometry(radius, segments, rings), sphereMaterial);
    sphere.position.x = system.location.x ; sphere.position.y = system.location.y ; sphere.position.z = system.location.z ;
    system.scene_object = sphere;
    system.location.scene_entities.push(sphere);
    canvas_ui.scene.add(sphere);

    // draw label
    var text3d = new THREE.TextGeometry( system.name, {height: 10, width: 3, curveSegments: 2, font: 'helvetiker', size: 16});
    var textMaterial = new THREE.MeshBasicMaterial( { color: 0x3366FF, overdraw: true } );
    var text = new THREE.Mesh( text3d, textMaterial );
    text.position.x = system.location.x - 50 ; text.position.y = system.location.y - 50 ; text.position.z = system.location.z - 50;
    text.lookAt(canvas_ui.camera.scene_camera.position);
    system.location.scene_entities.push(text);
    canvas_ui.scene.add(text);
  };

  this.draw_star = function(star){
    var radius = star.size, segments = 32, rings = 32;
    var sphereMaterial = new THREE.MeshLambertMaterial({color: '0x' + star.color, blending: THREE.AdditiveBlending });
    var sphere = new THREE.Mesh(new THREE.SphereGeometry(radius, segments, rings), sphereMaterial);
    sphere.position.x = star.location.x ; sphere.position.y = star.location.y ; sphere.position.z = star.location.z ;
    star.scene_object = sphere;
    star.location.scene_entities.push(sphere);
    star.location.scene_entities.push(sphereMaterial);
    canvas_ui.scene.add(sphere);
  };

  this.draw_planet = function(planet){
    var loco = planet.location;

    // draw sphere representing planet
    var radius = planet.size, segments = 32, rings = 32;
    var sphereMaterial = new THREE.MeshLambertMaterial({color: '0x' + planet.color, blending: THREE.AdditiveBlending});
    var sphere = new THREE.Mesh(new THREE.SphereGeometry(radius, segments, rings), sphereMaterial);
    sphere.position.x = planet.location.x ; sphere.position.y = planet.location.y ; sphere.position.z = planet.location.z ;
    planet.scene_object = sphere;
    planet.location.scene_entities.push(sphereMaterial);
    planet.location.scene_entities.push(sphere);
    canvas_ui.scene.add(sphere);

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
    planet.location.scene_entities.push(line);
    planet.location.scene_entities.push(material);
    planet.location.scene_entities.push(geometry);
    canvas_ui.scene.add(line);
  
    // draw moons
    for(var m=0; m<planet.moons.length; ++m){
      var moon = planet.moons[m];
      radius = 5, segments = 32, rings = 32;
      var sphereMaterial = new THREE.MeshLambertMaterial({color: '0x808080', blending: THREE.AdditiveBlending});
      var sphere = new THREE.Mesh(new THREE.SphereGeometry(radius, segments, rings), sphereMaterial);
      sphere.position.x = planet.location.x + moon.location.x ; sphere.position.y = planet.location.y + moon.location.y; sphere.position.z = planet.location.z + moon.location.z;
      moon.scene_object = sphere;
      planet.location.scene_entities.push(sphere);
      planet.location.scene_entities.push(sphereMaterial);
      canvas_ui.scene.add(sphere);
    }
  };
  this.update_planet_location = function(planet){
    planet.scene_object.position.x = planet.location.x;
    planet.scene_object.position.y = planet.location.y;
    planet.scene_object.position.z = planet.location.z;
    for(var m=0; m<planet.moons.length; ++m){
      var moon = planet.moons[m];
      moon.scene_object.position.x = planet.location.x + moon.location.x;
      moon.scene_object.position.y = planet.location.x + moon.location.y;
      moon.scene_object.position.z = planet.location.x + moon.location.z;
    }
  };

  this.draw_asteroid = function(asteroid){
    var text3d = new THREE.TextGeometry( "*", {height: 20, curveSegments: 2, font: 'helvetiker', size: 32});
    var textMaterial = new THREE.MeshBasicMaterial( { color: 0xffffff, overdraw: true } );
    var text = new THREE.Mesh( text3d, textMaterial );
    text.position.x = asteroid.location.x ; text.position.y = asteroid.location.y ; text.position.z = asteroid.location.z;
    asteroid.scene_object = text;
    asteroid.location.scene_entities.push(text);
    asteroid.location.scene_entities.push(textMaterial);
    asteroid.location.scene_entities.push(text3d);
    canvas_ui.scene.add(text);
  };
  this.draw_gate = function(gate){
    var planeTex = THREE.ImageUtils.loadTexture("images/jump_gate.png");
    var planeMat = new THREE.MeshBasicMaterial( { map: planeTex } );

    var geometry = new THREE.PlaneGeometry( 50, 50 );
    var mesh = new THREE.Mesh( geometry, planeMat );
    mesh.rotation.x = 90 * Math.PI / 180;
    mesh.doubleSided = true;
    mesh.position.set( gate.location.x, gate.location.y, gate.location.z );
    gate.location.scene_entities.push(mesh);
    gate.location.scene_entities.push(geometry);
    gate.location.scene_entities.push(planeTex);
    gate.location.scene_entities.push(planeMat);
    canvas_ui.scene.add( mesh );

    // if selected draw sphere around gate trigger radius
    if(gate == controls.selected_gate){
      var radius = gate.trigger_distance, segments = 32, rings = 32;
      var sphereMaterial = new THREE.MeshLambertMaterial({color: 0xffffff, transparent: true, opacity: 0.4});
      var sphere = new THREE.Mesh(new THREE.SphereGeometry(radius, segments, rings), sphereMaterial);
      sphere.position.x = gate.location.x ; sphere.position.y = gate.location.y ; sphere.position.z = gate.location.z ;
      canvas_ui.scene.add(sphere);
      gate.location.scene_entities.push(sphere);
      gate.location.scene_entities.push(sphereMaterial);
      gate.scene_object = sphere;
    }else{
      gate.scene_object = mesh;
    }
  };
  this.draw_station = function(station){
    var material = new THREE.LineBasicMaterial({color: '0x0000CC'});
    var geometry = new THREE.Geometry();
    geometry.vertices.push(new THREE.Vector3(station.location.x - station.size/2, station.location.y, station.location.z));
    geometry.vertices.push(new THREE.Vector3(station.location.x + station.size/2, station.location.y, station.location.z));
    var line = new THREE.Line(geometry, material);
    station.location.scene_entities.push(line);
    station.location.scene_entities.push(material);
    canvas_ui.scene.add(line);

    var geometry = new THREE.Geometry();
    geometry.vertices.push(new THREE.Vector3(station.location.x, station.location.y - station.size/2, station.location.z));
    geometry.vertices.push(new THREE.Vector3(station.location.x, station.location.y + station.size/2, station.location.z));
    var line = new THREE.Line(geometry, material);
    station.location.scene_entities.push(line);
    station.location.scene_entities.push(geometry);
    canvas_ui.scene.add(line);

    var geometry = new THREE.PlaneGeometry( station.size, station.size );
    var texture = new THREE.MeshFaceMaterial({ });
    var mesh = new THREE.Mesh(geometry, texture);
    mesh.doubleSided = true;
    mesh.rotation.x = 90 * Math.PI / 180;
    mesh.position.set(station.location.x, station.location.y, station.location.z);
    station.location.scene_entities.push(mesh);
    station.location.scene_entities.push(geometry);
    station.location.scene_entities.push(texture);
    canvas_ui.scene.add(mesh);

    station.scene_object = mesh;
  };
  this.draw_ship = function(ship){
    // draw crosshairs representing ship
    var color = '0x';
    if(ship.selected)
      color += "FFFF00";
    else if(ship.docked_at)
      color += "99FFFF";
    else
      color += "00CC00";
    var material = new THREE.LineBasicMaterial({color: color});

    var geometry = new THREE.Geometry();
    geometry.vertices.push(new THREE.Vector3(ship.location.x - ship.size/2, ship.location.y, ship.location.z));
    geometry.vertices.push(new THREE.Vector3(ship.location.x + ship.size/2, ship.location.y, ship.location.z));
    var line = new THREE.Line(geometry, material);
    ship.location.scene_entities.push(line);
    ship.location.scene_entities.push(geometry);
    canvas_ui.scene.add(line);

    var geometry = new THREE.Geometry();
    geometry.vertices.push(new THREE.Vector3(ship.location.x, ship.location.y - ship.size/2, ship.location.z));
    geometry.vertices.push(new THREE.Vector3(ship.location.x, ship.location.y + ship.size/2, ship.location.z));
    var line = new THREE.Line(geometry, material);
    ship.location.scene_entities.push(line);
    ship.location.scene_entities.push(geometry);
    canvas_ui.scene.add(line);

    var geometry = new THREE.PlaneGeometry( ship.size, ship.size );
    var texture = new THREE.MeshFaceMaterial({ });
    var mesh = new THREE.Mesh(geometry, texture);
    mesh.doubleSided = true;
    mesh.rotation.x = 90 * Math.PI / 180;
    mesh.position.set(ship.location.x, ship.location.y, ship.location.z);
    ship.location.scene_entities.push(mesh);
    ship.location.scene_entities.push(geometry);
    ship.location.scene_entities.push(texture);
    canvas_ui.scene.add(mesh);

    ship.scene_object = mesh;

    // if ship is attacking another, draw line of attack
    if(ship.attacking){
      material = new THREE.LineBasicMaterial({color: '0xFF0000'});
      geometry = new THREE.Geometry();
      geometry.vertices.push(new THREE.Vector3(ship.location.x, ship.location.y, ship.location.z));
      geometry.vertices.push(new THREE.Vector3(ship.attacking.location.x, ship.attacking.location.y + 25, ship.attacking.location.z));
      line = new THREE.Line(geometry, material);
      ship.location.scene_entities.push(line);
      ship.location.scene_entities.push(material);
      ship.location.scene_entities.push(geometry);
      canvas_ui.scene.add(line);
    }

    // if ship is mining, draw line to mining target
    if(ship.mining){
      material = new THREE.LineBasicMaterial({color: '0x0000FF'});
      geometry = new THREE.Geometry();
      geometry.vertices.push(new THREE.Vector3(ship.location.x, ship.location.y, ship.location.z));
      geometry.vertices.push(new THREE.Vector3(ship.mining.location.x, ship.mining.location.y + 25, ship.mining.location.z));
      line = new THREE.Line(geometry, material);
      ship.location.scene_entities.push(line);
      ship.location.scene_entities.push(material);
      ship.location.scene_entities.push(geometry);
      canvas_ui.scene.add(line);
    }
  };
};
