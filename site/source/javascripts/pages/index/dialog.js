/* Omega JS Index Page Dialog Component
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.Pages.IndexDialog = function(parameters){
  /// need handle to page to
  /// - submit login via node
  /// - set the page session
  /// - update the page nav
  /// - submit registration via node
  this.page = null;

  $.extend(this, parameters);

  this.login_fields = [$('#login_username'), $('#login_password')];
  this.login_button    = $('#login_button');
  this.register_button = $('#register_button');
};

Omega.Pages.IndexDialog.prototype = {
  wire_up : function(){
    var _this = this;
    for(var l = 0; l < this.login_fields.length; l++)
      this.login_fields[l].keypress(function(evnt){
        if(evnt.which == 13) _this._login_clicked(evnt);
      });
    this.login_button.click(function(evnt)   {           _this._login_clicked(evnt); });
    this.register_button.click(function(evnt){ _this._register_button_clicked(evnt); });
  },

  follow_node : function(node){
    var _this = this;
    node.addEventListener('error', function(err){
      if(err.disconnected)
        _this.show_critical_err_dialog('Critical Error:', err.error.class)
    });
    node.addEventListener('closed', function(){
      /// TODO if not unloading attempt reconnecting for a configurable
      /// amount of attempts (w/ a configurable duration inbetween)
      var title = _this.page.unloading ?  'Connection Closed' : 'Critical Error: ';
      _this.show_critical_err_dialog(title, "Connection Closed");
    });
  },

  show_critical_err_dialog : function(title, msg){
    if(!msg) msg = '';
    this.hide();
    this.title  = title;
    this.div_id = '#critical_err_dialog';
    $('#critical_err').html(msg);
    this.show();
    this.keep_open();
  },

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

    Recaptcha.create(Omega.Config.recaptcha_pub, 'omega_recaptcha',
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

    /// clear inputs
    $('#login_username').val('');
    $('#login_password').val('');

    var _this = this;
    Omega.Session.login(user, this.page.node, function(result){
      if(result.error){
        _this.show_login_failed_dialog(result.error.message);
      }else{
        _this.hide();
        _this.page.session = result;
        _this.page._session_validated(function(){ _this.page._valid_session(); });
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

$.extend(Omega.Pages.IndexDialog.prototype, new Omega.UI.Dialog());
