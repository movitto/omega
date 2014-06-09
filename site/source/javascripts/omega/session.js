/* Omega Session JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "vendor/jquery.cookie"

Omega.Session = function(parameters){
  this.id = null;
  this.user_id = null;
  $.extend(this, parameters);
};

/// Flag toggling cookies globally
Omega.Session.cookies_enabled = true;

Omega.Session.prototype = {
  constructor : Omega.Session,

  /* Set the session browser cookies
   */
  set_cookies : function(){
    if(Omega.Session.cookies_enabled){
      $.cookie('omega-session', this.id);
      $.cookie('omega-user',    this.user_id);
    }
  },

  /* Clear the session browser cookies
   */
  clear_cookies : function(){
    if(Omega.Session.cookies_enabled){
      $.removeCookie('omega-session');
      $.removeCookie('omega-user');
    }
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
    this.set_headers_on(node);
    node.http_invoke('users::get_entity', 'with_id', this.user_id, cb);
  },

  /// Logout from existing session
  ///
  /// Callback will be invoked on logout
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

/// Instantiate / return a session object from the local browser cookie
///
/// If cookies are disabled or session cookies are not present
/// null will be returned.
Omega.Session.restore_from_cookie = function(){
  var user_id = null, session_id = null;
  if(Omega.Session.cookies_enabled){
    user_id    = $.cookie('omega-user');
    session_id = $.cookie('omega-session');
  }

  var session = null;
  if(user_id != null && session_id != null)
    session = new Omega.Session({id : session_id, user_id : user_id});

  return session;
};

/// Create a new Session instance and log the specified user in
///
/// On response from the server, the callback will be invoked
/// with the newly established session or error if there was
/// one.
Omega.Session.login = function(user, node, cb){
  /// upon session creation, server will store the source node / endpoint
  /// which the session is established on, need to set that now
  var session = new Omega.Session({user_id : user.id});
  session.set_headers_on(node);

  node.http_invoke('users::login', user, function(response){
    if(response.error){
      if(cb) cb.apply(null, [response]);

    }else{
      var session = new Omega.Session({id      : response.result.id,
                                       user_id : response.result.user.id });

      session.set_cookies();
      session.set_headers_on(node);
      if(cb) cb.apply(null, [session]);
      Omega.Session.dispatchEvent({type: 'login', data: session})
    }
  });
};

THREE.EventDispatcher.prototype.apply( Omega.Session );
THREE.EventDispatcher.prototype.apply( Omega.Session.prototype );
