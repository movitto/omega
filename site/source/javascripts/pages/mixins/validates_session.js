/* Omega Page SessionValidator Mixin
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.Pages.ValidatesSession = {
  /// Restore session and validate invoking the callback corresponding to the
  /// post-validation state
  validate_session : function(){
    var _this = this;
    this.session = Omega.Session.restore_from_cookie();
    /// TODO split out anon user session into third case where we: (?)
    /// - show login controls, load default entities
    if(this.session != null && this.session.user_id != Omega.Config.anon_user){
      this.session.validate(this.node, function(response){
        if(response.error)
          _this._invalid_session();

        else{
          _this.session.user = response.result;
          _this._valid_session();
        }
      });
    }else
      _this._invalid_session();
  }
};
