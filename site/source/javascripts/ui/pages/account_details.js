/* Omega JS Account Details UI Component
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require 'vendor/utf8_encode'
//= require 'vendor/md5'

Omega.UI.AccountDetails = function(parameters){
  /// need handle to page to
  /// - access config
  this.page = null;

  $.extend(this, parameters);
};

Omega.UI.AccountDetails.prototype = {
  wire_up : function(){
    var _this = this;;
    //$('#account_info_update').die();
    $('#account_info_update').click(function(){ _this._update(); });
  },

  _update : function(){
    if(!this.passwords_match()){
      this.page.dialog.show_incorrect_passwords_dialog();
    }else{
      var _this = this;
      this.page.node.http_invoke('users::update_user', this.user(),
        function(response){
          if(response.error)
            _this.page.dialog.show_update_error_dialog(response.error.message);
          else
            _this.page.dialog.show_update_success_dialog();
        });
    }
  },

  /// get/set username
  username : function(val){
    var container = $('#account_info_username input');
    if(val) container.val(val);
    return container.val();
  },

  /// get password
  password : function(){
    return $('#user_password').val();
  },

  password_confirmation : function(){
    return $("#user_confirm_password").val();
  },

  /// get/set the email element
  email : function(val){
    var container = $('#account_info_email input');
    if(val) container.val(val);
    return container.val();
  },

  /// set the gravatar element
  gravatar : function(email){
    var container = $('#account_logo');
    var gravatar_url = 'http://gravatar.com/avatar/' +
                        md5(email) + '?s=175';
    var gravatar = $("<img />",
      {src   : gravatar_url,
       alt   : 'gravatar',
       title : 'gravatar'});
    container.html('');
    container.append(gravatar);
  },

  /// set entities
  entities : function(entities){
    for(var e = 0; e < entities.length; e++){
      var entity = entities[e];
      this.entity(entity);
    }

  },

  entity : function(entity){
    if(entity.json_class == 'Manufactured::Ship')
      $('#account_info_ships').append(entity.id + ' ');
    else if(entity.json_class == 'Manufactured::Station')
      $('#account_info_stations').append(entity.id + ' ');
  },

  /// return bool indicating if password matches confirmation
  passwords_match : function(){
    var pass1 = this.password();
    var pass2 = this.password_confirmation();
    return pass1 == pass2;
  },

  /// return user generated from account info
  user : function(){
    return new Omega.User({id    : this.username(),
                           email : this.email(),
                           password: this.password()});
  },

  /// add a badge to account into page
  add_badge : function(id, description, rank){
    var badges = $('#account_info_badges');
    var url    = this.page.config.url_prefix + '/images/badges/' + id + '.png';
    var badge  = $('<div />',
      {class : 'badge',
       style : "background: url('"+url+"');",
       text  : description + ": " + (rank+1)});
    badges.append(badge);
  }
};

