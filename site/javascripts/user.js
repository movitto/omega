function User(){
  this.id         = 'mmorsi';
  this.password   = 'foobar';
  this.session_id = '';

  this.toJSON = function(){ return new JRObject("Users::User", this).toJSON(); };
  this.create_session = function(session_id, client){
    this.session_id = session_id;
    client.web_node.headers['session_id'] = session_id;
    client.ws_node.headers['session_id']  = session_id;
  };
  this.destroy_session = function(){
    this.session_id = '';
    client.web_node.headers['session_id'] = '';
    client.ws_node.headers['session_id']  = '';
  }
};
