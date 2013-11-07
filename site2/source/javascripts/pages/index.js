/* Omega Index Page JS
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/nav"
//= require "ui/dialog"
//= require "ui/canvas"
//= require "ui/effects_player"
//= require "ui/status_indicator"

Omega.UI.IndexNav = function(parameters){
  this.register_link = $('#register_link');
  this.login_link    = $('#login_link');
  this.logout_link   = $('#logout_link');

  /// need a dialog handle to show login/register forms
  this.index_dialog        = null;

  /// need a session handle to logout
  this.session             = null;

  $.extend(this, parameters);

  if(session == null)
    this.show_login_controls();
  else
    this.show_logout_controls();

  var _this = this;
  this.login_link.click(function(event){    _this._login_clicked(evnt); });
  this.logout_link.click(function(event){   _this._logout_clicked(evnt); });
  this.register_link.click(function(event){ _this._register_clicked(evnt); });
}

Omega.UI.IndexNav.prototype = {
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
    this.index_dialog.show_login_dialog();
  },

  _logout_clicked : function(evnt){
    this.session.logout();
    this.show_login_controls();
  },

  _register_clicked : function(evnt){
    this.index_dialog.show_register_dialog();
  }
}

Omega.UI.IndexDialog = function(parameters){
  this.login_button    = $('#login_button');
  this.register_button = $('#register_button');

  var _this = this;
  this.login_button.click(function(evnt){    _this._login_clicked(evnt); });
  this.register_button.click(function(evnt){ _this._register_clicked(evnt); });
}

Omega.UI.IndexDialog.prototype = {
  show_login_dialog : function(){
    this.title   = $('#login_dialog_title').html();
    this.content = $('#login_dialog').html();
    this.show();
  },

  show_register_dialog : function(){
    this.title   = $('#register_dialog_title').html();
    this.content = $('#register_dialog').html();
    this.show();
  },

  _login_clicked : function(evnt){
    /// TODO Session.login
    this.hide();
  },

  _register_button_clicked : function(evnt){
    this.title   = $('#register_dialog_title').html();
    this.content = $('#registration_submitted_dialog').html();
    /// TODO submit register dialog
  }
};

$.extend(Omega.UI.IndexDialog.prototype,
         new Omega.UI.Dialog());

Omega.Pages.Index = function(parameters){
  this.session = Omega.Session.restore_from_cookie();
  // TODO establish node connection / validate session

  this.canvas           = new Omega.UI.Canvas();
  this.effects_player   = new Omega.UI.EffectsPlayer();
  this.status_indicator = new Omega.UI.StatusIndicator();

  this.dialog           = new Omega.UI.IndexDialog();
  this.nav              = new Omega.UI.IndexNav({dialog  : this.dialog,
                                                 session : this.session});
}

$(document).ready(function(){
  var index = new Omega.Pages.Index();
});
