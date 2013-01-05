/* Omega Chat Operations
 *
 * Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

/////////////////////////////////////// public methods

/* Send the specified message to the server
 *
 * @params {String} message message to send to the server
 */
function send_message(message){
  var chat_input  = $('#chat_input input[type=text]');
  var chat_output = $('#chat_output textarea');
  $omega_node.web_request('users::send_message', message, null);
  chat_output.append($user_id + ": " + message + "\n");
  chat_input.attr('value', '');
}

/////////////////////////////////////// private methods

/* Callback to subscribe to messages on login/session-validation
 */
function subscribe_to_messages(){
  var chat_output = $('#chat_output textarea');
  $omega_node.ws_request('users::subscribe_to_messages', null);

  $omega_node.add_request_handler('users::on_message', function(msg){
    chat_output.append(msg.nick + ": " + msg.message + "\n");
  });
}

/////////////////////////////////////// initialization

$(document).ready(function(){ 
  // lock chat container to its current position
  $('#chat_container').css({
    position: 'absolute',
    top:  $('#chat_container').position().top,
    left: $('#chat_container').position().left
  });

  var chat_input  = $('#chat_input input[type=text]');
  var chat_button = $('#chat_input input[type=button]');
  var chat_output = $('#chat_output textarea');

  // send messages on chat input
  chat_button.live('click', function(e){
    var message = chat_input.attr('value');
    send_message(message);
  });

  // subscribe to messages on session validation
  on_session_validated(subscribe_to_messages);
});
