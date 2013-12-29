/* Omega JS Node, uses RJR to handle all JSON-RPC operations
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.Node = function(parameters){
  this.http_host   = 'localhost';
  this.http_path   = '/omega';
  this.ws_host     = 'localhost';
  this.ws_port     = 8080;
  $.extend(this, parameters);

  this.http_url = 'http://' + this.http_host + this.http_path;

  this.http = new RJR.HttpNode(this.http_url);
  this.ws   = new RJR.WsNode(this.ws_host, this.ws_port);

  var _this = this;
  this.ws.message_received   = function(msg){ _this._ws_msg_received(msg);   }
  this.http.message_received = function(msg){ _this._http_msg_received(msg); }
  this.ws.onerror            = function(msg){ _this._on_err(msg);            }
  this.http.onerror          = function(msg){ _this._on_err(msg);            }
  this.ws.onclose            = function(){    _this._on_close();             }
};

Omega.Node.prototype = {
  constructor : Omega.Node,

  /* Set header value on the local rjr nodes.
   *
   * @param {String} header name of the header to set
   * @param {String} value value to set the header to
   */
  set_header : function(header, value){
    this.ws.headers[header]   = value;
    this.http.headers[header] = value;
  },

  /* Invoke a json-rpc message on the Omega server via a web socket request.
   *
   * Takes same parameters as WSNode#invoke
   */
  ws_invoke : function(){
    /// automatically open ws socket connection on first request
    if(!this.ws.opened) this.ws.open();

    var msg = this.ws.invoke.apply(this.ws, arguments);
    this.dispatchEvent({type: 'request', data: msg});
    return msg;
  },

  /* Invoke a json-rpc message on the Omega server via a http request.
   *
   * Takes same parameters as WebNode#invoke
   */
  http_invoke : function(){
    var msg = this.http.invoke.apply(this.http, arguments)
    this.dispatchEvent({type: 'request', data: msg});
    return msg;
  },

  /// websocket message received callback
  _ws_msg_received : function(jr_msg){
    var evnt = $.extend(jr_msg, {type:'msg_received'})
    this.dispatchEvent(evnt);

    /// ensure this is a request message
    if(jr_msg && jr_msg['rpc_method']){
      var method = jr_msg['rpc_method'];
      var params = jr_msg['params'];
      this.dispatchEvent({type: method, data: params});
    }
  },

  /// http message received callback
  _http_msg_received : function(jr_msg){
    var evnt = $.extend(jr_msg, {type:'msg_received'});
    this.dispatchEvent(evnt);
  },

  /// ws & http error callback
  _on_err : function(err){
    if(err.error && err.error.code  == 503 &&
       err.error.class == 'Service Unavailable')
      err.disconnected = true;
    var evnt = $.extend(err, {type:'error'});
    this.dispatchEvent(evnt);
  },

  /// ws close callback
  _on_close : function(){
    var evnt = {type : 'closed'};
    this.dispatchEvent(evnt);
  }
};

THREE.EventDispatcher.prototype.apply( Omega.Node.prototype );
