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
//= require "ui/canvas"

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

  var _this = this;
  this.login_link.click(function(evnt){    _this._login_clicked(evnt); });
  this.logout_link.click(function(evnt){   _this._logout_clicked(evnt); });
  this.register_link.click(function(evnt){ _this._register_clicked(evnt); });
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
    this.page.dialog.show_login_dialog();
  },

  _logout_clicked : function(evnt){
    this.page.session.logout(this.page.node);
    this.show_login_controls();
  },

  _register_clicked : function(evnt){
    this.page.dialog.show_register_dialog();
  }
}

Omega.UI.IndexDialog = function(parameters){
  /// need handle to page to
  /// - submit login via node
  /// - set the page session
  /// - update the page nav
  /// - retrieve recaptcha from page config
  /// - submit registration via node
  this.page = null;

  $.extend(this, parameters);

  this.login_button    = $('#login_button');
  this.register_button = $('#register_button');

  var _this = this;
  this.login_button.click(function(evnt){    _this._login_clicked(evnt); });
  this.register_button.click(function(evnt){ _this._register_button_clicked(evnt); });
}

Omega.UI.IndexDialog.prototype = {
  show_login_dialog : function(){
    this.hide();
    this.title   = 'Login';
    this.div_id  = '#login_dialog';
    this.show();
  },

  show_register_dialog : function(){
    this.hide();
    this.title   = 'Register';
    this.div_id  = '#register_dialog';

    Recaptcha.create(this.page.config.recaptcha_pub, 'omega_recaptcha',
      { theme: "red", callback: Recaptcha.focus_response_field});

    this.show();
  },

  show_login_failed_dialog : function(err){
    this.hide();
    this.title   = 'Login Failed';
    this.div_id  = '#login_failed_dialog';
    $('#login_err').html('Login Failed: ' + err);
    this.show();
  },

  show_registration_submitted_dialog : function(){
    this.hide();
    this.title = 'Registration Submitted';
    this.div_id = '#registration_submitted_dialog';
    this.show();
  },

  show_registration_failed_dialog : function(err){
    this.hide();
    this.title = 'Registration Failed';
    this.div_id = '#registration_failed_dialog';
    $('#registration_err').html('Failed to create account: ' + err)
    this.show();
  },

  _login_clicked : function(evnt){
    var user_id  = $('#login_username').val();
    var password = $('#login_password').val();
    var user = new Omega.User({id: user_id, password: password});

    var _this = this;
    Omega.Session.login(user, this.page.node, function(result){
      if(result.error){
        _this.show_login_failed_dialog(result.error.message);
      }else{
        _this.hide();
        _this.page.session = result;
        _this.page.nav.show_logout_controls();
      }
    });
  },

  _register_button_clicked : function(evnt){
    var user_id       = $('#register_username').val();
    var user_password = $('#register_password').val();
    var user_email    = $('#register_email').val();
    var recaptcha_challenge = Recaptcha.get_challenge();
    var recaptcha_response  = Recaptcha.get_response();
    var user = new Omega.User({id: user_id, password: user_password, email: user_email,
                               recaptcha_challenge: recaptcha_challenge,
                               recaptcha_response : recaptcha_response});

    var _this = this;
    this.page.node.http_invoke('users::register', user, function(result){
      if(result.error){
        _this.show_registration_failed_dialog(result.error.message);
      }else{
        _this.show_registration_submitted_dialog();
      }
    });
  }
};

$.extend(Omega.UI.IndexDialog.prototype,
         new Omega.UI.Dialog());

Omega.Pages.Index = function(){
  this.config  = Omega.Config;
  this.node    = new Omega.Node(this.config);

  var _this = this;
  this.session = Omega.Session.restore_from_cookie();
  if(this.session != null){
    this.session.validate(this.node, function(result){
      if(result.error){
        _this.session = null;
        _this.nav.show_login_controls();
      }else{
        _this.nav.show_logout_controls();
        /// TODO load entities, locations
      }
    });
  }

  /// not blocking for validation to return,
  /// assuming it'll arrive before node is used above

  //this.effects_player   = new Omega.UI.EffectsPlayer();

  this.dialog           = new Omega.UI.IndexDialog({page : this});
  this.nav              = new    Omega.UI.IndexNav({page : this});
  this.canvas           = new       Omega.UI.Canvas({page: this});
  this.status_indicator = new          Omega.UI.StatusIndicator();

  /// FIXME play status_indicator
  this.status_indicator.follow_node(this.node);
}

$(document).ready(function(){
//FIXME needs to be enabled for app, disabled for tests
  //var index = new Omega.Pages.Index();
});
