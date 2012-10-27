function User(arg){
  this.id = arg.id;
  this.password = arg.password;
  this.email = arg.email;
  this.recaptcha_challenge = arg.recaptcha_challenge;
  this.recaptcha_response = arg.recaptcha_response;
  this.toJSON = function(){ return new JRObject("Users::User", this).toJSON(); };
};

function create_session(session_id, user_id){
  // set session id on rjr nodes
  $web_node.headers['session_id'] = session_id;
  $ws_node.headers['session_id']  = session_id;
  $web_node.headers['source_node']= user_id;
  $ws_node.headers['source_node'] = user_id;

  // set session cookies
  $.cookie('omega-session', session_id);
  $.cookie('omega-user',    user_id);
};

function destroy_session(){
  // delete session cookies
  $.cookie('omega-session', null);
  $.cookie('omega-user',    null);
};

function callback_validate_session(user, error){
  var ret = true;
  if(error){
    destroy_session();
    ret = false;
  }
  for(var i = 0; i < $validate_session_callbacks.length; i++){
    $validate_session_callbacks[i](user, error);
  }
  return ret;
};

function callback_login_user(session, error){
  if(error){
    destroy_session();
  }else{
    create_session(session.id, session.user_id);
    for(var i = 0; i < $login_callbacks.length; i++){
      $login_callbacks[i](session, error);
    }
  }
}

function login_user(user){
  omega_web_request('users::login', user, callback_login_user)
};

function logout_user(){
  // TODO issue users::logout
  var session_id = $.cookie('omega-session');
  omega_web_request('users::logout', session_id, null);
};

function register_user(user, callback){
  omega_web_request('users::register', user, callback);
}

$(document).ready(function(){ 
  // setup callbacks
  $validate_session_callbacks = [];
  $login_callbacks = [];
  $logout_callback = [];

  // restore the session
  var user_id    = $.cookie('omega-user');
  var session_id = $.cookie('omega-session');
  if(user_id != null && session_id != null){
    create_session(session_id, user_id);
  }

  // validate the session
  if(user_id != null){
    omega_web_request('users::get_entity', 'with_id', user_id, callback_validate_session);
  }
});
