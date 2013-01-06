/* Omega Canvas Operations
 *
 * Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

/////////////////////////////////////// public methods

/* Show the entity details container with
 * the specified line items
 *
 * @param {Array<String>} items strings to add to entity container
 */
function show_entity_container(items){
  hide_entity_container(); // so as to unselect previous
  var text = "";
  for(var item in items)
    text += items[item];
  $('#entity_container_contents').html(text);
  $('#omega_entity_container').show();
}

/* Append items to the entity details container
 *
 * @param {Array<String>} items strings to add to entity container
 */
function append_to_entity_container(items){
  var text = "";
  for(var item in items)
    text += items[item];
  var container = $('#entity_container_contents');
  container.html(container.html() + text);
}

/* Hide the entity container, this calls the globally
 * registered $entity_container_callback method to
 * handle the entity 'unselection' event
 */
function hide_entity_container(){
  $('#omega_entity_container').hide();
  if($entity_container_callback != null)
    $entity_container_callback();
}

/* Register method to be invoked when canvas scene root is set
 */
function on_scene_change(callback){
  $scene_changed_callback = callback;
}

/////////////////////////////////////// private methods

/* Hide the omega canvas
 */
function hide_canvas(){
  $('canvas').hide();
  $('.entities_container').hide();
  $('#camera_controls').hide();
  $('#grid_control').hide();
  $('#close_canvas').hide();
  $('#show_canvas').show();
};

/* Show the omega canvas
 */
function show_canvas(){
  $('canvas').show();
  //$('.entities_container').show(); // TODO we need to individually show each of these
  $('#camera_controls').show();
  $('#grid_control').show();
  $('#close_canvas').show();
  $('#show_canvas').hide();
};

/* Set the root canvas entity
 */
function set_root_entity(entity_id){
  var entity = $tracker.entities[entity_id];
  hide_entity_container();
  $('#omega_canvas').css('background', 'url("/womega/images/backgrounds/' + entity.background + '.png") no-repeat');

  $omega_scene.clear();
  for(var child in entity.children){
    child = entity.children[child];
    $omega_scene.add_entity(child);
    if(child.added_to_scene)
      child.added_to_scene();
  }

  if($omega_scene_changed_callback)
    $omega_scene_changed_callback();

  $omega_scene.animate();
};


/* Return coordiantes on canvas corresponding
 * to absolute screen coordinates.
 *
 * Pass x,y position of click event relative to screen/window
 */
function canvas_click_coords(x,y){
  var canvas = $('#omega_canvas');
  var nx = Math.floor(x-canvas.offset().left);
  var ny = Math.floor(y-canvas.offset().top);
  nx = nx / canvas.width() * 2 - 1;
  ny = - ny / canvas.height() * 2 + 1;
  return [nx, ny];
}

// Display the canvas select box
function show_select_box(args){
  $sb_dx = args.x;
  $sb_dy = args.y;
  $("#canvas_select_box").show();
}

// Hide the canvas select box
function hide_select_box(args){
  var select_box = $("#canvas_select_box");
  select_box.css('left', 0);
  select_box.css('top',  0);
  select_box.css('min-width',  0);
  select_box.css('min-height', 0);
  select_box.hide();
}

// Update the canvas select box
function update_select_box(args){
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

$(document).ready(function(){ 
  $omega_scene_changed_callback = null;

  // lock canvas to its current position
  $('#omega_canvas').css({
    position: 'absolute',
    top: $('#omega_canvas').position().top,
    left: $('#omega_canvas').position().left
  });
  $('#omega_entity_container').css({
    position: 'absolute',
    top: $('#omega_entity_container').position().top,
    left: $('#omega_entity_container').position().left,
    display: 'none'
  });

  /////////////////////// show/close canvas controls

  $('#close_canvas').live('click', function(event){ hide_canvas(); });
  $('#show_canvas').live('click', function(event){ show_canvas(); });

  /////////////////////// entities containers controls

  // if a new system is registered, add to locations list
  on_entity_registration(function(entity){
    if(entity.json_class == "Cosmos::SolarSystem" && !entity.modified){
      $('#locations_list ul').append('<li name="'+entity.name+'">'+entity.name+'</li>');
      $('#locations_list').show();
    }
  });

  $('#locations_list li').live('click', function(event){ 
    var entity_id = $(event.currentTarget).attr('name');
    set_root_entity(entity_id);
  });

  /////////////////////// grid controls

  // depends on the omega_renderer module
  $('#toggle_grid_canvas').live('click', function(e){ $omega_grid.toggle(); });
  $('#toggle_grid_canvas').attr('checked', false);

  /////////////////////// camera controls
  
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

  /////////////////////// canvas mouse controls

  // on canvas click, determine if an item in the scene was clicked,
  // and if so invoke clicked method on it
  $("#omega_canvas").live('click', function(e){
    var coords = canvas_click_coords(e.pageX, e.pageY);
    var x = coords[0]; var y = coords[1];
    var clicked_on_entity = false;

    var projector = new THREE.Projector();
    var ray = projector.pickingRay(new THREE.Vector3(x, y, 0.5), $camera._camera);
    var intersects = ray.intersectObjects($omega_scene._scene.__objects);

    if(intersects.length > 0){
      for(var entity in $omega_scene.entities){
        entity = $omega_scene.entities[entity];
        if(entity.clickable_obj == intersects[0].object){
          clicked_on_entity = true;
          entity.clicked();
          break;
        }
      }
    }

    //if(!clicked_on_entity)
    //  controls.clicked_space(x, y);
  });

  $("#omega_canvas, #canvas_select_box").live('mousemove', function(e){
    var c = $('#omega_canvas');
    var x = e.pageX - c.offset().left;
    var y = e.pageY - c.offset().top;
    update_select_box({x : x, y : y});
  });

  $("#omega_canvas, #canvas_select_box").live('mousedown', function(e){
    var c = $('#omega_canvas');
    var x = e.pageX - c.offset().left;
    var y = e.pageY - c.offset().top;
    show_select_box({x : x, y : y});
  });

  $("#omega_canvas, #canvas_select_box").live('mouseup', function(e){
    hide_select_box();
  });

  /////////////////////// general entity container controls

  // if set will be called when entity container is closed
  $entity_container_callback = null;

  $('#entity_container_close').live('click', function(e){
    hide_entity_container();
  });

  $('.entities_container').live('mouseenter', function(e){
    var container = $(e.currentTarget).attr('id');
    $('#' + container + ' ul').show();
    $('#omega_canvas').css('z-index', -1);
  });
  
  // hide entities container info
  $('.entities_container').live('mouseleave', function(e){
    var container = $(e.currentTarget).attr('id');
    $('#' + container + ' ul').hide();
    $('#omega_canvas').css('z-index', 0);
  });
});
