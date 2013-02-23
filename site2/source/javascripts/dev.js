/* dev page
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

require('javascripts/omega/client.js');

// show login & registration errors in an alert box
function popup_login_errors(error_msg){
  if(error_msg['error']['class'] == 'Omega::DataNotFound' &&
     error_msg['error']['message'].slice(0,4) == "user")
       alert(error_msg['error']['message']);

  else if(error_msg['error']['class'] == 'ArgumentError' &&
          error_msg['error']['message'] == "invalid user")
       alert("invalid user credentials");
}

// log all errors to the console
function errors_to_console(error_msg){
  console.log(error_msg);
}

// initialize the page
$(document).ready(function(){ 
  $omega_node     = new OmegaClient();
  $omega_session  = new OmegaSession();
  $omega_registry = new OmegaRegistry();
  OmegaCommand.init();

  // dependency pulled in via canvas partial
  $omega_canvas_ui = new OmegaCanvasUI();

  // pulled in via renderer, used in a few modules
  $omega_scene  = new OmegaScene();

  // dependendency pulled in via site layout
  $omega_navigation = new OmegaNavigationContainer();

  $omega_node.add_error_handler(popup_login_errors);
  $omega_node.add_error_handler(errors_to_console);

  $omega_session.on_session_validated(function(){
    $("#omega_canvas").css('background', 'url("/womega/images/backgrounds/galaxy1.png") no-repeat');
    for(var i = 0; i < 50; i++){
      var sphere   = new THREE.Mesh($omega_scene.geometries['asteroid_container'],
                                    $omega_scene.materials['asteroid_container']);

      sphere.position.x = i*50;
      sphere.position.y = i*50;
      sphere.position.z = i*50;
      $omega_scene.add(sphere);
    }
    $omega_scene.animate();
  });
});
