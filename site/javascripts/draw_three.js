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

  this.setup_scene = function(){
    // FIXME optimize object removal and adding so that only updated locations are refreshed

    for(var obji = canvas_ui.scene.__objects.length-1;obji>=0;obji--){
      var obj = canvas_ui.scene.__objects[obji];
      canvas_ui.scene.remove( obj );
    }

    for(loc in client.locations){
      var loco = client.locations[loc];
      loco.draw(loco.entity);
    }

    var toggle_grid = $('#motel_toggle_grid_canvas');
    if(toggle_grid && toggle_grid.is(':checked') &&
       (client.current_system || client.current_galaxy))
         canvas_ui.draw_grid();

    canvas_ui.animate();
  }

  this.animate = function(){
    requestAnimationFrame(canvas_ui.render);
  }

  this.render = function(){
    canvas_ui.renderer.render(canvas_ui.scene, canvas_ui.camera.scene_camera);
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
    canvas_ui.scene.add( line );
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
        canvas_ui.scene.add(line);
      }
    }
  
    // draw sphere representing system
    var radius = system.size, segments = 32, rings = 32;
    var sphereMaterial = new THREE.MeshLambertMaterial({color: 0x996600, blending: THREE.AdditiveBlending});
    var sphere = new THREE.Mesh(new THREE.SphereGeometry(radius, segments, rings), sphereMaterial);
    sphere.position.x = system.location.x ; sphere.position.y = system.location.y ; sphere.position.z = system.location.z ;
    system.scene_object = sphere;
    canvas_ui.scene.add(sphere);

    // draw label
    var text3d = new THREE.TextGeometry( system.name, {height: 10, width: 3, curveSegments: 2, font: 'helvetiker', size: 16});
    var textMaterial = new THREE.MeshBasicMaterial( { color: 0x3366FF, overdraw: true } );
    var text = new THREE.Mesh( text3d, textMaterial );
    text.position.x = system.location.x - 50 ; text.position.y = system.location.y - 50 ; text.position.z = system.location.z - 50;
    text.lookAt(canvas_ui.camera.scene_camera.position);
    canvas_ui.scene.add(text);
  };

  this.draw_star = function(star){
    var radius = star.size, segments = 32, rings = 32;
    var sphereMaterial = new THREE.MeshLambertMaterial({color: '0x' + star.color, blending: THREE.AdditiveBlending });
    var sphere = new THREE.Mesh(new THREE.SphereGeometry(radius, segments, rings), sphereMaterial);
    sphere.position.x = star.location.x ; sphere.position.y = star.location.y ; sphere.position.z = star.location.z ;
    star.scene_object = sphere;
    canvas_ui.scene.add(sphere);
  };

  this.draw_orbit = function(orbit){
    if(orbit.previous){
      var material = new THREE.LineBasicMaterial({color: 0xAAAAAA});
      var geometry = new THREE.Geometry();
      geometry.vertices.push(new THREE.Vector3(orbit.location.x, orbit.location.y, orbit.location.z));
      geometry.vertices.push(new THREE.Vector3(orbit.previous.location.x, orbit.previous.location.y, orbit.previous.location.z));
      var line = new THREE.Line(geometry, material);
      canvas_ui.scene.add(line);
    }
  };
  this.draw_planet = function(planet){
    var loco = planet.location;

    // draw sphere representing planet
    var radius = planet.size, segments = 32, rings = 32;
    var sphereMaterial = new THREE.MeshLambertMaterial({color: '0x' + planet.color, blending: THREE.AdditiveBlending});
    var sphere = new THREE.Mesh(new THREE.SphereGeometry(radius, segments, rings), sphereMaterial);
    sphere.position.x = planet.location.x ; sphere.position.y = planet.location.y ; sphere.position.z = planet.location.z ;
    planet.scene_object = sphere;
    canvas_ui.scene.add(sphere);
  
    // draw moons
    for(var m=0; m<planet.moons.length; ++m){
      var moon = planet.moons[m];
      radius = 5, segments = 32, rings = 32;
      var sphereMaterial = new THREE.MeshLambertMaterial({color: '0x808080', blending: THREE.AdditiveBlending});
      var sphere = new THREE.Mesh(new THREE.SphereGeometry(radius, segments, rings), sphereMaterial);
      sphere.position.x = planet.location.x + moon.location.x ; sphere.position.y = planet.location.y + moon.location.y; sphere.position.z = planet.location.z + moon.location.z;
      moon.scene_object = sphere;
      canvas_ui.scene.add(sphere);
    }
  };
  this.draw_asteroid = function(asteroid){
    var text3d = new THREE.TextGeometry( "*", {height: 20, curveSegments: 2, font: 'helvetiker', size: 32});
    var textMaterial = new THREE.MeshBasicMaterial( { color: 0xffffff, overdraw: true } );
    var text = new THREE.Mesh( text3d, textMaterial );
    text.position.x = asteroid.location.x ; text.position.y = asteroid.location.y ; text.position.z = asteroid.location.z;
    asteroid.scene_object = text;
    canvas_ui.scene.add(text);
  };
  this.draw_gate = function(gate){
    var planeTex = THREE.ImageUtils.loadTexture("images/jump_gate.png");
    var planeMat = new THREE.MeshBasicMaterial( { map: planeTex } );

    geometry = new THREE.PlaneGeometry( 50, 50 );
    mesh = new THREE.Mesh( geometry, planeMat );
    mesh.rotation.x = 90 * Math.PI / 180;
    mesh.doubleSided = true;
    mesh.position.set( gate.location.x, gate.location.y, gate.location.z );
    gate.scene_object = mesh;
    canvas_ui.scene.add( mesh );

    // TODO if selected draw circle around gate
  };
  this.draw_station = function(station){
    var material = new THREE.LineBasicMaterial({color: '0x0000CC'});
    var geometry = new THREE.Geometry();
    geometry.vertices.push(new THREE.Vector3(station.location.x - station.size/2, station.location.y, station.location.z));
    geometry.vertices.push(new THREE.Vector3(station.location.x + station.size/2, station.location.y, station.location.z));
    var line = new THREE.Line(geometry, material);
    canvas_ui.scene.add(line);

    geometry = new THREE.Geometry();
    geometry.vertices.push(new THREE.Vector3(station.location.x, station.location.y - station.size/2, station.location.z));
    geometry.vertices.push(new THREE.Vector3(station.location.x, station.location.y + station.size/2, station.location.z));
    line = new THREE.Line(geometry, material);
    canvas_ui.scene.add(line);

    var geometry = new THREE.PlaneGeometry( station.size, station.size );
    var texture = new THREE.MeshFaceMaterial({ });
    var mesh = new THREE.Mesh(geometry, texture);
    mesh.doubleSided = true;
    mesh.rotation.x = 90 * Math.PI / 180;
    mesh.position.set(station.location.x, station.location.y, station.location.z);
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
    canvas_ui.scene.add(line);

    geometry = new THREE.Geometry();
    geometry.vertices.push(new THREE.Vector3(ship.location.x, ship.location.y - ship.size/2, ship.location.z));
    geometry.vertices.push(new THREE.Vector3(ship.location.x, ship.location.y + ship.size/2, ship.location.z));
    line = new THREE.Line(geometry, material);
    canvas_ui.scene.add(line);

    var geometry = new THREE.PlaneGeometry( ship.size, ship.size );
    var texture = new THREE.MeshFaceMaterial({ });
    var mesh = new THREE.Mesh(geometry, texture);
    mesh.doubleSided = true;
    mesh.rotation.x = 90 * Math.PI / 180;
    mesh.position.set(ship.location.x, ship.location.y, ship.location.z);
    canvas_ui.scene.add(mesh);

    ship.scene_object = mesh;

    // if ship is attacking another, draw line of attack
    if(ship.attacking){
      material = new THREE.LineBasicMaterial({color: '0xFF0000'});
      geometry = new THREE.Geometry();
      geometry.vertices.push(new THREE.Vector3(ship.location.x, ship.location.y, ship.location.z));
      geometry.vertices.push(new THREE.Vector3(ship.attacking.location.x, ship.attacking.location.y + 25, ship.attacking.location.z));
      line = new THREE.Line(geometry, material);
      canvas_ui.scene.add(line);
    }

    // if ship is mining, draw line to mining target
    if(ship.mining){
      material = new THREE.LineBasicMaterial({color: '0x0000FF'});
      geometry = new THREE.Geometry();
      geometry.vertices.push(new THREE.Vector3(ship.location.x, ship.location.y, ship.location.z));
      geometry.vertices.push(new THREE.Vector3(ship.mining.location.x, ship.mining.location.y + 25, ship.mining.location.z));
      line = new THREE.Line(geometry, material);
      canvas_ui.scene.add(line);
    }
  };
};
