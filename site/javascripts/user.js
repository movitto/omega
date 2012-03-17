function User(){
  this.id         = 'mmorsi';
  this.password   = 'foobar';
  this.session_id = '';

  this.toJSON = function(){ return new JRObject("Users::User", this).toJSON(); };
  this.create_session = function(session, client){
    this.session_id = session.id;
    client.web_node.headers['source_node']= session.user_id;
    client.ws_node.headers['source_node'] = session.user_id;
    client.web_node.headers['session_id'] = session.id;
    client.ws_node.headers['session_id']  = session.id;
  };
  this.destroy_session = function(){
    this.session_id = '';
    client.web_node.headers['source_node']= '';
    client.ws_node.headers['source_node'] = '';
    client.web_node.headers['session_id'] = '';
    client.ws_node.headers['session_id']  = '';
  }
};
