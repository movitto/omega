/* Omega JS Base Dialog UI Component
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */
Omega.UI.Dialog = function(parameters){
  this.div_id    = '#omega_dialog';
  this.title     = '';
  $.extend(this, parameters);
}

Omega.UI.Dialog.prototype = {
  component : function(){
    return $(this.div_id);
  },

  dialog : function(){
    return $(this.div_id);
  },

  show : function(){
    this.dialog().dialog({title: this.title,
                          width: '450px',
                          closeText: ''});
    this.dialog().dialog('option', 'title', this.title);
    this.dialog().dialog('open');
  },

  hide : function(){
    this.dialog().dialog(); // needed incase dialog not already initialized
    this.dialog().dialog('close');
  },

  keep_open : function(){
    this.dialog().dialog({closeOnEscape: false});
    $(".ui-dialog-titlebar-close").hide();
  }
};

// manually removes all dialogs
Omega.UI.Dialog.remove = function(){
  $('.ui-dialog').remove();
};
