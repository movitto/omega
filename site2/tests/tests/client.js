require("javascripts/omega/user.js");
require("javascripts/omega/client.js");

$(document).ready(function(){

  module("omega_client");
  
  asyncTest("web_request", 2, function() {
    var user = new JRObject("Users::User", {id : 'admin', password: 'nimda'});
    $omega_node.web_request('users::login', user, function(res, err){
      //ok('im awesome');
      equal(null, err);
      equal('Users::Session', res.json_class);
      start();
    });
  });
  
  asyncTest("ws request", 2, function() {
    var user = new JRObject("Users::User", {id : 'admin', password: 'nimda'});
    $omega_node.ws_request('users::login', user, function(res, err){
      equal(null, err);
      equal('Users::Session', res.json_class);
      start();
    });
  });
  
  asyncTest("global error handlers", 2, function() {
    var user = new JRObject("Users::User", {id : 'admin', password: 'invalid'});
    $omega_node.add_error_handler(function(msg){
      start();
      equal('invalid user', msg['error']['message']);
    });
    $omega_node.web_request('users::login', user, function(res, err){
      start();
      equal('invalid user', err['message']);
    });
  });
  
  asyncTest("method handlers", 1, function() {
    var user = new JRObject("Users::User", {id : 'admin', password: 'nimda'});
    $omega_node.ws_request('users::login', user, null);
    $omega_node.ws_request('motel::track_movement', 10, 5, null); // location 12 corresponds to a planet
    $omega_node.add_request_handler("motel::on_movement", function(location){
      equal(10, location.id);
      $omega_node.ws_request('motel::remove_callbacks', 10, null);
      start();
    });
  });

});
