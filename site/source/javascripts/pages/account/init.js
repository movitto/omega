/* Omega JS Account Page Initializer
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/splash"

//= require "pages/account/details"
//= require "pages/account/dialog"

Omega.Pages.AccountInitializer = {
  init_account : function(){
    this.dialog  = new Omega.Pages.AccountDialog();
    this.details = new Omega.Pages.AccountDetails({page : this});
  },

  wire_up : function(){
    this.details.wire_up();

    $('#account_info_clear_notices').on('click', function(){
      new Omega.UI.SplashScreen().clear_notices();
    });
  }
};
