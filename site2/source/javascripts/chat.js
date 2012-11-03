function send_message(message){
  var chat_input  = $('#chat_input input[type=text]');
  var chat_output = $('#chat_output textarea');
  omega_web_request('users::send_message', message, null);
  chat_output.append($user_id + ": " + message + "\n");
  chat_input.attr('value', '');
}

function subscribe_to_messages(user, error){
  if(error == null){
    var chat_output = $('#chat_output textarea');
    omega_ws_request('users::subscribe_to_messages', null);

    add_method_handler('users::on_message', function(msg){
      chat_output.append(msg.nick + ": " + msg.message + "\n");
    });
  }
}

$(document).ready(function(){ 
  // lock chat container to its current position
  $('#chat_container').css({
    position: 'absolute',
    top: $('#chat_container').position().top,
    left: $('#chat_container').position().left
  });

  var chat_input  = $('#chat_input input[type=text]');
  var chat_button = $('#chat_input input[type=button]');
  var chat_output = $('#chat_output textarea');

  chat_button.live('click', function(e){
    var message = chat_input.attr('value');
    send_message(message);
  });

  $validate_session_callbacks.push(subscribe_to_messages);
  $login_callbacks.push(subscribe_to_messages);
});
