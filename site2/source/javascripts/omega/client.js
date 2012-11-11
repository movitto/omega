/* Omega Javascript Client
 *
 * Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

/////////////////////////////////////// global vars

  // response message handles
  $callbacks             = [];

  // global error handlers
  $error_handlers        = [];

  // request / notification message handlers
  $method_handlers       = [];

/////////////////////////////////////// public methods

/* Add a global error handler
 */
function add_error_handler(handler){
  $error_handlers.push(handler);
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
function omega_web_request(){
  var args = Array.prototype.slice.call(arguments);
  var callback   = args.pop();
  var request = $web_node.invoke_request.apply(null, args);
  if(callback != null)
    $callbacks.push({'request' : request, 'callback' : callback});
};

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
function omega_ws_request(){
  var args = Array.prototype.slice.call(arguments);
  var callback   = args.pop();
  var request = $ws_node.invoke_request.apply(null, args);
  if(callback != null)
    $callbacks.push({'request' : request, 'callback' : callback});
};

/* Register a function to be invoked when a request or notification
 * message is received via the web socket.
 *
 * @param {String} method name of method which to register handler for
 * @param {Callable} handler which to invoke when method request /
 *                   notification is received
 */
function add_method_handler(method, handler){
  if($method_handlers[method] == null)
    $method_handlers[method] = [];
  $method_handlers[method].push(handler);
}

/* Clear all registered method handlers.
 */
function clear_method_handlers(){
  $method_handlers = [];
}

/////////////////////////////////////// private methods

/* Method registered w/ websocket::on_message to invoke
 * request and notification  handlers that the client registered
 */
function invoke_method_handlers(jr_message){
  // ensure this is a request message
  if(jr_message && jr_message['method']){
    var handlers = $method_handlers[jr_message['method']];
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
function invoke_client_callbacks(jr_message){
  // ensure this is a response message
  if(jr_message && !jr_message['method']){
    var id = jr_message['id'];
    var callback = null;
    for(var i=0; i < $callbacks.length; i++){
      if($callbacks[i]['request']['id'] == id){
        callback = $callbacks.splice(i, 1)[0].callback;
        break;
      }
    }
    if(callback == null)
      return;

    if(jr_message['result']){
      callback(jr_message['result'], null);
    }else if(jr_message['error']){
      for(var i = 0; i < $error_handlers.length; i++){
        $error_handlers[i](jr_message);
      }
      callback(null, jr_message['error']);
    }
  }
}

/////////////////////////////////////// initialization

$(document).ready(function(){
  /* initialize rjr web and websocket nodes
   * TODO parameterize connection info
   */
  $web_node = new WebNode('http://localhost/omega');
  $ws_node  = new WSNode('127.0.0.1', '8080');

  // open the websocket connection
  $ws_node.open();

  /* register methods to invoke when web and websocke nodes
   * receive messages
   */
  $ws_node.message_received  = function(jr_msg) { 
    // will launch request/response message handlers depending
    // on contents of jsonrpc message
    invoke_method_handlers(jr_msg);
    invoke_client_callbacks(jr_msg);
  }
  $web_node.message_received = function(jr_msg) { invoke_client_callbacks(jr_msg); }
});
