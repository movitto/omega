/* Omega Chat Operations
 *
 * Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

/////////////////////////////////////// Omega Chat Container

/* Initialize new Omega Chat Container
 */
function OmegaChatContainer(){

  /////////////////////////////////////// private data

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

  // lock chat container to its current position
  chat_container.css({
    position: 'absolute',
    top:  chat_container.position().top,
    left: chat_container.position().left
  });


  // send messages on chat input
  chat_button.live('click', function(e){
    var message = chat_input.attr('value');
    send_message(message);
  });

  // subscribe to messages on session validation
  $omega_session.on_session_validated(subscribe_to_messages);
}

/////////////////////////////////////// initialization

$(document).ready(function(){
  /* initialize global chat container */
  $omega_chat = new OmegaChatContainer();
});
