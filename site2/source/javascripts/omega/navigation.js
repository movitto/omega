/* Omega Navigation Operations
 *
 * Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

// google recaptcha for new accounts
require('javascripts/vendor/google_recaptcha_ajax.js');
require('javascripts/omega/user.js');

/////////////////////////////////////// Omega Navigation Container

/* Initialize new Omega Navigation Container
 */
function OmegaNavigationContainer(){

  /////////////////////////////////////// private data

  var register_link       = $('#register_link');

  var login_link          = $('#login_link');

  var logout_link         = $('#logout_link');

  var account_link        = $('#account_link');

  /////////////////////////////////////// private methods

  /* Show login controls, hide logout controls
   */
  var show_login_controls = function(){
    register_link.show(); login_link.show();
    account_link.hide();  logout_link.hide();
    
  }

  /* Show logout controls, hide login controls
   */
  var show_logout_controls = function(){
    account_link.show();  logout_link.show();
    register_link.hide(); login_link.hide();
  }

  /* Show the login dialog
   */
  var show_login_dialog = function(){
    $omega_dialog.show('Login', '#login_dialog');
  }

  /* Submit the login dialog
   */
  var submit_login_dialog = function(){
    var user_id       = $('#omega_dialog #login_username').attr('value');
    var user_password = $('#omega_dialog #login_password').attr('value');
    var user = new OmegaUser({ id : user_id, password : user_password });
    $omega_dialog.hide();
    $omega_session.login_user(user);
  }

  /* Log the user out
   */
  var handle_logout_click = function(){
    $omega_session.logout_user();
    show_login_controls();
  }

  /* Show registration dialog
   */
  var show_register_dialog = function(){
    $omega_dialog.show('Create Account', '#register_dialog');
  
    // FIXME make recaptcha public key variable / configurable
    $('#omega_dialog #omega_recaptcha').html('<div id="omega_registration_recaptcha"></div>');
    Recaptcha.create("6LflM9QSAAAAAHsPkhWc7OPrwV4_AYZfnhWh3e3n", "omega_registration_recaptcha",
                     { theme: "red", callback: Recaptcha.focus_response_field});
  }

  /* Handle registration submitted response
   */
  var callback_registration_submitted = function(user, error){
    if(error){
      $omega_dialog.show('Failed to create account', '#registration_failed_dialog', error['message'])
    }else{
      $omega_dialog.show('Creating Account', '#registration_submitted_dialog')
    }
  }

  /* Submit register user dialog
   */
  var submit_register_dialog = function(){
    var user_id             = $('#omega_dialog #register_username').attr('value');
    var user_password       = $('#omega_dialog #register_password').attr('value');
    var user_email          = $('#omega_dialog #register_email').attr('value');
    var recaptcha_challenge = Recaptcha.get_challenge();
    var recaptcha_response  = Recaptcha.get_response();

    var user = new OmegaUser({ id : user_id, password : user_password, email : user_email,
                          recaptcha_challenge : recaptcha_challenge,
                          recaptcha_response : recaptcha_response});
  
    $omega_dialog.hide();
    $omega_session.register_user(user, callback_registration_submitted);
  }

  /////////////////////////////////////// initialization

  $omega_session.on_session_validated(show_logout_controls);
  $omega_session.on_invalid_session(show_login_controls);

  $('#login_link').live('click', function(event){ show_login_dialog(); });
  //$('#omega_dialog input').live('keypress', function(e){ if(e.keyCode == 13) submit_login_dialog(); }); // submit on enter
  $('#login_button').live('click', function(event){ submit_login_dialog(); });

  $('#logout_link').live('click', function(event){ handle_logout_click(); });

  $('#register_link').live('click', function(event){ show_register_dialog(); });
  $('#register_button').live('click', function(event){ submit_register_dialog(); });
}

$(document).ready(function(){ 
  $omega_navigation = new OmegaNavigationContainer();
});
