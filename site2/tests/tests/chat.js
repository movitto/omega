require("javascripts/omega/user.js");
require("javascripts/omega/chat.js");

$(document).ready(function(){

  module("omega_chat");
  
  asyncTest("send and received chat messages", 2, function() {
    var chat = new OmegaChatContainer();

    login_test_user($mmorsio_user, function(){
      $('#chat_input input[type=text]').attr('value', 'foo');
      $('#chat_input input[type=button]').trigger('click');

      var chat_output = $('#chat_output textarea').text();
      var chat_regex  = new RegExp("foo");
      ok(chat_regex.test(chat_output));

      $omega_node.web_request('users::get_messages', function(m){
        ok(m.indexOf('foo') != -1);
        start();
      });
    });

    // TODO would be nice to test receiving message sent by other user
  });

  // TODO test showing/hiding chat container, clicking/displaying chat button
  
});
