/* Omega Javascript Client
 *
 * Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

require('javascripts/vendor/rjr/json.js');
require('javascripts/vendor/rjr/jrw.js');

/////////////////////////////////////// Omega Client

/* Initialiaze new Omega Client
 */
function OmegaClient(){

  /////////////////////////////////////// private data

  // connection established handlers
  var connection_established_handlers = [];

  // response message handlers
  var response_handlers = [];

  // request / notification message handlers
  var request_handlers  = [];

  // error message handler
  var error_handlers    = [];

  // RJR web node
  // FIXME parameterize connection info
  var rjr_web_node = new WebNode('http://localhost/omega');

  // RJR websocket node
  // TODO parameterize connection info
  var rjr_ws_node  = new WSNode('127.0.0.1', '8080');

  /////////////////////////////////////// initialization

  rjr_ws_node.onopen = function(){
    invoke_connection_established_handlers();
  }

  rjr_ws_node.message_received  = function(jr_msg) { 
    // will launch request/response message handlers depending
    // on contents of jsonrpc message
    invoke_request_handlers(jr_msg);
    invoke_response_handlers(jr_msg);
  }

  rjr_web_node.message_received = function(jr_msg) {
    invoke_response_handlers(jr_msg);
  }

  rjr_ws_node.open();

  /////////////////////////////////////// public methods

  /* Clear all handlers
   */
  this.clear_handlers = function(){
    connection_established_handlers = [];
    response_handlers               = [];
    request_handlers                = [];
    error_handlers                  = [];
  }

  /* Add a callback to be invoked on connection
   * being established
   *
   * XXX potential race condition if connection is opened before
   * callbacks can be registered
   */
  this.on_connection_established = function(handler){
    connection_established_handlers.push(handler);
  }


  /* Add a error handler
   */
  this.add_error_handler = function(handler){
    error_handlers.push(handler);
  }

  /* Register a function to be invoked when a request or notification
   * message is received via the web socket.
   *
   * @param {String} method name of method which to register handler for
   * @param {Callable} handler which to invoke when method request /
   *                   notification is received
   */
  this.add_request_handler = function(method, handler){
    if(request_handlers[method] == null)
      request_handlers[method] = [];
    request_handlers[method].push(handler);
  }

  /* Clear all registered request handlers.
   */
  this.clear_request_handlers = function(){
    request_handlers = [];
  }

  /* Invoke a json-rpc message on the omega server via a web request.
   * Takes list of arguments specifying the request the last of which
   * must be the callback method to invoke on receiving the request
   * response (or null to ignore responses).
   *
   * @param {String} method_name name of method to invoke
   * @param {Array<Object>} arguments args to specify to method
   * @param {Callable} callback function to invoke upon receiving
   *                   response with the result or error, or null
   */
  this.web_request = function(){
    var args     = Array.prototype.slice.call(arguments);
    var callback = args.pop();
    var request  = rjr_web_node.invoke_request.apply(null, args);
    if(callback != null)
      response_handlers.push({'request' : request, 'callback' : callback});
  }

  /* Invoke a json-rpc message on the omega server via a web socket request.
   * Takes list of arguments specifying the request the last of which
   * must be the callback method to invoke on receiving the request
   * response (or null to ignore responses).
   *
   * @param {String} method_name name of method to invoke
   * @param {Array<Object>} arguments args to specify to method
   * @param {Callable} callback function to invoke upon receiving
   *                   response with the result or error, or null
   */
  this.ws_request = function(){
    var args     = Array.prototype.slice.call(arguments);
    var callback = args.pop();
    var request  = rjr_ws_node.invoke_request.apply(null, args);
    if(callback != null)
      response_handlers.push({'request' : request, 'callback' : callback});
  }

  /* Set header of the rjr nodes.
   *
   * @param {String} header name of the header to set
   * @param {String} value value to set the header to
   */
  this.set_header = function(header, value){
    rjr_ws_node.headers[header]  = value;
    rjr_web_node.headers[header] = value;
  }

  /* Get specified header value
   *
   * @param {String} header name of the header to get
   */
  this.get_header = function(header){
    // since set_header will set header same on web and ws nodes,
    // just need to access one
    return rjr_ws_node.headers[header];
  }


  /////////////////////////////////////// private methods

  /* Invoke callbacks on connection established
   */
  var invoke_connection_established_handlers = function(){
    for(var i=0; i < connection_established_handlers.length; i++){
      connection_established_handlers[i]();
    }
  }

  /* Method registered w/ websocket::on_message to invoke
   * request and notification handlers that the client registered
   */
  var invoke_request_handlers = function(jr_message){
    // ensure this is a request message
    if(jr_message && jr_message['method']){
      var handlers = request_handlers[jr_message['method']];
      if(handlers != null){
        for(var i=0; i < handlers.length; i++){
          handlers[i].apply(null, jr_message['params']);
        }
      }
    }
  }
  
  /* Method registered w/ websocket::on_message and
   * webnode::on_message to invoke response handlers
   * that the client registered
   */
  var invoke_response_handlers = function(jr_message){
    // ensure this is a response message
    if(jr_message && !jr_message['method']){
      var id = jr_message['id'];
      var callback = null;
      for(var i=0; i < response_handlers.length; i++){
        if(response_handlers[i]['request']['id'] == id){
          callback = response_handlers.splice(i, 1)[0].callback;
          break;
        }
      }
      if(callback == null)
        return;
  
      if(typeof(jr_message['result']) !== "undefined"){
        callback(jr_message['result'], null);
      }else if(typeof(jr_message['error']) !== "undefined"){
        for(var i = 0; i < error_handlers.length; i++){
          error_handlers[i](jr_message);
        }
        callback(null, jr_message['error']);
      }
    }
  }
}
