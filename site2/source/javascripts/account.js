function errors_to_console(error_msg){
  console.log(error_msg);
}

function callback_got_manufactured_entities(entities, error){
  if(error == null){
    for(var entityI in entities){
      var entity = entities[entityI];
      if(entity.json_class == "Manufactured::Ship"){
        $('#account_info_ships').append(entity.id + ' ');
      }else if(entity.json_class == "Manufactured::Station"){
        $('#account_info_stations').append(entity.id + ' ');
      }
    }
  }
}

function update_account_details(user, error){
  if(error == null){
    $current_user = user;
    $current_user.toJSON = function(){ return new JRObject("Users::User", $current_user, 
                                      ["toJSON", "json_class", "alliances"]).toJSON(); }; 
            

    //$('#account_info_last_login');
    $('#account_info_username input').attr('value', user.id);
    $('#account_info_email input').attr('value', user.email);

    // get entities owned by user
    omega_web_request('manufactured::get_entities', 'owned_by', user.id, callback_got_manufactured_entities);
  }
}

$(document).ready(function(){ 
  $current_user = null;

  $validate_session_callbacks.push(update_account_details);

  $error_handlers.push(errors_to_console);

  $('#account_info_update').live('click', function(e){
      var pass1 = $('#user_password').attr('value');
      var pass2 = $('#user_confirm_password').attr('value');
      if(pass1 != pass2){
        alert("passwords do not match");
        return;
      }

      $current_user.password = pass1;

      omega_web_request('users::update_user', $current_user, function(u, e){
        if(e == null){
          alert("User " + u.id + " updated successfully");
        }
      });
  });
});
