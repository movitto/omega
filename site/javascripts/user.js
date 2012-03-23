function User(){
  this.id         = null;
  this.email      = null;
  this.password   = null;
  this.session_id = '';

  this.toJSON = function(){ return new JRObject("Users::User", this).toJSON(); };
  this.create_session = function(session_id, user_id, client){
    // set session cookies
    $.cookie('omegaverse-session', session_id);
    $.cookie('omegaverse-user',    user_id);

    this.id = user_id;
    this.session_id = session_id;
    client.web_node.headers['source_node']= user_id;
    client.ws_node.headers['source_node'] = user_id;
    client.web_node.headers['session_id'] = session_id;
    client.ws_node.headers['session_id']  = session_id;
    if(handlers.onlogin) handlers.onlogin();
  };

  this.destroy_session = function(client){
    // delete session cookies
    $.cookie('omegaverse-session', null);
    $.cookie('omegaverse-user',    null);

    this.session_id = '';
    client.web_node.headers['source_node']= '';
    client.ws_node.headers['source_node'] = '';
    client.web_node.headers['session_id'] = '';
    client.ws_node.headers['session_id']  = '';
    if(handlers.onlogout) handlers.onlogout();
  }

  // restore session if possible
  this.restore_session = function(client){
    var saved_session = $.cookie('omegaverse-session');
    var saved_user    = $.cookie('omegaverse-user');
    if(saved_session && saved_user){
      this.create_session(saved_session, saved_user,client);
    }
  }
};
