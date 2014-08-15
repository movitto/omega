/* Omega JS Base Callback Handler
 *
 * Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.UI.CallbackHandler = {
  init_handlers : function(parameters){
    this.handling = [];

    /// need handle to page to
    /// - register and clear rpc handlers with node
    /// - perform any actions required by callbacks
    this.page = null;

    $.extend(this, parameters);
  },

  /// Track specified server event,
  /// invoking callback configured above on receiving
  track : function(evnt){
    if(this.handling.indexOf(evnt) != -1) return;
    this.handling.push(evnt);

    var _this = this;
    this.page.node.addEventListener(evnt, function(node_evnt){
      var args = [];
      for(var a = 0; a < node_evnt.data.length; a++)
        args.push(node_evnt.data[a]);
      _this._msg_received(evnt, args);
    });
  }
};
