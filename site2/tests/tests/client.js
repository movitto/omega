require("javascripts/omega/user.js");
require("javascripts/omega/client.js");

$(document).ready(function(){

  // TODO test status icon, status set to 'loading' on requests

  module("omega_client");
  
  asyncTest("web_request", 3, function() {
    login_test_user($admin_user, function(){
      $omega_node.web_request('cosmos::get_entities', 'with_id', 'Zeus', function(res, err){
        equal(err, null);
        equal(res.json_class, 'Cosmos::Galaxy');
        equal(res.name, 'Zeus');
        start();
      });
    });
  });
  
  asyncTest("ws request", 3, function() {
    login_test_user($admin_user, function(){
      $omega_node.ws_request('cosmos::get_entities', 'with_id', 'Zeus', function(res, err){
        equal(err, null);
        equal(res.json_class, 'Cosmos::Galaxy');
        equal(res.name, 'Zeus');
        start();
      });
    });
  });
  
  asyncTest("global error handlers", 2, function() {
    var user = new JRObject("Users::User", {id : 'admin', password: 'invalid'});
    $omega_node.add_error_handler(function(msg){
      equal(msg['error']['message'], 'invalid user');
    });
    $omega_node.web_request('users::login', user, function(res, err){
      equal(err['message'], 'invalid user');
      start();
    });
  });
  
  asyncTest("method handlers", 3, function() {
    login_test_user($admin_user, function(){
      $omega_node.ws_request('motel::track_movement', 10, 5, null); // location 12 corresponds to a planet
      equal($omega_node.has_request_handler('motel::on_movement'), false)
      $omega_node.add_request_handler("motel::on_movement", function(location){
        equal(location.id, 10);
        $omega_node.ws_request('motel::remove_callbacks', 10, null);
        start();
      });
      equal($omega_node.has_request_handler('motel::on_movement'), true)
    });
  });

});
