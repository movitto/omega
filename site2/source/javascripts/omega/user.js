/* Omega User Operations
 *
 * Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

/////////////////////////////////////// Omega User

function OmegaUser(args){
  /////////////////////////////////////// private data

  this.id                   = args.id;

  this.password             = args.password;

  this.email                = args.email;

  this.recaptcha_challenge  = args.recaptcha_challenge;

  this.recaptcha_response   = args.recaptcha_response;

  /////////////////////////////////////// public methods

  this.toJSON = function(){
    return new JRObject("Users::User", this).toJSON();
  };
}

/////////////////////////////////////// Omega Session

/* Initialize new Omega Session
 */
function OmegaSession(){

  /////////////////////////////////////// private data

  // invoked when session validation is successful (eg page refresh when user is logged in)
  var session_validated_callbacks = [];

  // invoked when session validation is not succesful
  var invalid_session_callbacks   = [];

  // invoked when session is destroyed
  var session_destroyed_callbacks = [];

  /////////////////////////////////////// private methods

  /* Initialize the user session
   */
  var create_session = function(session_id, user_id){
    // set session id on rjr nodes
    $omega_node.set_header('session_id', session_id)
    $omega_node.set_header('source_node', user_id);

    // set session cookies
    $.cookie('omega-session', session_id);
    $.cookie('omega-user',    user_id);

    $user_id = user_id;
  };

  /* Destroy the user session
   */
  var destroy_session = function(){
    // delete session cookies
    $.cookie('omega-session', null);
    $.cookie('omega-user',    null);
  };

  /* Callback invoked to verify user session
   */
  var callback_validate_session = function(user, error){
    var ret = true;
    if(error){
      destroy_session();
      ret = false;
      for(var i = 0; i < invalid_session_callbacks.length; i++){
        invalid_session_callbacks[i]();
      }
    }else{
      for(var i = 0; i < session_validated_callbacks.length; i++){
        session_validated_callbacks[i]();
      }
    }
    return ret;
  };

  /* Callback invoked on user login
   */
  var callback_login_user = function(session, error){
    if(error){
      destroy_session();
    }else{
      create_session(session.id, session.user_id);
      for(var i = 0; i < session_validated_callbacks.length; i++){
        session_validated_callbacks[i]();
      }
    }
  }

  /* Callback invoked on user logout
   */
  var callback_logout_user = function(result, error){
    destroy_session();
    for(var i = 0; i < session_destroyed_callbacks.length; i++){
      session_destroyed_callbacks[i]();
    }
  }

  /////////////////////////////////////// public methods

  this.on_session_validated = function(callback){
    session_validated_callbacks.push(callback);
  }

  /* Register function to be invoked when invalid session
   * is detected.
   */
  this.on_invalid_session = function(callback){
    invalid_session_callbacks.push(callback);
  }

  /* Register function to be invoked when session
   * is destroyed.
   */
  this.on_session_destroyed = function(callback){
    session_destroyed_callbacks.push(callback);
  }

  /* Login the user
   */
  this.login_user = function(user){
    $omega_node.web_request('users::login', user, callback_login_user);
  };

  /* Logout the user
   */
  this.logout_user = function(){
    var session_id = $.cookie('omega-session');
    $omega_node.web_request('users::logout', session_id, callback_logout_user);
  };

  /* Register the user
   */
  this.register_user = function(user, callback){
    $omega_node.web_request('users::register', user, callback);
  };

  /////////////////////////////////////// initialization

  // restore the session from cookies
  var user_id    = $.cookie('omega-user');
  var session_id = $.cookie('omega-session');
  if(user_id != null && session_id != null){
    create_session(session_id, user_id);
  }

  // validate the session
  if(user_id != null){
    // XXX hack, give socket time to open before running client
    setTimeout(function(){
      $omega_node.web_request('users::get_entity', 'with_id', user_id,
                              callback_validate_session);
    }, 1000);
  }
}

/////////////////////////////////////// initialization

$(document).ready(function(){
  $omega_session = new OmegaSession();
});
