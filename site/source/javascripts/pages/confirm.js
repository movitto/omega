/* Omega Confirm Page JS
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "vendor/purl"

Omega.Pages.Confirm = function(){
  this.node    = new Omega.Node();
};

Omega.Pages.Confirm.prototype = {
  /// XXX needed to stub out get/set window location in test suite
  url : function(){
    return window.location;
  },
  redirect_to : function(value){
    window.location = value;
  },

  registration_code : function(){
    var url = $.url(this.url());
    return url.param('rc');
  },

  confirm_registration : function(){
    var _this = this
    var code = this.registration_code();
    this.node.http_invoke('users::confirm_register', code,
      function(response){ _this._registration_response(); });
  },

  _registration_response : function(){
    /// XXX
    alert("Done... redirecting");

    var host   = Omega.Config.http_host;
    var prefix = Omega.Config.url_prefix;
    this.redirect_to('http://'+host+prefix);
  }
};

$(document).ready(function(){
  if(Omega.Test) return;

  var dev = new Omega.Pages.Confirm();
  dev.confirm_registration();
});
