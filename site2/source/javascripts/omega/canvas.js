/* Omega Canvas Operations
 *
 * Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

// since chat is loaded in a partial, we assume $omega_node
// $omega_session, etc have been initialized elsewhere
//require('javascripts/vendor/three.js');
//require('javascripts/omega/user.js');
//require('javascripts/omega/renderer.js');
//require('javascripts/omega/entity.js');
//require('javascripts/omega/commands.js');
require("javascripts/vendor/mousehold.js");

/////////////////////////////////////// Omega Canvas Camera

/* Initialize new Omega Camera
 */
function OmegaCamera(){

  /////////////////////////////////////// private data

  // width/height are overridden when canvas changes size

  var _width  = $omega_config.canvas_width;

  var _height = $omega_config.canvas_height;

  // private initializer
  var new_cam = function(){
    return new THREE.PerspectiveCamera(75, _width / _height, 1, 42000 );
    // new THREE.OrthographicCamera(-500, 500, 500, -500, -1000, 1000);
  }

  var _camera = new_cam();

  var looking_at = null;

  /////////////////////////////////////// public methods

  /* Set the size of the camera
   */
  this.set_size = function(width, height){
    _width = width; _height = height
    _camera = new_cam();
  }

  /* Set camera to its default position
   */
  this.reset = function(){
    var z = (20 * Math.sqrt(_width) + 20 * Math.sqrt(_height));
    this.position({x : 0, y : 0, z : z});
    if(typeof $omega_scene !== "undefined"){
      this.focus($omega_scene.position());
      $omega_scene.animate();
    }
  }

  /* Set/get the point the camera is looking at
   */
  this.focus = function(focus){
    if(looking_at == null){
      var pos = $omega_scene.position();
      looking_at = {x : pos.x, y : pos.y, z : pos.z};
    }
    if(focus != null){
      if(typeof focus.x !== "undefined")
        looking_at.x = focus.x;
      if(typeof focus.y !== "undefined")
        looking_at.y = focus.y;
      if(typeof focus.z !== "undefined")
        looking_at.z = focus.z;
    }
    _camera.lookAt(looking_at);
    return looking_at;
  }

  /* Set/get the camera position.
   *
   * Takes option position param to set camera position
   * before returning current camera position.
   */
  this.position = function(position){
    if(typeof position !== "undefined"){
      if(typeof position.x !== "undefined")
        _camera.position.x = position.x;

      if(typeof position.y !== "undefined")
        _camera.position.y = position.y;

      if(typeof position.z !== "undefined")
        _camera.position.z = position.z;
    }

    return {x : _camera.position.x,
            y : _camera.position.y,
            z : _camera.position.z};
  }

  /* Zoom the Omega Camera the specified distance from its
   * current position along the axis indicated by its focus
   */
  this.zoom = function(distance){
    var focus = this.focus();

    var x = _camera.position.x,
        y = _camera.position.y,
        z = _camera.position.z;
    var dx = x - focus.x,
        dy = y - focus.y,
        dz = z - focus.z;
    var dist  = Math.sqrt(Math.pow(dx, 2) + Math.pow(dy, 2) + Math.pow(dz, 2));
    var phi = Math.atan2(dx,dz);
    var theta   = Math.acos(dy/dist);

    if((dist + distance) <= 0) return;
    dist += distance;

    dz = dist * Math.sin(theta) * Math.cos(phi);
    dx = dist * Math.sin(theta) * Math.sin(phi);
    dy = dist * Math.cos(theta);

    _camera.position.x = dx + focus.x;
    _camera.position.y = dy + focus.y;
    _camera.position.z = dz + focus.z;

    this.focus();
  }

  /* Rotate the camera using a spherical coordiante system.
   * Specify the number of theta and phi degrees to rotate
   * the camera from its current position
   */
  this.rotate = function(theta_distance, phi_distance){
    var focus = this.focus();

    var x = _camera.position.x,
        y = _camera.position.y,
        z = _camera.position.z;
    var dx = x - focus.x,
        dy = y - focus.y,
        dz = z - focus.z;
    var dist  = Math.sqrt(Math.pow(dx, 2) + Math.pow(dy, 2) + Math.pow(dz, 2));
    var phi = Math.atan2(dx,dz);
    var theta   = Math.acos(dy/dist);
    if(dz < 0) theta = 2 * Math.PI - theta; // adjust for acos loss

    theta += theta_distance;
    phi   += phi_distance;

    if(dz < 0) theta = 2 * Math.PI - theta; // readjust for acos loss

    // prevent camera from going too far up / down
    if(theta < 0.5)
      theta = 0.5;
    else if(theta > (Math.PI - 0.5))
      theta = Math.PI - 0.5;

    dz = dist * Math.sin(theta) * Math.cos(phi);
    dx = dist * Math.sin(theta) * Math.sin(phi);
    dy = dist * Math.cos(theta);

    _camera.position.x = dx + focus.x;
    _camera.position.y = dy + focus.y;
    _camera.position.z = dz + focus.z;

    this.focus();
  }

  // Pan the camera along its own X/Y axis
  this.pan = function(x, y){
    var pos   = this.position();
    var focus = this.focus();

    var mat = _camera.matrix;
    _camera.position.x += mat.elements[0] * x;
    _camera.position.y += mat.elements[1] * x;
    _camera.position.z += mat.elements[2] * x;
    _camera.position.x += mat.elements[4] * y;
    _camera.position.y += mat.elements[5] * y;
    _camera.position.z += mat.elements[6] * y;

    var npos   = this.position();
    this.focus({x : focus.x + (npos.x - pos.x),
                y : focus.y + (npos.y - pos.y),
                z : focus.z + (npos.z - pos.z)});
  }

  // XXX OmegaScene and canvas clicked handler requires access to three.js camera
  //     canvas_to_xy in tests/setup.js requires access to internal camera
  this.scene_camera = function(){
    return _camera;
  }


  /////////////////////////////////////// initialization

  // wire up camera controls

  if(jQuery.fn.mousehold){

    $('#cam_reset').click(function(e){
      $omega_camera.reset();
    });

    $('#cam_pan_right').click(function(e){
      $omega_camera.pan(50, 0);
      $omega_scene.animate();
    });

    $('#cam_pan_right').mousehold(function(e, ctr){
      $omega_camera.pan(50, 0);
      $omega_scene.animate();
    });

    $('#cam_pan_left').click(function(e){
      $omega_camera.pan(-50, 0);
      $omega_scene.animate();
    });

    $('#cam_pan_left').mousehold(function(e, ctr){
      $omega_camera.pan(-50, 0);
      $omega_scene.animate();
    });

    $('#cam_pan_up').click(function(e){
      $omega_camera.pan(0, 50);
      $omega_scene.animate();
    });

    $('#cam_pan_up').mousehold(function(e, ctr){
      $omega_camera.pan(0, 50);
      $omega_scene.animate();
    });

    $('#cam_pan_down').click(function(e){
      $omega_camera.pan(0, -50);
      $omega_scene.animate();
    });

    $('#cam_pan_down').mousehold(function(e, ctr){
      $omega_camera.pan(0, -50);
      $omega_scene.animate();
    });

    $('#cam_rotate_right').click(function(e){
      $omega_camera.rotate(0.0, 0.2);
      $omega_scene.animate();
    });

    $('#cam_rotate_right').mousehold(function(e, ctr){
      $omega_camera.rotate(0.0, 0.2);
      $omega_scene.animate();
    });

    $('#cam_rotate_left').click(function(e){
      $omega_camera.rotate(0.0, -0.2);
      $omega_scene.animate();
    });

    $('#cam_rotate_left').mousehold(function(e, ctr){
      $omega_camera.rotate(0.0, -0.2);
      $omega_scene.animate();
    });

    $('#cam_rotate_up').click(function(e){
      $omega_camera.rotate(-0.2, 0.0);
      $omega_scene.animate();
    });

    $('#cam_rotate_up').mousehold(function(e, ctr){
      $omega_camera.rotate(-0.2, 0.0);
      $omega_scene.animate();
    });

    $('#cam_rotate_down').click(function(e){
      $omega_camera.rotate(0.2, 0.0);
      $omega_scene.animate();
    });

    $('#cam_rotate_down').mousehold(function(e, ctr){
      $omega_camera.rotate(0.2, 0.0);
      $omega_scene.animate();
    });

    $('#cam_zoom_out').click(function(e){
      $omega_camera.zoom(20);
      $omega_scene.animate();
    });

    $('#cam_zoom_out').mousehold(function(e, ctr){
      $omega_camera.zoom(20);
      $omega_scene.animate();
    });

    $('#cam_zoom_in').click(function(e){
      $omega_camera.zoom(-20);
      $omega_scene.animate();
    });

    $('#cam_zoom_in').mousehold(function(e, ctr){
      $omega_camera.zoom(-20);
      $omega_scene.animate();
    });

  }
}

/////////////////////////////////////// Omega Canvas Axis

/* Initialize new Omega Axis
 */
function OmegaAxis(){
  /////////////////////////////////////// private data
  var size = 250;

  var step = 100;

  var line_geometry = new THREE.Geometry();

  var line_material = new THREE.LineBasicMaterial( { color: 0xcccccc, opacity: 0.4 } );

  var showing_axis = false;

  var distance_geometries = [new THREE.TorusGeometry(3000, 5, 40, 40),
                             new THREE.TorusGeometry(2000, 5, 20, 20),
                             new THREE.TorusGeometry(1000, 5, 20, 20)];

  var distance_material = new THREE.MeshBasicMaterial({color: 0xcccccc });

  /////////////////////////////////////// public data

  // should be set to number of elements in distance_geometries
  this.num_markers = 3;

  /////////////////////////////////////// public methods

  /* Return boolean indicating if axis is showing
   */
  this.is_showing = function(){
    return showing_axis;
  }

  /* Show the Canvas Axis
   */
  this.show = function(){
    $omega_scene.add( axis_line );
    for(var marker in distance_markers){
      $omega_scene.add(distance_markers[marker]);
    }
    showing_axis = true;
  }

  /* Hide the Canvas Axis
   */
  this.hide = function(){
    for(var marker in distance_markers){
      $omega_scene.remove_obj(distance_markers[marker]);
    }
    $omega_scene.remove_obj(axis_line);
    showing_axis = false;
  }

  /* Toggle showing/hiding the canvas axis based
   * on checked attribute of the '#toggle_axis_canvas' input
   */
  this.toggle = function(){
    var toggle_axis = $('#toggle_axis_canvas');
    if(toggle_axis){
      if(toggle_axis.is(':checked'))
        this.show();
      else
        this.hide();
    }
    $omega_scene.animate();
  }

  /////////////////////////////////////// initialization

  // create line representing entire axis
  line_geometry.vertices.push( new THREE.Vector3( 0, 0, -4096 ) );
  line_geometry.vertices.push( new THREE.Vector3( 0, 0,  4096 ) );

  line_geometry.vertices.push( new THREE.Vector3( 0, -4096, 0 ) );
  line_geometry.vertices.push( new THREE.Vector3( 0,  4096, 0 ) );

  line_geometry.vertices.push( new THREE.Vector3( -4096, 0, 0 ) );
  line_geometry.vertices.push( new THREE.Vector3(  4096, 0, 0 ) );

  var axis_line = new THREE.Line( line_geometry, line_material, THREE.LinePieces );
  axis_line.omega_id = 'axis-line';

  var distance_markers = [];
  for(var geometry in distance_geometries){
    var mesh = new THREE.Mesh(distance_geometries[geometry], distance_material)
    mesh.position.x = 0;
    mesh.position.y = 0;
    mesh.position.z = 0;
    mesh.rotation.x = 1.57;
    mesh.omega_id = 'distance-marker-' + geometry
    distance_markers.push(mesh);
  }

  // wire up axis controls
  $('#toggle_axis_canvas').live('click', function(e){ $omega_axis.toggle(); });
  $('#toggle_axis_canvas').attr('checked', false);

}

/////////////////////////////////////// Omega Canvas Grid

/* Initialize new Omega Grid
 */
function OmegaGrid(){

  /////////////////////////////////////// private data
  var size = 1000;

  var step = 250;

  var geometry = new THREE.Geometry();

  var material = new THREE.LineBasicMaterial( { color: 0xcccccc, opacity: 0.4 } );

  var showing_grid = false;

  /////////////////////////////////////// public methods

  /* Return boolean indicating if grid is showing
   */
  this.is_showing = function(){
    return showing_grid;
  }


  /* Show the Canvas Grid
   */
  this.show = function(){
    $omega_scene.add( grid_line );
    showing_grid = true;
  }

  /* Hide the Canvas Grid
   */
  this.hide = function(){
    $omega_scene.remove_obj(grid_line);
    showing_grid = false;
  }

  /* Toggle showing/hiding the canvas grid based
   * on checked attribute of the '#toggle_grid_canvas' input
   */
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

  // create line representing entire grid

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
  grid_line.omega_id = 'grid-line';

  // wire up grid controls
  $('#toggle_grid_canvas').live('click', function(e){ $omega_grid.toggle(); });
  $('#toggle_grid_canvas').attr('checked', false);
}


/////////////////////////////////////// Omega Entity Container

/* Initialize new Omega Entity Container
 */
function OmegaEntityContainer(){

  /////////////////////////////////////// private data

  // if set will be called when entity container is closed
  var closed_callback  = null;

  var entity_container          = $('#omega_entity_container');

  var entity_container_contents = $('#entity_container_contents');

  /////////////////////////////////////// public methods

  /* Register callback to be called when container is closed
   */
  this.on_closed = function(callback){
    closed_callback = callback;
  }

  /* Show the entity details container with
   * the specified line items
   *
   * @param {Array<String>} items strings to add to entity container
   */
  this.show = function(items){
    this.hide(); // so as to unselect previous
    var text = "";
    for(var item in items)
      text += items[item];
    entity_container_contents.html(text);
    entity_container.show();
  }

  /* Append items to the entity details container
   *
   * @param {Array<String>} items strings to add to entity container
   */
  this.append = function(items){
    var text = "";
    for(var item in items)
      text += items[item];
    entity_container_contents.html(entity_container_contents.html() + text);
  }

  /* Hide the entity container, this calls the globally
   * registered $entity_container_callback method to
   * handle the entity 'unselection' event
   */
  this.hide = function(){
    entity_container.hide();
    if(closed_callback != null)
      closed_callback();
  }

  /////////////////////////////////////// initialization

  // lock entity container to its current position

  entity_container.css({
    position: 'absolute',
    top:     entity_container.position().top,
    right:   $(document).width() - entity_container.offset().left - entity_container.width(),
    display: 'none'
  });

  // wire up enitity container close button

  $('#entity_container_close').live('click', function(e){
    $omega_entity_container.hide();
  });

}

/////////////////////////////////////// Omega Entities Container

/* Initialize new Omega Entities Container
 */
function OmegaEntitiesContainer(){

  /////////////////////////////////////// private data

  var locations   =  {};

  var entities    =  {};

  /////////////////////////////////////// public methods

  // hide all containers
  this.hide_all = function(){
    $('.entities_container').hide();
    $('.canvas_button').hide();
  }

  // Add specified entity to the proper entities container
  this.add_to_entities_container = function(entity){
    if(entity.json_class == "Cosmos::Galaxy"){
      if(locations[entity.name] == null){
        locations[entity.name] = entity;
        $('#locations_list ul').prepend('<li name="'+entity.name+'" style="color: green; font-weight: bold;">'+entity.name+'</li>');
      }

      $('#locations_list').show();

    }else if(entity.json_class == "Cosmos::SolarSystem"){
      if(locations[entity.name] == null){
        locations[entity.name] = entity;
        $('#locations_list ul').append('<li name="'+entity.name+'" style="color: red; font-weight: bold;">'+entity.name+'</li>');
      }

      $('#locations_list').show();

    }else if(entity.json_class == "Manufactured::Ship"){
      if(entities[entity.id] == null){
        entities[entity.id] = entity;
        $('#entities_list ul').append('<li name="'+entity.id+'" style="color: green; font-weight: bold;">'+entity.id+'</li>');
      }

      $('#entities_list').show();

    }else if(entity.json_class == "Manufactured::Station"){
      if(entities[entity.id] == null){
        entities[entity.id] = entity;
        $('#entities_list ul').append('<li name="'+entity.id+'" style="color: blue; font-weight: bold;">'+entity.id+'</li>');
      }

      $('#entities_list').show();

    }else if(entity.json_class == "Missions::Mission"){
      $("#missions_button").show();
    }
  };

  // wire up various entities containers to their respective actions

  $('#locations_list li').live('click', function(event){ 
    var entity_id = $(event.currentTarget).attr('name');
    $omega_scene.set_root($omega_registry.get(entity_id));
  });

  $('#entities_list li').live('click', function(event){
    var entity_id = $(event.currentTarget).attr('name');
    var entity = $omega_registry.get(entity_id)
    var system = $omega_registry.get(entity.system_name);

    $omega_scene.set_root(system);
    $omega_camera.position({x : entity.location.x, y : entity.location.y, z : entity.location.z + 500});
    $omega_camera.focus({x : entity.location.x, y : entity.location.y, z : entity.location.z });
    $omega_scene.animate();
  });

  $('#missions_button').live('click', function(event){
    var missions = $omega_registry.select([function(e){ return e.json_class == "Missions::Mission"; }]);
    var missions_text = '';
    var assigned = null;
    for(var m in missions){
      var mission = missions[m];

      // TODO display 'completed' / 'failed' if mission expired, victorious, or failed
      if(!mission.expired()){
        if(mission.assigned_to_user() &&
          !mission.victorious && !mission.failed){
          assigned = mission;

        }else if(!mission.assigned_to_id){
          missions_text += mission.title;
          missions_text += "<a href=\"#\" id=\""+missions[m].id+"\" class=\"assign_mission\">assign</a>";
          missions_text += "<br/>";

        }
      }
    }
    if(assigned){
      $omega_dialog.show('Assigned mission', '',
                         '<b>' + assigned.title + '</b><br/>' +
                         assigned.description + '<br/><hr/>' +
                         'Accepted at: ' + assigned.assigned_time + '<br/>' +
                         'Expires at: ' + assigned.expires().toString());
    }else{
      $omega_dialog.show('Missions', '', missions_text);
    }
  });

  // XXX hack so entity always appears over canvas

  $('.entities_container').live('mouseenter', function(e){
    var container = $(e.currentTarget).attr('id');
    $('#' + container + ' ul').show();
    $("#omega_canvas").css('z-index', -1);
  });

  // hide entities container info
  $('.entities_container').live('mouseleave', function(e){
    var container = $(e.currentTarget).attr('id');
    $('#' + container + ' ul').hide();
    $("#omega_canvas").css('z-index', 0);
  });
}

/////////////////////////////////////// Omega Canvas Skybox

/* Initialize new Omega Skybox
 */
function OmegaSkybox(){

  /////////////////////////////////////// private data

  var skybox_bg  = null;

  var skyboxMesh = null;

  // to render skybox
  var texture_placeholder = document.createElement( 'canvas' );

  /////////////////////////////////////// private methods

  var loadTexture = function( path ) {

    var texture = new THREE.Texture( texture_placeholder );
    var material = new THREE.MeshBasicMaterial( { map: texture, overdraw: true } );

    var image = new Image();
    image.onload = function () {
      texture.needsUpdate = true;
      material.map.image = this;
      $omega_scene.animate();
    };
    image.src = path;
    return material;
  }

  /////////////////////////////////////// public methods

  /* Get the skybox background
   */
  this.get_background = function(){
    return skybox_bg;
  };

  /* Set the skybox background
   */
  this.set_background = function(entity){
    skybox_bg = entity.background;
    this.show();
  };

  /* Show the Skybox
   */
  this.show = function(){
    var path   = '/womega/images/skybox/'+skybox_bg+'/';
    var format = '.png';

    var materials = [
      loadTexture(path + 'px' + format),
      loadTexture(path + 'nx' + format),
      loadTexture(path + 'pz' + format),
      loadTexture(path + 'nz' + format),
      loadTexture(path + 'py' + format),
      loadTexture(path + 'ny' + format)
    ];

    this.hide();

    // build the skybox Mesh
    skyboxMesh = new THREE.Mesh( new THREE.CubeGeometry( 32768, 32768, 32768, 7, 7, 7, materials ),
                                 new THREE.MeshFaceMaterial( ) );
    //skyboxMesh.flipSided = true;
    skyboxMesh.scale.x = - 1;
    skyboxMesh.omega_id = 'skybox-mesh';

    // add it to the scene
    $omega_scene.add( skyboxMesh );
    $omega_scene.animate();
  };

  /** Hide the skybox
   */
  this.hide = function(){
    if(skyboxMesh != null){
      $omega_scene.remove_obj( skyboxMesh );
    }
  }

}

/////////////////////////////////////// Omega Canvas

/* Initialize new Omega Canvas
 */
function OmegaCanvas(){

  /////////////////////////////////////// public methods

  /* Hide the omega canvas
   */
  this.hide = function(){
    $('canvas').hide();
    $('.entities_container').hide();
    $('.canvas_button').hide();
    $('#camera_controls').hide();
    $('#axis_controls').hide();
    $('#close_canvas').hide();
    $('#show_canvas').show();
  };
  
  /* Show the omega canvas
   */
  this.show = function(){
    $('canvas').show();
    //$('.entities_container').show(); // TODO we need to individually show each of these
    //$('.canvas_button').show(); // TODO we need to individually show each of these
    $('#camera_controls').show();
    $('#axis_controls').show();
    $('#close_canvas').show();
    $('#show_canvas').hide();
  };

  /* Set canvas size
   */
  this.set_size = function(w, h){
    // resize to specified width/height
    $("#omega_canvas").height(h);
    $("#omega_canvas").width(w);
    $("#omega_canvas").trigger('resize');
  }

  /////////////////////////////////////// private methods

  /* Return coordiantes on canvas corresponding
   * to absolute screen coordinates.
   *
   * Pass x,y position of click event relative to screen/window
   */
  function canvas_click_coords(x,y){
    
    var nx = Math.floor(x-$("#omega_canvas").offset().left);
    var ny = Math.floor(y-$("#omega_canvas").offset().top);
    nx =   nx / $("#omega_canvas").width() * 2 - 1;
    ny = - ny / $("#omega_canvas").height() * 2 + 1;
    return [nx, ny];
  }

  /////////////////////////////////////// initialization

  // lock canvas to its current position
  $("#omega_canvas").css({
    position: 'absolute',
    top:  $("#omega_canvas").position().top,
    left: $("#omega_canvas").position().left
  });

  // make it resizable
  $("#omega_canvas").resizable();
  $("#omega_canvas").resize(function(e){
    var w = $("#omega_canvas").width();
    var h = $("#omega_canvas").height();
    $omega_camera.set_size(w, h);
    $omega_camera.reset();
    if(typeof $omega_scene !== "undefined"){
      $omega_scene.set_size(w, h);
      $omega_scene.animate();
    }
  });

  // wire up show/close canvas controls
  $('#close_canvas').live('click', function(event){ $omega_canvas.hide(); });
  $('#show_canvas').live( 'click', function(event){ $omega_canvas.show(); });

  // wire up canvas mouse controls

  // on canvas click, determine if an item in the scene was clicked,
  // and if so invoke clicked method on it
  $("#omega_canvas").live('click', function(e){
    var coords = canvas_click_coords(e.pageX, e.pageY);
    var x = coords[0]; var y = coords[1];
    var clicked_on_entity = false;

    var projector = new THREE.Projector();
    var ray = projector.pickingRay(new THREE.Vector3(x, y, 0.5), $omega_camera.scene_camera());
    var intersects = ray.intersectObjects($omega_scene.scene_objects());

    if(intersects.length > 0){
      var entities = $omega_scene.get_root().children();
      for(var entity in entities){
        entity = entities[entity];
        if(entity.clickable_obj == intersects[0].object){
          clicked_on_entity = true;
          entity.clicked();

          // XXX hack hide dialog
          if(typeof $omega_dialog !== "undefined") $omega_dialog.hide();

          break;
        }
      }
    }

    //if(!clicked_on_entity)
    //  controls.clicked_space(x, y);
  });

}

/////////////////////////////////////// Omega Canvas Select Box

/* Initialize new Omega Canvas Select Box
 */
function OmegaSelectBox(){
  /////////////////////////////////////// private methods

  // Display the canvas select box
  function show(args){
    $sb_dx = args.x;
    $sb_dy = args.y;
    $("#canvas_select_box").show();
  }

  // Hide the canvas select box
  function hide(args){
    var select_box = $("#canvas_select_box");
    select_box.css('left', 0);
    select_box.css('top',  0);
    select_box.css('min-width',  0);
    select_box.css('min-height', 0);
    select_box.hide();
  }

  // Update the canvas select box
  function update(args){
    var canvas = $("#omega_canvas");
    var select_box = $("#canvas_select_box");

    if(!select_box.is(":visible"))
      return;

    var tlx = select_box.css('left');
    var tly = select_box.css('top');
    var brx = select_box.css('left') + select_box.css('min-width');
    var bry = select_box.css('top')  + select_box.css('min-height');

    var downX = $sb_dx; var downY = $sb_dy;
    var currX = args.x; var currY = args.y;

    if(currX < downX){ tlx = currX; brx = downX; }
    else             { tlx = downX; brx = currX; }

    if(currY < downY){ tly = currY; bry = downY; }
    else             { tly = downY; bry = currY; }

    var width  = brx - tlx;
    var height = bry - tly;

    select_box.css('left', canvas.position().left + tlx);
    select_box.css('top',  canvas.position().top + tly);
    select_box.css('min-width',  width);
    select_box.css('min-height', height);
  }

  /////////////////////////////////////// initialization

  // wire up select box mouse controls

  $("#omega_canvas, #canvas_select_box").live('mousemove', function(e){
    var c = $('#omega_canvas');
    var x = e.pageX - c.offset().left;
    var y = e.pageY - c.offset().top;
    update({x : x, y : y});
  });

  $("#omega_canvas, #canvas_select_box").live('mousedown', function(e){
    var c = $('#omega_canvas');
    var x = e.pageX - c.offset().left;
    var y = e.pageY - c.offset().top;
    show({x : x, y : y});
  });

  $("#omega_canvas, #canvas_select_box").live('mouseup', function(e){
    hide();
  });
}

/////////////////////////////////////// Omega Canvas UI Container

/* Initialize new Canvas UI, high level wrapper around all canvas
 * components
 */
function OmegaCanvasUI(args){
  $omega_camera             = new OmegaCamera();
  $omega_axis               = new OmegaAxis();
  $omega_grid               = new OmegaGrid();
  $omega_skybox             = new OmegaSkybox();
  $omega_canvas             = new OmegaCanvas();
  $omega_entity_container   = new OmegaEntityContainer();
  $omega_entities_container = new OmegaEntitiesContainer();
  $omega_select_box         = new OmegaSelectBox();

  $omega_camera.reset();

  // set canvas to page size
  // TODO optionally load fixed size from config
  $omega_canvas.set_size(($(document).width()  - $("#omega_canvas").offset().left - 50),
                         ($(document).height() - $("#omega_canvas").offset().top  - 50));

  if(!args || !args.noresize){
    // capture page resize and resize canvas
    var resizing_window = false;
    $(window).resize(function(){
      if(resizing_window) return;
      resizing_window = true;
      $omega_canvas.set_size(($(document).width()  - $("#omega_canvas").offset().left - 50),
                             ($(document).height() - $("#omega_canvas").offset().top  - 50));
      resizing_window = false;
    });
  }

  // when entities are registered, add to entities container if appropriate
  $omega_registry.on_registration($omega_entities_container.add_to_entities_container);

  // retrieve entities owned by user and system / galaxies they are in
  $omega_session.on_session_validated(function(){
    OmegaQuery.entities_owned_by($user_id, function(entities){
      for(var entityI in entities){
        var entity = entities[entityI];
        OmegaSolarSystem.cached(entity.system_name, function(system){
          // XXX do not further process if request already issued, and are waiting on cach
          if(system != null){
            OmegaGalaxy.cached(system.galaxy_name);
          }
        });
      }
    });

    // retrieve missions
    OmegaQuery.all_missions();
  });

  // clean up canvas and controls on logout
  $omega_session.on_session_destroyed(function(){
    $omega_registry.delete_timer('planet_movement');
    $omega_scene.clear();
    $omega_skybox.hide();
    $omega_scene.animate();

    $omega_entities_container.hide_all();
    $omega_entity_container.hide();
    $omega_axis.hide();
    $omega_grid.hide();
  });
}
