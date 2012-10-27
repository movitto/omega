function hide_canvas(){
  $('canvas').hide();
  $('.entities_container').hide();
  $('#camera_controls').hide();
  $('#grid_control').hide();
  $('#close_canvas').hide();
  $('#show_canvas').show();
};

function show_canvas(){
  $('canvas').show();
  $('.entities_container').show();
  $('#camera_controls').show();
  $('#grid_control').show();
  $('#close_canvas').show();
  $('#show_canvas').hide();
};

// pass x,y position of click event relative to screen/window
function canvas_click_coords(x,y){
  var canvas = $('#omega_canvas');
  var nx = Math.floor(x-canvas.offset().left);
  var ny = Math.floor(y-canvas.offset().top);
  nx = nx / canvas.width() * 2 - 1;
  ny = - ny / canvas.height() * 2 + 1;
  return [nx, ny];
}

function show_select_box(args){
  $sb_dx = args.x;
  $sb_dy = args.y;
  $("#canvas_select_box").show();
}

function hide_select_box(args){
  var select_box = $("#canvas_select_box");
  select_box.css('left', 0);
  select_box.css('top',  0);
  select_box.css('min-width',  0);
  select_box.css('min-height', 0);
  select_box.hide();
}

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

$(document).ready(function(){ 
  // lock canvas to its current position
  $('#omega_canvas').css({
    position: 'absolute',
    top: $('#omega_canvas').position().top,
    left: $('#omega_canvas').position().left
  });

  /////////////////////// show/close canvas controls

  $('#close_canvas').live('click', function(event){ hide_canvas(); });
  $('#show_canvas').live('click', function(event){ show_canvas(); });

  /////////////////////// grid controls

  // depends on the omega_renderer module
  $('#toggle_grid_canvas').live('click', function(e){ $grid.toggle(); });
  $('#toggle_grid_canvas').attr('checked', false);

  /////////////////////// camera controls
  
  if(jQuery.fn.mousehold){
  
    $('#cam_rotate_right').mousehold(function(e, ctr){
      $camera.rotate(0.0, 0.2);
    });
    
    $('#cam_rotate_left').mousehold(function(e, ctr){
      $camera.rotate(0.0, -0.2);
    });
    
    $('#cam_rotate_up').mousehold(function(e, ctr){
      $camera.rotate(-0.2, 0.0);
    });
    
    $('#cam_rotate_down').mousehold(function(e, ctr){
      $camera.rotate(0.2, 0.0);
    });
    
    $('#cam_zoom_out').mousehold(function(e, ctr){
      $camera.zoom(20);
    });
    
    $('#cam_zoom_in').mousehold(function(e, ctr){
      $camera.zoom(-20);
    });

  }

  /////////////////////// canvas mouse controls

  $("#omega_canvas").live('click', function(e){
    var coords = canvas_click_coords(e.pageX, e.pageY);
    var x = coords[0]; var y = coords[1];
    var clicked_on_entity = false;

    var projector = new THREE.Projector();
    var ray = projector.pickingRay(new THREE.Vector3(x, y, 0.5), $camera._camera);
    var intersects = ray.intersectObjects($scene._scene.__objects);

    if(intersects.length > 0){
      for(var loc in $scene.locations){
        loc = $scene.locations[loc];
        if(loc.scene_object == intersects[0].object){
          clicked_on_entity = true;
          //loc.clicked(e, loc.entity);
          break;
        }
      }
    }

    //if(!clicked_on_entity)
    //  controls.clicked_space(x, y);

    $scene.setup(); // appearances may have changed, redraw scene
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

  /////////////////////// entities container controls

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
