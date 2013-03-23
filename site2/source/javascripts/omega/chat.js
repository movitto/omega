/* Omega Chat Operations
 *
 * Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

// since chat is loaded in a partial, we assume $omega_node
// and $omega_session have been initialized elsewhere
//require('javascripts/omega/client');
//require('javascripts/omega/user');

/////////////////////////////////////// Omega Chat Container

/* Initialize new Omega Chat Container
 */
function OmegaChatContainer(){

  /////////////////////////////////////// private data

  var showing = false;

  var chat_container = $('#chat_container');

  var chat_input     = $('#chat_input input[type=text]');

  var chat_button    = $('#chat_input input[type=button]');

  var chat_output    = $('#chat_output textarea');

  /////////////////////////////////////// private methods

  /* Send the specified message to the server
   *
   * @params {String} message message to send to the server
   */
  var send_message = function(message){
    $omega_node.web_request('users::send_message', message, null);
    chat_output.append($user_id + ": " + message + "\n");
    chat_input.attr('value', '');
  }

  /* Callback to subscribe to messages on login/session-validation
   */
  var subscribe_to_messages = function(){
    $omega_node.ws_request('users::subscribe_to_messages', null);

    $omega_node.add_request_handler('users::on_message', function(msg){
      chat_output.append(msg.nick + ": " + msg.message + "\n");
    });
  }

  /////////////////////////////////////// initialization

  // lock chat container to its current position & hide it
  chat_container.css({
    position: 'absolute',
    bottom:  chat_container.position().bottom,
    right: chat_container.position().right
  });
  chat_container.hide();

  // wire up chat toggle
  $("#toggle_chat").click(function(){
    if(showing){
      $("#toggle_chat").html("Chat");
      chat_container.hide();
      showing = false;
    }else{
      $("#toggle_chat").html("Hide Chat");
      chat_container.show();
      showing = true;
    }
  });

  // send messages on chat input
  chat_button.live('click', function(e){
    var message = chat_input.attr('value');
    send_message(message);
  });

  // subscribe to messages on session validation
  $omega_session.on_session_validated(function(){
    if(!$omega_user.is_anon()){
      $("#toggle_chat").show();
      subscribe_to_messages();
    }
  });

  $omega_session.on_session_destroyed(function(){
    $("#toggle_chat").hide();
  });
}
