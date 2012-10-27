function omega_web_request(){
  var args = Array.prototype.slice.call(arguments);
  var callback   = args.pop();
  var request = $web_node.invoke_request.apply(null, args);
  if(callback != null)
    $callbacks.push({'request' : request, 'callback' : callback});
};

function omega_ws_request(){
  var args = Array.prototype.slice.call(arguments);
  var callback   = args.pop();
  var request = $ws_node.invoke_request.apply(null, args);
  if(callback != null)
    $callbacks.push({'request' : request, 'callback' : callback});
};

function invoke_client_callbacks(jr_message){
  if(jr_message){
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

$(document).ready(function(){
  // TODO parameterize connection info
  $web_node = new WebNode('http://localhost/omega');
  $ws_node  = new WSNode('127.0.0.1', '8080');
  $ws_node.open();
  $callbacks = [];
  $error_handlers = [];

  $ws_node.message_received  = function(jr_msg) { invoke_client_callbacks(jr_msg); }
  $web_node.message_received = function(jr_msg) { invoke_client_callbacks(jr_msg); }
});
