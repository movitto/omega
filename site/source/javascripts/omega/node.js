/* RJR Javascript Endpoint
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require 'vendor/jquery.cookie'
//= require "vendor/rjr/json"
//= require "vendor/rjr/jrw"

/* Primary communication mechanism w/ omega server
 */
function Node(){
  $.extend(this, new EventTracker());

  var node         = this;
  this.rjr_web_node = new WebNode('http://'+$omega_config['host']+'/omega');
  this.rjr_ws_node  = new WSNode($omega_config['host'], '8080');

  // request/notification handlers
  this.handlers  = {};
  this.add_handler = function(method, handler){
    if(!this.handlers[method]) this.handlers[method] = [];
    this.handlers[method].push(handler);
  }
  this.clear_handlers = function(method){
    if(method)
      this.handlers[method] = [];
    else
      this.handlers = {};
  }

  // error handlers
  this.error_handlers = [];
  this.on_error = function(handler){
    this.error_handlers.push(handler);
  }
  this.clear_error_handlers = function(){
    this.error_handlers = [];
  }

  // handle requests/notifications received over websocket
  this.rjr_ws_node.message_received  = function(jr_msg) { 
    node.raise_event('msg_received', jr_msg);

    // ensure this is a request message
    if(jr_msg && jr_msg['rpc_method']){
      var handlers = node.handlers[jr_msg['rpc_method']];
      if(handlers != null){
        for(var i=0; i < handlers.length; i++){
          handlers[i].apply(null, jr_msg['params']);
        }
      }
    }
  }

  // client web node doesn't support incoming requests/notifications
  this.rjr_web_node.message_received  = function(jr_msg) { 
    node.raise_event('msg_received', jr_msg);
  }

  // catch errors and handle
  this.rjr_web_node.onerror = 
  this.rjr_ws_node.onerror  = 
    function(err){
      for(var eh in node.error_handlers)
        node.error_handlers[eh](err);
    }

  /* Invoke a json-rpc message on the omega server via a web socket request.
   *
   * Takes same parameters as WSNode::invoke
   */
   this.ws_request = function(){
     // automatically open ws socket connection on first request
     if(!this.rjr_ws_node.opened) this.rjr_ws_node.open();

     var msg = this.rjr_ws_node.invoke.apply(this.rjr_ws_node, arguments)
     this.raise_event('request',    msg);
     this.raise_event('ws_request', msg);
     return msg;
   }

  /* Invoke a json-rpc message on the omega server via a web request.
   *
   * Takes same parameters as WebNode::invoke
   */
   this.web_request = function(){
     var msg = this.rjr_web_node.invoke.apply(this.rjr_web_node, arguments)
     this.raise_event('request',     msg);
     this.raise_event('web_request', msg);
     return msg;
   }

  /* Set header of the rjr nodes.
   *
   * @param {String} header name of the header to set
   * @param {String} value value to set the header to
   */
  this.set_header = function(header, value){
    this.rjr_ws_node.headers[header]  = value;
    this.rjr_web_node.headers[header] = value;
  }

  return this;
}

/* Logged in user session
 */
function Session(args){
  this.id      = args['id'];
  this.user_id = args['user_id'];

  $.cookie('omega-session', this.id);
  $.cookie('omega-user',    this.user_id);

  /* set session headers on the node
   */
  this.set_headers_on = function(node){
    node.set_header('session_id',  this.id);
    node.set_header('source_node', this.user_id);
  }

  /* clear session headers on the node
   */
  this.clear_headers_on = function(node){
    node.set_header('session_id',  null);
    node.set_header('source_node', null);
  }

  /* validate the session, specify callback to be invoked w/ result
   */
  this.validate = function(node, callback){
    node.web_request('users::get_entity',
                     'with_id', this.user_id, callback);
  }

  /* destroy session
   */
  this.destroy = function(){
    $.cookie('omega-session', null);
    $.cookie('omega-user',    null);
  }

  return this;
}

Session.restore_from_cookie = function(){
  var user_id    = $.cookie('omega-user');
  var session_id = $.cookie('omega-session');

  if(user_id != null && session_id != null){
    Session.current_session = new Session({id : session_id, user_id : user_id});
    return Session.current_session;
  }
}

Session.login = function(user, node, cb){
  node.web_request('users::login', user, function(response){
    if(response.error){
    }else{
      Session.current_session = 
        new Session({id : response.result.id, user_id : response.result.user.id });
      Session.current_session.set_headers_on(node);
      if(cb)
        cb.apply(Session.current_session, [Session.current_session]);
    }
  });
}

Session.logout = function(node, cb){
  node.web_request('users::logout', Session.current_session.id, function(response){
    if(Session.current_session)
      Session.current_session.clear_headers_on(node)
    Session.current_session = null;
    if(cb) cb();
  });
}
