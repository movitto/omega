require("javascripts/omega/user.js");
require("javascripts/omega/chat.js");

$(document).ready(function(){

  //function before_all(details){
  //  on_session_validated(function(){ start(1); });
  //
  //  var user = new JRObject("Users::User", {id : 'mmorsi-omegaverse', password: 'isromm'});
  //  $omega_session.login_user(user);
  //  stop(1);
  //}
  
  //QUnit.moduleStart(before_all);
  //QUnit.testStart(before_each);
  //QUnit.testDone(after_each);
  //QUnit.moduleDone(after_all);
  
  module("omega_chat");
  
  asyncTest("send chat messages", 0, function() {
    $('#chat_input input[type=text]').attr('value', 'foo');
    $('#chat_input input[type=button]').trigger('click');
  });
  
  asyncTest("receive chat messages", 0, function() {
  });

});
