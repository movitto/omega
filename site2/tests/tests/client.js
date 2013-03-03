require("javascripts/omega/user.js");
require("javascripts/omega/client.js");

$(document).ready(function(){

  module("omega_status");

  test("push/pop state", function(){
    var os = new OmegaStatus();
    ok(!os.has_state('loading'));
    ok(!os.is_state('loading'));
    ok(!os.has_state('foobar'));
    ok(!os.is_state('foobar'));

    os.push_state('loading');
    equal($('#status_icon').css('background-image'), 'url("http://localhost/womega/images/status/loading.png")');
    ok(os.has_state('loading'));
    ok(os.is_state('loading'));
    ok(!os.has_state('foobar'));
    ok(!os.is_state('foobar'));

    os.push_state('foobar');
    equal($('#status_icon').css('background-image'), 'url("http://localhost/womega/images/status/foobar.png")');
    ok(os.has_state('loading'));
    ok(!os.is_state('loading'));
    ok(os.has_state('foobar'));
    ok(os.is_state('foobar'));

    os.pop_state();
    equal($('#status_icon').css('background-image'), 'url("http://localhost/womega/images/status/loading.png")');
    ok(os.has_state('loading'));
    ok(os.is_state('loading'));
    ok(!os.has_state('foobar'));
    ok(!os.is_state('foobar'));

    os.pop_state();
    equal($('#status_icon').css('background-image'), 'none');
    ok(!os.has_state('loading'));
    ok(!os.is_state('loading'));
    ok(!os.has_state('foobar'));
    ok(!os.is_state('foobar'));
  });

  test("provide singleton access", function(){
    equal(OmegaStatus.instance(), OmegaStatus.instance());
  });

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

  asyncTest("should set loading state when issuing remote requests", 5, function(){
    login_test_user($admin_user, function(){
      ok(!OmegaStatus.instance().has_state('loading'));
      var first   = true;
      var handler = function(res, err){
        ok(!OmegaStatus.instance().has_state('loading'));
        if(first){
          first = false;
          $omega_node.web_request('cosmos::get_entities', 'with_id', 'Zeus', handler);
          ok(OmegaStatus.instance().has_state('loading'));
        }else{
          start();
        }
      }

      $omega_node.ws_request('cosmos::get_entities', 'with_id', 'Zeus', handler);
      ok(OmegaStatus.instance().has_state('loading'));
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
  
  asyncTest("method handlers", function() {
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
