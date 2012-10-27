function popup_login_errors(error_msg){
  if(error_msg['error']['class'] == 'Omega::DataNotFound' &&
     error_msg['error']['message'].slice(0,4) == "user")
       alert(error_msg['error']['message']);

  else if(error_msg['error']['class'] == 'ArgumentError' &&
          error_msg['error']['message'] == "invalid user")
       alert("invalid user credentials");
}

function errors_to_console(error_msg){
  console.log(error_msg);
}

$(document).ready(function(){ 
  $error_handlers.push(popup_login_errors);
  $error_handlers.push(errors_to_console);
});
