/* Omega JS Account Dialog UI Component
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

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
