/* Omega JS Dialog UI Component
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */
Omega.UI.Dialog = function(parameters){
  this.content = '';
  this.title   = '';
  this.dialog  = $('#omega_dialog');
  $.extend(this, parameters);
}

Omega.UI.Dialog.prototype = {
  show : function(){
    this.dialog.html(this.content);
    this.dialog.dialog({title: this.title,
                        width: '450px',
                        closeText: ''});
    this.dialog.dialog('option', 'title', this.title);
    this.dialog.dialog('open');
  },

  hide : function(){
    this.dialog.dialog('close');
  }
};
