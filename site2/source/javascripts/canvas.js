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

$(document).ready(function(){ 
  // lock canvas and container to its current position
  $('#omega_canvas_container').css({
    position: 'absolute',
    top: $('#omega_canvas_container').position().top,
    left: $('#omega_canvas_container').position().left
  });
  $('#omega_canvas_container canvas').css({
    position: 'absolute',
    top: $('#omega_canvas_container canvas').position().top,
    left: $('#omega_canvas_container canvas').position().left
  });

  $('#close_canvas').live('click', function(event){ hide_canvas(); });
  $('#show_canvas').live('click', function(event){ show_canvas(); });

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
  ////////////////////////////////////////////



  $('.entities_container').live('mouseenter', function(e){
    var container = $(e.currentTarget).attr('id');
    $('#' + container + ' ul').show();
  });
  
  // hide entities container info
  $('.entities_container').live('mouseleave', function(e){
    var container = $(e.currentTarget).attr('id');
    $('#' + container + ' ul').hide();
  });

});
