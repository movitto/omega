/* Omega Confirm Page JS
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "vendor/purl"

//= require "pages/mixins/base"
//= require "pages/mixins/redirect"
//= require "pages/confirm/registration""

Omega.Pages.Confirm = function(){
  this.init_page();
};

$.extend(Omega.Pages.Confirm.prototype, Omega.Pages.Base);
$.extend(Omega.Pages.Confirm.prototype, Omega.Pages.Redirect);
$.extend(Omega.Pages.Confirm.prototype, Omega.Pages.ConfirmRegistration);

$(document).ready(function(){
  if(Omega.Test) return;

  new Omega.Pages.Confirm().confirm_registration();
});
