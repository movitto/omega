/* Omega Account Page JS
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "pages/mixins/base"
//= require "pages/mixins/validates_session"

//= require_tree "pages/account/init"
//= require_tree "pages/account/runner"
//= require_tree "pages/account/session"
//= require_tree "pages/account/entity_processor"

/// TODO account option where user can setup
///      uri's to stream background audio from

/// TODO framerate config on accounts page (slider)

Omega.Pages.Account = function(){
  this.init_page();
  this.init_account();
};

$.extend(Omega.Pages.Account.prototype, Omega.Pages.Base);
$.extend(Omega.Pages.Account.prototype, Omega.Pages.ValidatesSession);

$.extend(Omega.Pages.Account.prototype, Omega.Pages.AccountInitializer);
$.extend(Omega.Pages.Account.prototype, Omega.Pages.AccountRunner);
$.extend(Omega.Pages.Account.prototype, Omega.Pages.AccountSession);
$.extend(Omega.Pages.Account.prototype, Omega.Pages.AccountEntityProcessor);

$(document).ready(function(){
  if(Omega.Test) return;

  var account = new Omega.Pages.Account();
  account.wire_up();
  account.start();
});
