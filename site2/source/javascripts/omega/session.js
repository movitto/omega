/* Omega Session JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.Session = function(parameters){
  this.id = null;
  this.user_id = null;
  $.extend(this, parameters);
};

Omega.Session.prototype = {
  constructor : Omega.Session,

  /* Set the session browser cookies
   */
  set_cookies : function(){
    $.cookie('omega-session', this.id);
    $.cookie('omega-user',    this.user_id);
  },

  /* Clear the session browser cookies
   */
  clear_cookies : function(){
    $.cookie('omega-session', null);
    $.cookie('omega-user',    null);
  },

  /* Set session headers on the specified node
   */
  set_headers_on : function(node){
    node.set_header('session_id',  this.id);
    node.set_header('source_node', this.user_id);
  },

  /* Clear session headers on the specified node
   */
  clear_headers_on : function(node){
    node.set_header('session_id',  null);
    node.set_header('source_node', null);
  },

  /* Validate session using node to send request to server
   *
   * Callback will be invoked with request result upon response
   */
  validate : function(node, cb){
    node.http_invoke('users::get_entity', 'with_id', this.user_id, cb);
  },

  logout : function(node, cb){
    var _this = this;
    node.http_invoke('users::logout', this.id, function(response){
      _this.clear_cookies();
      _this.clear_headers_on(node)
      if(cb) cb();
      _this.dispatchEvent({type: 'logout', data: _this});
    });
  }
};

Omega.Session.restore_from_cookie = function(){
  var user_id    = $.cookie('omega-user');
  var session_id = $.cookie('omega-session');

  var session = null;
  if(user_id != null && session_id != null)
    session = new Omega.Session({id : session_id, user_id : user_id});

  return session;
};

Omega.Session.login = function(user, node, cb){
  node.http_invoke('users::login', user, function(response){
    if(response.error){
      if(cb) cb.apply(null, [response]);

    }else{
      var session = new Omega.Session({id      : response.result.id,
                                       user_id : response.result.user.id });
        
      session.set_headers_on(node);
      if(cb) cb.apply(null, [session]);
      Omega.Session.dispatchEvent({type: 'login', data: session})
    }
  });
};

THREE.EventDispatcher.prototype.apply( Omega.Session );
THREE.EventDispatcher.prototype.apply( Omega.Session.prototype );
