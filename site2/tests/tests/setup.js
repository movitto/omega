require("javascripts/omega/client.js");
require("javascripts/omega/user.js");
require("javascripts/omega/entity.js");

//////////////////////////////// helper methods

function login_test_user(user, on_login){
  $omega_session.on_session_validated(function(){
    $omega_session.clear_callbacks();
    on_login();
  });
  $omega_session.login_user(user);
}

function logout_test_user(on_logout){
  $omega_session.on_session_destroyed(function(){
    $omega_session.clear_callbacks();
    if(on_logout)
      on_logout();
  });
  $omega_session.logout_user();
}

function setup_canvas(){
  $omega_canvas = new OmegaCanvas();
  $omega_entity_container = new OmegaEntityContainer();
  var scene = new OmegaScene();
  return scene;
}
  

//////////////////////////////// test hooks

function before_all(details){
  $mmorsio_user = new JRObject("Users::User", {id : 'mmorsi-omegaverse', password: 'isromm'});
  $mmorsi_user = new JRObject("Users::User", {id : 'mmorsi', password: 'isromm'});
  $admin_user  = new JRObject("Users::User", {id : 'admin',  password: 'nimda'});
}

function before_each(details){
  $omega_node     = new OmegaClient();
  $omega_session  = new OmegaSession();
  $omega_registry = new OmegaRegistry();
  $omega_scene    = new OmegaScene();

  $omega_node.on_connection_established(function(){
    start();
  });
  stop();

}

function after_each(details){
  $omega_node.clear_handlers();
  $omega_session.clear_callbacks();
  $omega_registry.clear_callbacks();
  logout_test_user();
}

QUnit.moduleStart(before_all);
QUnit.testStart(before_each);
QUnit.testDone(after_each);
//QUnit.moduleDone(after_all);
