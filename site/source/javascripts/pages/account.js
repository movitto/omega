/* Omega Account Page JS
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
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

Omega.UI.AccountDialog = function(parameters){
  $.extend(this, parameters);
};

Omega.UI.AccountDialog.prototype = {
  show_incorrect_passwords_dialog : function(){
    this.hide();
    this.title = 'Passwords Do Not Match'
    this.div_id = '#incorrect_passwords_dialog'
    this.show();
  },

  show_update_error_dialog : function(error_msg){
    this.hide();
    this.title = 'Error Updating User';
    this.div_id = '#user_update_error_dialog';
    $('#update_user_error').html('Error: ' + error_msg);
    this.show();
  },

  show_update_success_dialog : function(){
    this.hide();
    this.title = 'User Updated';
    this.div_id = '#user_updated_dialog';
    this.show();
  }
};

$.extend(Omega.UI.AccountDialog.prototype,
         new Omega.UI.Dialog());

Omega.Pages.Account = function(){
  this.config  = Omega.Config;
  this.node    = new Omega.Node(this.config);
  this.dialog  = new Omega.UI.AccountDialog();
  this.details = new Omega.UI.AccountDetails({page : this});

  var _this = this;
  this.session = Omega.Session.restore_from_cookie();
  if(this.session != null){
    this.session.validate(this.node, function(response){
      if(response.error){
        _this.session = null;
        /// TODO redirect to index?
      }else{
        var user = response.result;
        _this.details.username(user.id);
        _this.details.email(user.email);
        _this.details.gravatar(user.email);

        /// load entities owned by user
        Omega.Ship.owned_by(_this.session.user_id, _this.node,
          function(ships) { _this.process_entities(ships); });
        Omega.Station.owned_by(_this.session.user_id, _this.node,
          function(stations) { _this.process_entities(stations); });

        /// load user stats
        /// TODO configurable stats
        Omega.Stat.get('with_most', ['entities', 10], _this.node,
          function(stat_result) { _this.process_stat(stat_result); });
      }
    });
  }
};

Omega.Pages.Account.prototype = {
  wire_up : function(){
    this.details.wire_up();
  },

  process_entities : function(entities){
    for(var e = 0; e < entities.length; e++){
      var entity = entities[e];
      this.process_entity(entity);
    }
  },

  process_entity : function(entity){
    this.details.entity(entity);
  },

  process_stat : function(stat_result){
    if(stat_result == null) return;
    var stat = stat_result.stat;
    for(var v = 0; v < stat_result.value.length; v++){
      var value = stat_result.value[v];
      if(value == this.session.user_id){
        this.details.add_badge(stat.id, stat.description, v)
        break;
      }
    }
  }
};

$(document).ready(function(){
  if(Omega.Test) return;

  var account = new Omega.Pages.Account();
  account.wire_up();
});
