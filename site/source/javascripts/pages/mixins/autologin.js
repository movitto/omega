/* Omega Page Autologin Mixin
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.Pages.Autologin = {
  /// Return bool indicating if an autologin user is configured
  _should_autologin : function(){
    return !!(Omega.Config.autologin);
  },

  /// Autologin configured user
  autologin : function(cb){
    var _this = this;
    var un    = Omega.Config.autologin[0];
    var pass  = Omega.Config.autologin[1];
    var user  = new Omega.User({id : un, password: pass});
    Omega.Session.login(user, this.node, function(result){
      /// assuming autologin will always success or err is handled elsewhere
      if(!result.error){
        _this.session = result;
        _this._valid_session(cb);
      }
    });
  }
};
