/* JSON-RPC over HTTP and WebSockets
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 * Licensed under the Apache License, Version 2.0
 */

var RJR = { REVISION: '1' };

// Generate a new ascii string of length 4
RJR.S4 = function() {
  return (((1+Math.random())*0x10000)|0).toString(16).substring(1);
};

// Generate a new uuid
RJR.guid = function() {
  return (RJR.S4()+RJR.S4()+"-"+RJR.S4()+"-"+RJR.S4()+"-"+RJR.S4()+"-"+RJR.S4()+RJR.S4()+RJR.S4());
};

// Return bool indicating if specified data is a jsonrpc object
RJR.is_jr_object = function(obj){
  return obj && obj['json_class'];
}

// Return bool indicating if specified data is an array
RJR.is_array = function(obj){
  return obj && typeof(obj) == 'object' && obj.length != undefined;
}

// Encapsulates a json-rpc message
RJR.JRMessage = function(){
  // standard jsonrpc message fields
  this.id         = null;
  this.rpc_method = null;
  this.params     =   [];
  this.error      = null;
  this.result     = null;

  // extra data used locally
  this.onresponse = null;
  this.headers    =   {};
};

RJR.JRMessage.prototype = {
  // Convert message to json string
  to_json : function(){
    var params = RJR.JRMessage.convert_params(this.params);
    var msg = {jsonrpc: '2.0',
               method:  this.rpc_method,
               params:  params,
               id:      this.id};
    for(var h in this.headers)
      msg[h] = this.headers[h];
    return $.toJSON(msg);
  },

  // Invoke response handler if registered
  handle_response : function(res){
    if(this.onresponse) this.onresponse(res);
  }
};

// Convert js params to json params
RJR.JRMessage.convert_params = function(params){
  var jrparams = [];
  for(var p = 0; p < params.length; p++){
    var param = params[p];
    if(RJR.is_jr_object(param)){
      jrparams.push(RJR.JRMessage.convert_obj_to_jr_obj(param));
    }else if(RJR.is_array(param)){
      /// TODO s/convert_params/convert_array_to_jr_array here ?
      /// (or could the whole convert_params method could be
      ///  consolidated with that one ?)
      jrparams.push(RJR.JRMessage.convert_params(param));
    }else
      jrparams.push(param);
  }
  return jrparams;
}

// Convert single json object to jr object
RJR.JRMessage.convert_obj_to_jr_obj= function(obj){
  var jr_obj = $.extend(true, {}, obj)
  var json_class = jr_obj['json_class'];
  delete jr_obj['json_class'];

  /// iterate over object properties
  for(var p in jr_obj){
    if(RJR.is_jr_object(jr_obj[p]))
      jr_obj[p] = RJR.JRMessage.convert_obj_to_jr_obj(jr_obj[p]);
    else if(RJR.is_array(jr_obj[p]))
      jr_obj[p] = RJR.JRMessage.convert_array_to_jr_array(jr_obj[p]);
  }

  return {json_class: json_class,
          data      :    jr_obj};
}

// Convert single json object from jr object
RJR.JRMessage.convert_obj_from_jr_obj = function(jr_obj){
  var obj = $.extend(true, {}, jr_obj)
  if(obj.data){
    $.extend(obj, obj.data);
    delete obj['data'];
  }

  for(var p in obj){
    if(RJR.is_jr_object(obj[p]))
      obj[p] = RJR.JRMessage.convert_obj_from_jr_obj(obj[p]);
    else if(RJR.is_array(obj[p]))
      obj[p] = RJR.JRMessage.convert_array_from_jr_array(obj[p]);
  }

  return obj;
}

// Recursively convert array to jr object array
RJR.JRMessage.convert_array_to_jr_array = function(array){
  var jr_array = $.extend(true, [], array)
  for(var a = 0; a < jr_array.length; a++){
    if(RJR.is_jr_object(jr_array[a]))
      jr_array[a] = RJR.JRMessage.convert_obj_to_jr_obj(jr_array[a]);
    else if(RJR.is_array(jr_array[a]))
      jr_array[a] = RJR.JRMesage.convert_array_to_jr_array(jr_array[a]);
  }

  return jr_array;
}

// Convert json object array from jr object array
RJR.JRMessage.convert_array_from_jr_array = function(jr_array){
  var array = $.extend(true, [], jr_array)
  for(var a = 0; a < array.length; a++){
    if(RJR.is_jr_object(array[a]))
      array[a] = RJR.JRMessage.convert_obj_from_jr_obj(array[a]);
    else if(RJR.is_array(jr_array[a]))
      array[a] = RJR.JRMessage.convert_array_from_jr_array(array[a]);
  }

  return array;
}

// Parse a json string to a JRMessage
RJR.JRMessage.parse = function(json){
  var data = $.evalJSON(json);

  var msg        = new RJR.JRMessage();
  msg.id         = data['id'];
  msg.rpc_method = data['method'];
  msg.error      = data['error'];

  var params = data['params'];
  if(params){
    for(var d=0; d<params.length; d++){
      var param = params[d];
      if(RJR.is_jr_object(param))
        msg.params.push(RJR.JRMessage.parse_obj(param));
      else if(RJR.is_array(param))
        msg.params.push(RJR.JRMessage.parse_array(param));
      else
        msg.params.push(param);
    }
  }

  var result = data['result'];
  if(result){
    if(RJR.is_jr_object(result))
      msg.result = RJR.JRMessage.parse_obj(result);
    else if(RJR.is_array(result))
      msg.result = RJR.JRMessage.parse_array(result);
    else
      msg.result = result;
  }

  return msg;
};

// Parse a json object into a js object
RJR.JRMessage.parse_obj = function(obj){
  // TODO mechanism to lookup class and auto
  // instantiate instead of generic js object
  var result = {json_class : obj['json_class']};
  for(var p in obj['data']){
    var property = obj['data'][p];
    if(RJR.is_jr_object(property))
      result[p] = RJR.JRMessage.parse_obj(property);
    else if(RJR.is_array(obj[p]))
      result[p] = RJR.JRMessage.parse_array(property);
    else
      result[p] = property;
  }
  return result;
}

// Parse an array, potentially containing json data,
// into a js array
RJR.JRMessage.parse_array = function(array){
  var result = [];
  for(var a=0; a<array.length; a++){
    var item = array[a];
    if(RJR.is_jr_object(item))
      result.push(RJR.JRMessage.parse_obj(item));
    else if(RJR.is_array(item))
      result.push(RJR.JRMessage.parse_array(item));
    else
      result.push(item);
  }
  return result;
}

// Create new request message to send
RJR.JRMessage.new_request = function(rpc_method, params){
  var msg        = new RJR.JRMessage();
  msg.id         = RJR.guid();
  msg.rpc_method = rpc_method;
  msg.params     = params;
  return msg;
};

// Helper method to convert method arguments to:
//  - rpc_method
//  - parameter list
//  - callback (if last argument is a function, else null)
RJR.JRMessage.prepare_args = function(args){
  var rpc_method = args[0];
  var cb = null;
  if(typeof(args[args.length-1]) === 'function')
    cb = args[args.length-1];

  var params = [];
  for(var a = 1; a < args.length; a++){
    var arg = args[a];
    if(typeof(arg) !== 'function')
      params.push(arg);
  }

  return [rpc_method, params, cb];
};

// Helper to prepare a request for the specified node
RJR.JRMessage.request_for_node = function(node, args){
  var preq = RJR.JRMessage.prepare_args(args);
  var req  = RJR.JRMessage.new_request(preq[0], preq[1]);
  req.onresponse = preq[2];
  req.headers = node.headers;
  req.headers['node_id'] = node.node_id;
  return req;
};

// Main json-rpc client websocket interface
RJR.WsNode = function(host, port){
  this.host     = host;
  this.port     = port;
  this.opening  = false;
  this.opened   = false;
  this.node_id  = null;
  this.headers  = {};
  this.messages = {};
};

RJR.WsNode.prototype = {
  // Open socket connection
  open : function(){
    var node = this;
    if(this.opening) return;
    this.opening = true;
    this.socket = new WebSocket("ws://" + this.host + ":" + this.port);
    this.socket.onclose   = function(){ node._socket_close(); };
    this.socket.onmessage = function(evnt){ node._socket_msg(evnt);  };
    this.socket.onerror   = function(err){ node._socket_err(err);  };
    this.socket.onopen    = function(){ node._socket_open(); };

  },

  _socket_close : function(){
    if(this.onclose) this.onclose();
  },

  _socket_msg : function(evnt){
    var msg = RJR.JRMessage.parse(evnt.data);

    // match response w/ outstanding request
    if(msg.id){
      var req = this.messages[msg.id];
      delete this.messages[msg.id];
      req.handle_response(msg)

      // if err msg, run this.onerror
      if(msg.error)
        if(this.onerror)
          this.onerror(msg)
    }

    // relying on clients to handle notifications via message_received
    // TODO add notification (and request?) handler support here
    // clients may user this to register additional handlers to be invoked
    // upon request responses
    if(this.message_received)
      this.message_received(msg);
  },

  _socket_err : function(e){
    if(this.onerror)
      this.onerror(e);
  },

  _socket_open : function(){
    this.opened = true;
    this.opening = false;

    // send queued messages
    for(var m in this.messages)
      this.socket.send(this.messages[m].to_json());

    // invoke client callback
    if(this.onopen)
      this.onopen();
  },

  // Close socket connection
  close : function(){
    this.socket.close();
  },

  // Invoke request on socket, may be invoked before or after socket is opened.
  //
  // Pass in the rpc method, arguments to invoke method with, and optional callback
  // to be invoked upon received response.
  invoke : function(){
    var req = RJR.JRMessage.request_for_node(this, arguments);

    // store requests for later retrieval
    this.messages[req.id] = req;

    if(this.opened)
      this.socket.send(req.to_json());

    return req;
  }
};

// Main json-rpc http interface
RJR.HttpNode = function(uri){
  this.uri      = uri;
  this.node_id  = null;
  this.headers  = {};
};

RJR.HttpNode.prototype = {
  // Invoke request via http
  //
  // Pass in the rpc method, arguments to invoke method with, and optional callback
  // to be invoked upon received response.
  invoke : function(){
    var req = RJR.JRMessage.request_for_node(this, arguments);

    var node      = this;
    $.ajax({type: 'POST',
            url: this.uri,
            data: req.to_json(),
            dataType: 'text', // using text so we can parse json ourselves
            success: function(data) { node._http_success(data, req); },
            error:   function(hr, st, et) { node._http_err(hr, st, et, req); }});

    return req;
  },

  _http_success : function(data, req){
    var msg = RJR.JRMessage.parse(data);
    // clients may register additional callbacks
    // to handle web node responses
    if(this.message_received)
      this.message_received(msg);

    req.handle_response(msg)

    // if err msg, run this.onerror
    if(msg.error)
      if(this.onerror)
        this.onerror(msg);
  },

  _http_err : function(jqXHR, textStatus, errorThrown, req){
    var err = { 'error' : {'code' : jqXHR.status,
                           'message' : textStatus,
                           'class' : errorThrown } };
    if(this.onerror)
      this.onerror(err);

    req.handle_response(err)
  }
};
