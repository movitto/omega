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

  var _camera = new THREE.PerspectiveCamera(75, 900 / 400, 1, 10000 );
  //var camera = new THREE.OrthographicCamera(-500, 500, 500, -500, -1000, 1000);

  /////////////////////////////////////// public methods

  /* Set/get the camera position.
   *
   * Takes option position param to set camera position
   * before returning current camera position.
   */
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

  /* Zoom the Omega Camera the specified distance from its
   * current position. Camera currently always faces origin.
   */
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

  /* Rotate the camera using a spherical coordiante system.
   * Specify the number of theta and phi degrees to rotate
   * the camera from its current position
   */
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
  //     canvas_to_xy in tests/setup.js requires access to internal camera
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
    left:    entity_container.position().left,
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

  var alliances   =  {};

  var fleets      =  {};

  /////////////////////////////////////// public methods

  // Add specified entity to the proper entities container
  this.add_to_entities_container = function(entity){
    if(entity.json_class == "Cosmos::Galaxy" ||
       entity.json_class == "Cosmos::SolarSystem"){
      if(locations[entity.name] == null){
        locations[entity.name] = entity;
        $('#locations_list ul').append('<li name="'+entity.name+'">'+entity.name+'</li>');
      }

      $('#locations_list').show();

    }else if(entity.json_class == "Users::User"){
      for(var a in entity.alliances){
        var alliance = entity.alliances[a];
        if(alliances[alliance.id] == null){
          alliances[alliance.id] = alliance;
          $('#alliances_list ul').append('<li name="'+alliance.id+'">' + alliance.id + '</li>');
        }
      }

      if(entity.alliances.length > 0)
        $('#alliances_list').show();

    }else if(entity.json_class == "Manufactured::Fleet"){
      if(fleets[entity.id] == null){
        locations[entity.id] = entity;
        $('#fleets_list ul').append('<li name="'+entity.id+'">'+entity.id+'</li>');
      }

      $('#locations_list').show();

    }
  };

  // wire up various entities containers to their respective actions

  $('#locations_list li').live('click', function(event){ 
    var entity_id = $(event.currentTarget).attr('name');
    $omega_scene.set_root($omega_registry.get(entity_id));
  });

  $('#alliances_list li').live('click', function(event){
    // TODO
  });

  $('#fleets_list li').live('click', function(event){
    // TODO
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

    if(skyboxMesh != null){
      $omega_scene.remove( skyboxMesh );
    }

    // build the skybox Mesh
    skyboxMesh = new THREE.Mesh( new THREE.CubeGeometry( 8192, 8192, 8192, 7, 7, 7, materials ),
                                 new THREE.MeshFaceMaterial( ) );
    //skyboxMesh.flipSided = true;
    skyboxMesh.scale.x = - 1;

    // add it to the scene
    $omega_scene.add( skyboxMesh );
    $omega_scene.animate();
  };

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
    $('#camera_controls').hide();
    $('#grid_control').hide();
    $('#close_canvas').hide();
    $('#show_canvas').show();
  };
  
  /* Show the omega canvas
   */
  this.show = function(){
    $('canvas').show();
    //$('.entities_container').show(); // TODO we need to individually show each of these
    $('#camera_controls').show();
    $('#grid_control').show();
    $('#close_canvas').show();
    $('#show_canvas').hide();
  };

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
      var entities = $omega_scene.entities()
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
function OmegaCanvasUI(){
  $omega_camera             = new OmegaCamera();
  $omega_grid               = new OmegaGrid();
  $omega_skybox             = new OmegaSkybox();
  $omega_canvas             = new OmegaCanvas();
  $omega_entity_container   = new OmegaEntityContainer();
  $omega_entities_container = new OmegaEntitiesContainer();
  $omega_select_box         = new OmegaSelectBox();

  $omega_camera.position({z : 500});

  // when entities are registered, add to entities container if appropriate
  $omega_registry.on_registration($omega_entities_container.add_to_entities_container);

  // retrieve entities owned by user and system / galaxies they are in
  $omega_session.on_session_validated(function(){
    OmegaQuery.entities_owned_by($user_id, function(entities){
      for(var entityI in entities){
        var entity = entities[entityI];
        OmegaSolarSystem.cached(entity.system_name, function(system){
          OmegaQuery.galaxy_with_name(system.galaxy_name);
          OmegaQuery.entities_under(system.name);
        });
      }
    });
  });
}
