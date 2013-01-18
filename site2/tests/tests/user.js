require("javascripts/omega/user.js");
require("javascripts/omega/client.js");

$(document).ready(function(){

  module("omega_user");
  
  asyncTest("user login and logout", 5, function() {
    $omega_session.on_session_validated(function(){
      var sc = $.cookie('omega-session');
      var hc = $omega_node.get_header('session_id');
      ok(sc != null);
      equal(hc, sc);
  
      var uc = $.cookie('omega-user');
      equal(uc, 'mmorsi');
      start();
    });
    $omega_session.on_session_destroyed(function(){
      var sc = $.cookie('omega-session');
      var uc = $.cookie('omega-user');
      equal(sc, null);
      equal(uc, null);
      start();
    });
    var user = new JRObject("Users::User", {id : 'mmorsi', password: 'isromm'});
    $omega_session.login_user(user);
    stop();
    $omega_session.logout_user();
  });

});
