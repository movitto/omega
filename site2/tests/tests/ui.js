require("javascripts/omega/user.js");
require("javascripts/omega/dialog.js");
require("javascripts/omega/navigation.js");
require("javascripts/omega/canvas.js");
require("javascripts/omega/commands.js");

$(document).ready(function(){

  module("omega_ui");
  
  ///////////////////////////// commands.js:
  
  asyncTest("select ship destination", 2, function() {
    login_test_user($admin_user, function(){
      OmegaQuery.entity_with_id('mmorsi-corvette-ship2', function(ship){
        OmegaCommand.move_ship.pre_exec(ship);
        var display = $('#omega_dialog').css('display');
        equal(display, 'block');
        ok($('#omega_dialog #dest_x') != null);
        start();
      });
    });
  });
  
  asyncTest("select ship target", 2, function() {
    login_test_user($admin_user, function(){
      OmegaQuery.entity_with_id('mmorsi-corvette-ship3', function(ship){
        OmegaCommand.launch_attack.pre_exec(ship);
        var display = $('#omega_dialog').css('display');
        equal(display, 'block');
        ok($('#omega_dialog .ship_launch_attack[value=opponent-mining-ship1]') != null);
        start();
      });
    });
  });
  
  asyncTest("select ship dock", 2, function() {
    login_test_user($admin_user, function(){
      OmegaQuery.entity_with_id('mmorsi-corvette-ship3', function(ship){
        OmegaCommand.dock_ship.pre_exec(ship);
        var display = $('#omega_dialog').css('display');
        equal(display, 'block');
        ok($('#omega_dialog .ship_dock[value=mmorsi-manufacturing-station1]') != null);
        start();
      });
    });
  });
  
  //asyncTest("select ship transfer", 2, function() {
  //});
  //
  //asyncTest("select ship mining", 2, function() {
  //});
  
  ///////////////////////////// canvas.js:
  
  test("show/hide/append to entity container", function() {
    var entity_container = new OmegaEntityContainer();
    entity_container.show();
    var display = $('#omega_entity_container').css('display');
    equal(display, 'block');
    entity_container.append(["foo", "bar"]);
    var value   = $('#entity_container_contents').html();
    equal(value, 'foobar');
    entity_container.append(["aaa", "bbb"]);
    value   = $('#entity_container_contents').html();
    equal(value, "foobaraaabbb");
    entity_container.hide();
    display = $('#omega_entity_container').css('display');
    equal(display, 'none');
  });
  
  //asyncTest("scene changed callback", 2, function() {
  //  // TODO
  //});
  
  ///////////////////////////// dialog.js:
  
  test("show/hide/append to dialog", function() {
    $omega_dialog.show('title', '#omega_dialog_content', '+some');
    var display = $('#omega_dialog').css('display');
    var value   = $('#omega_dialog').html();
    equal(display, 'block');
    equal(value, "content+some");
    $omega_dialog.append("evenmore");
    value   = $('#omega_dialog').html();
    equal(value, "content+someevenmore");
    $omega_dialog.hide();
    display = $('#omega_dialog').css('display');
    // FIXME this isn't working right
    //equal("none", display);
  });
  
  ///////////////////////////// nav.js:
  
  asyncTest("navigation controls", 10, function() {
    var navigation = new OmegaNavigationContainer();

    // TODO verify intial state of navigation
    //equal($('#login_link').css('display'),    'inline');
    //equal($('#register_link').css('display'), 'inline');
    //equal($('#logout_link').css('display'),   'none');
    //equal($('#account_link').css('display'),  'none');

    // verify clicking login link brings up dialog
    $('#login_link').click();
    equal($('#login_dialog').css('display'),   'block');

    // verify submitting login dialog changes nav
    $omega_session.on_session_validated(function(){
      equal($('#login_link').css('display'),     'none');
      equal($('#register_link').css('display'),  'none');
      equal($('#logout_link').css('display'),    'inline');
      equal($('#account_link').css('display'),   'inline');
      // TODO verify user is actually logged in

    $('#logout_link').click();
    });

    $('#omega_dialog #login_username').val('mmorsi');
    $('#omega_dialog #login_password').val('isromm');
    $('#login_button').click();
    equal($('#omega_dialog').parent().css('display'),   'none');

    // verify logout link changes nav
    $omega_session.on_session_destroyed(function(){
      equal($('#login_link').css('display'),    'inline');
      equal($('#register_link').css('display'), 'inline');
      equal($('#logout_link').css('display'),   'none');
      equal($('#account_link').css('display'),  'none');

      // TODO verify user is actually logged out
      start();
    });


    // TODO verify a failed login
  });
  
});
