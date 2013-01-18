require("javascripts/omega/user.js");
require("javascripts/omega/chat.js");

$(document).ready(function(){

  module("omega_chat");
  
  asyncTest("send chat messages", 0, function() {
    $('#chat_input input[type=text]').attr('value', 'foo');
    $('#chat_input input[type=button]').trigger('click');
  });
  
  asyncTest("receive chat messages", 0, function() {
  });

});
