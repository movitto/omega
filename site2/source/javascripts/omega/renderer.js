/* Omega Rendering Operations
 *
 * Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

require("javascripts/vendor/mousehold");
require('javascripts/vendor/three');
require('javascripts/vendor/helvetiker_font/helvetiker_regular.typeface');

/////////////////////////////////////// Omega Canvas Camera

/* Initialize new Omega Camera
 */
function OmegaCamera(){

  /////////////////////////////////////// private data

  var _camera = new THREE.PerspectiveCamera(75, 900 / 400, 1, 1000 );
  //var camera = new THREE.OrthographicCamera(-500, 500, 500, -500, -1000, 1000);

  /////////////////////////////////////// public methods

  this.position = function(position){
    if(position && position.x)
      _camera.position.x = position.x;

    if(position && position.y)
      _camera.position.y = position.y;

    if(position && position.z)
      _camera.position.z = position.z;

    return {x : _camera.position.x,
            y : _camera.position.y,
            z : _camera.position.z};
  }

  this.zoom = function(distance){
    var x = _camera.position.x,
        y = _camera.position.y,
        z = _camera.position.z;
    var dist  = Math.sqrt(Math.pow(x, 2) + Math.pow(y, 2) + Math.pow(z, 2));
    var phi = Math.atan2(x,z);
    var theta   = Math.acos(y/dist);

    if((dist + distance) <= 0) return;
    dist += distance;

    z = dist * Math.sin(theta) * Math.cos(phi);
    x = dist * Math.sin(theta) * Math.sin(phi);
    y = dist * Math.cos(theta);

    _camera.position.x = x;
    _camera.position.y = y;
    _camera.position.z = z;

    _camera.lookAt($omega_scene.position());
    $omega_scene.animate();
  }

  this.rotate = function(theta_distance, phi_distance){
    var x = _camera.position.x,
        y = _camera.position.y,
        z = _camera.position.z;
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

    _camera.position.x = x;
    _camera.position.y = y;
    _camera.position.z = z;

    _camera.lookAt($omega_scene.position());
    _camera.updateMatrix();
    $omega_scene.animate();
  }

  // XXX OmegaScene and canvas clicked handler requires access to three.js camera
  this.scene_camera = function(){
    return _camera;
  }

  /////////////////////////////////////// initialization

  // wire up camera controls

  if(jQuery.fn.mousehold){

    $('#cam_rotate_right').mousehold(function(e, ctr){
      $omega_camera.rotate(0.0, 0.2);
    });

    $('#cam_rotate_left').mousehold(function(e, ctr){
      $omega_camera.rotate(0.0, -0.2);
    });

    $('#cam_rotate_up').mousehold(function(e, ctr){
      $omega_camera.rotate(-0.2, 0.0);
    });

    $('#cam_rotate_down').mousehold(function(e, ctr){
      $omega_camera.rotate(0.2, 0.0);
    });

    $('#cam_zoom_out').mousehold(function(e, ctr){
      $omega_camera.zoom(20);
    });

    $('#cam_zoom_in').mousehold(function(e, ctr){
      $omega_camera.zoom(-20);
    });

  }
}

/////////////////////////////////////// Omega Canvas Grid

/* Initialize new Omega Grid
 */
function OmegaGrid(){

  /////////////////////////////////////// private data
  var size = 250;

  var step = 100;

  var geometry = new THREE.Geometry();

  var material = new THREE.LineBasicMaterial( { color: 0xcccccc, opacity: 0.4 } );

  var showing_grid = false;

  /////////////////////////////////////// public methods

  this.show = function(){
    $omega_scene.add( grid_line );
    showing_grid = true;
  }

  this.hide = function(){
    $omega_scene._scene.remove(grid_line);
    showing_grid = false;
  }

  this.toggle = function(){
    var toggle_grid = $('#toggle_grid_canvas');
    if(toggle_grid){
      if(toggle_grid.is(':checked'))
        this.show();
      else
        this.hide();
    }
    $omega_scene.animate();
  }

  /////////////////////////////////////// initialization

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

  var grid_line = new THREE.Line( geometry, material, THREE.LinePieces );

  // wire up grid controls
  $('#toggle_grid_canvas').live('click', function(e){ $omega_grid.toggle(); });
  $('#toggle_grid_canvas').attr('checked', false);
}

/////////////////////////////////////// Omega Scene Selection

/* Initialize new Omega Selection
 */
function OmegaSelection(){
  /////////////////////////////////////// private data

  var selected_entities   =   [];

  /////////////////////////////////////// public methods

  this.is_selected = function(entity_id){
    for(var se in selected_entities){
      if(selected_entities[se] == entity_id)
        return true;
    }

    return false;
  }

  this.select = function(entity_id){
    if(this.is_selected(entity_id))
      return;
    selected_entities.push(entity_id);
  }

  this.unselect = function(entity_id){
    for(var index in selected_entities){
      if(selected_entities[index] == entity_id){
        selected_entities.splice(index, 1);
        return;
      }
    }
  }

  // XXX might not be best to expose a 'single' selection, but works for now
  this.selected = function(){
    return selected_entities[0];
  }
}


/////////////////////////////////////// Omega Canvas Scene

/* Initialize new Omega Scene
 */
function OmegaScene(){
  /////////////////////////////////////// private data

  var _canvas   = $('#omega_canvas').get()[0];

  var _scene    = new THREE.Scene();

  var _renderer = new THREE.CanvasRenderer({canvas: _canvas});
  _renderer.setSize( 900, 400 );

  $omega_camera.position({z : 500});

  var entities = {};

  var scene_changed_callback = null;

  var root_entity    = null;

  /////////////////////////////////////// public (read-only) data

  // preload textures & other resources
  var textures   = {jump_gate : THREE.ImageUtils.loadTexture("/womega/images/jump_gate.png")};
  this.materials = {line      : new THREE.LineBasicMaterial({color: 0xFFFFFF}),
                    system    : new THREE.MeshLambertMaterial({color: 0x996600, blending: THREE.AdditiveBlending}),
                    system_label : new THREE.MeshBasicMaterial( { color: 0x3366FF, overdraw: true } ),
                    orbit : new THREE.LineBasicMaterial({color: 0xAAAAAA}),
                    moon : new THREE.MeshLambertMaterial({color: 0x808080, blending: THREE.AdditiveBlending}),
                    asteroid : new THREE.MeshBasicMaterial( { color: 0xffffff, overdraw: true }),
                    jump_gate : new THREE.MeshBasicMaterial( { map: textures['jump_gate'] } ),
                    jump_gate_selected : new THREE.MeshLambertMaterial({color: 0xffffff, transparent: true, opacity: 0.4}),
                    ship_surface : new THREE.LineBasicMaterial( { } ), // new THREE.MeshFaceMaterial({ });
                    ship_attacking : new THREE.LineBasicMaterial({color: 0xFF0000}),
                    ship_mining : new THREE.LineBasicMaterial({color: 0x0000FF}),
                    station_surface : new THREE.LineBasicMaterial( { } )
                   };
  // relatively new for three.js (mesh.doubleSided = true is old way):
  this.materials['jump_gate'].side       = THREE.DoubleSide;
  this.materials['ship_surface'].side    = THREE.DoubleSide;
  this.materials['station_surface'].side = THREE.DoubleSide;

  var mnradius = 5, mnsegments = 32, mnrings = 32;
  this.geometries = {asteroid : new THREE.TextGeometry( "*", {height: 20, curveSegments: 2, font: 'helvetiker', size: 32}),
                    moon     : new THREE.SphereGeometry(mnradius, mnsegments, mnrings),};

  /////////////////////////////////////// private methods

  var clear = function(){
    for(var entity in entities){
      entity = entities[entity]
      for(var scene_entity in entity.scene_objs){
        var se = entity.scene_objs[scene_entity];
        _scene.remove(se);
        delete entity.scene_objs[scene_entity];
      }
      entities[entity.id].scene_objs = [];
      delete entities[entity.id];
    }
    entities = [];
  }

  /////////////////////////////////////// public methods

  this.on_scene_change = function(callback){
    scene_changed_callback = callback;
  }

  this.set_root = function(entity){
    root_entity = entity;
    $omega_canvas.set_background(entity);
    $omega_entity_container.hide();

    clear();
    var children = entity.children();
    for(var child in children){
      child = children[child];
      this.add_entity(child);
      if(child.added_to_scene)
        child.added_to_scene();
    }

    if(scene_changed_callback)
      scene_changed_callback();

    this.animate();
  }

  this.get_root = function(){
    return root_entity;
  }

  this.refresh = function(){
    this.set_root(root_entity);
  }

  this.has = function(entity){
    return entities[entity.id] != null;
  }

  this.add_entity = function(entity){
    entity.load();
    entities[entity.id] = entity;
  }

  // XXX would like to remove this
  this.add = function(scene_obj){
    _scene.add(scene_obj);
  }

  this.remove = function(entity_id){
    var entity = entities[entity_id];
    for(var scene_entity in entity.scene_objs){
      var se = entity.scene_objs[scene_entity];
      _scene.remove(se);
      delete entity.scene_objs[scene_entity];
    }
    entities[entity_id].scene_objs = [];
    delete entities[entity_id];
  }

  this.reload = function(entity){
    this.remove(entity.id);
    this.add_entity(entity);
    this.animate();
  }


  this.animate = function(){
    requestAnimationFrame(this.render);
  }

  this.render = function(){
    _renderer.render(_scene, $omega_camera.scene_camera());
  }

  // XXX camera requries access to scene position
  this.position = function(){
    return _scene.position;
  }

  // XXX canvas clicked handler request access to scene objects
  this.scene_objects = function(){
    return _scene.__objects;
  }

  // XXX canvas clicked handler requires scene entities
  this.entities = function(){
    return entities;
  }

  /////////////////////////////////////// initialization

  this.animate();
}

/////////////////////////////////////// initialization

$(document).ready(function(){ 
  $omega_camera = new OmegaCamera();
  $omega_grid   = new OmegaGrid();
  $omega_selection = new OmegaSelection();
  $omega_scene  = new OmegaScene();
});
