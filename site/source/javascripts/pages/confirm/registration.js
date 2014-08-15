/* Omega Confirmation Page Registration Mixin
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.Pages.ConfirmRegistration = {
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
