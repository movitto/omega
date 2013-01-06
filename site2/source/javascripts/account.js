/* accounts page
 *
 * Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

// log all errors to the console
function errors_to_console(error_msg){
  console.log(error_msg);
}

// populate the manufactured entities box w/ entities retrieved from server
function populate_manufactured_entities(entities){
  for(var entityI in entities){
    var entity = entities[entityI];
    if(entity.json_class == "Manufactured::Ship"){
      $('#account_info_ships').append(entity.id + ' ');
    }else if(entity.json_class == "Manufactured::Station"){
      $('#account_info_stations').append(entity.id + ' ');
    }
  }
}

// on login / session validation, populate this page's info
function update_account_details(user){
  $current_user = user;
  $current_user.toJSON = function(){ return new JRObject("Users::User", $current_user, 
                                    ["toJSON", "json_class", "alliances"]).toJSON(); }; 

  //$('#account_info_last_login');
  $('#account_info_username input').attr('value', user.id);
  $('#account_info_email input').attr('value', user.email);

  // get entities owned by user
  omega_entities_owned_by(user.id, populate_manufactured_entities);
}

// initialize the page
$(document).ready(function(){ 
  $current_user = null;

  $omega_session.on_session_validated(update_account_details);
  $omega_node.add_error_handler(errors_to_console);

  // update account info when button clicked
  $('#account_info_update').live('click', function(e){
      var pass1 = $('#user_password').attr('value');
      var pass2 = $('#user_confirm_password').attr('value');
      if(pass1 != pass2){
        alert("passwords do not match");
        return;
      }

      $current_user.password = pass1;

      $omega_node.web_request('users::update_user', $current_user, function(u, e){
        if(e == null){
          alert("User " + u.id + " updated successfully");
        }
      });
  });
});
