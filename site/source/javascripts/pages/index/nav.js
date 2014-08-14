/* Omega JS Index Nav UI Component
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

// TODO rename to Omega.Pages.Index.Nav ? (same w/ Dialog below)
Omega.UI.IndexNav = function(parameters){
  this.register_link = $('#register_link');
  this.login_link    = $('#login_link');
  this.logout_link   = $('#logout_link');
  this.account_link  = $('#account_link');

  /// need handle to page to
  /// - interact w/ dialog (login/register forms)
  /// - logout of session
  /// - logout using node
  this.page = null;

  $.extend(this, parameters);
};

Omega.UI.IndexNav.prototype = {
  wire_up : function(){
    var _this = this;
    this.login_link.click(function(evnt)   {    _this._login_clicked(evnt); });
    this.logout_link.click(function(evnt)  {   _this._logout_clicked(evnt); });
    this.register_link.click(function(evnt){ _this._register_clicked(evnt); });
  },

  show_login_controls : function(){
    this.register_link.show();
    this.login_link.show();
    this.account_link.hide();
    this.logout_link.hide();
  },

  show_logout_controls : function(){
    this.account_link.show();
    this.logout_link.show();
    this.register_link.hide();
    this.login_link.hide();
  },

  _login_clicked : function(evnt){
    this.page.dialog.show_login_dialog();
  },

  _logout_clicked : function(evnt){
    this.page.session.logout(this.page.node);
    this.page.canvas.controls.missions_button.hide();
    this.page._session_invalid();
  },

  _register_clicked : function(evnt){
    this.page.dialog.show_register_dialog();
  }
};

