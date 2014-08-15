/* Omega JS Index Page Runner
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.Pages.IndexRunner = {
  start : function(){
    if(!this.canvas.detect_webgl()){
      this._require_webgl();
      return;
    }

    this.effects_player.start();
    this.splash.start();

    var _this = this;
    if(this._should_autologin())
      this.autologin();
    else
      this.validate_session();
  },

  _require_webgl : function(){
    var msg = 'A WebGL capable browser is currently required';
    this.dialog.show_critical_err_dialog('WebGL Required', msg);
  }
};
