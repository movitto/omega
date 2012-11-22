/* index page
 *
 * Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

// show login & registration errors in an alert box
function popup_login_errors(error_msg){
  if(error_msg['error']['class'] == 'Omega::DataNotFound' &&
     error_msg['error']['message'].slice(0,4) == "user")
       alert(error_msg['error']['message']);

  else if(error_msg['error']['class'] == 'ArgumentError' &&
          error_msg['error']['message'] == "invalid user")
       alert("invalid user credentials");
}

// log all errors to the console
function errors_to_console(error_msg){
  console.log(error_msg);
}

// initialize the page
$(document).ready(function(){ 
  add_error_handler(popup_login_errors);
  add_error_handler(errors_to_console);
});