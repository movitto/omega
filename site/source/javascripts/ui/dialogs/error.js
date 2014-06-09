/* Omega JS Error Dialog Operations
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.UI.ErrorDialog = {
  append_error : function(message){
    $('#command_error').append(message);
  },

  clear_errors : function(){
    $('#command_error').empty();
  },

  show_error_dialog : function(){
    this.div_id = '#command_dialog';
    this.show();
  }
};
