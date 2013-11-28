/* Omega JS Command UI Components
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/dialog"

Omega.UI.CommandDialog = function(parameters){
  this.div_id = '#command_dialog';
  $.extend(this, parameters);
};

Omega.UI.CommandDialog.prototype = {
  append_error : function(message){
    $('#command_error').append(message);
  },
};

$.extend(Omega.UI.CommandDialog.prototype,
         new Omega.UI.Dialog());
