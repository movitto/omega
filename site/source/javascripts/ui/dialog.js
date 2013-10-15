/* Omega Javascript Dialog
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

/* Instantiate and return a new Dialog
 */
function Dialog(args){
  $.extend(this, new UIComponent(args));

  this.div_id = '#omega_dialog';

  this.opend = false;

  /* return the specified div under the dialog
   */
  this.subdiv = function(id){
    return $(this.div_id + ' ' + id);
  }

  if(args){
    // title to assign to dialog
    this.title = args['title'];

    // selector of div to populate dialog content from
    this.selector = args['selector'];

    // additional text to add to dialog
    this.text = args['text'];
  }

  /* Show the dialog
   *
   * @overrideed
   */
  this.show = function(){
    var content = this.selector ? $(this.selector).html() : null;
    if(content == null) content = "";
    if(this.text == null) this.text = "";
    this.opend = true;
    this.component().html(content + this.text).
                     dialog({title: this.title, width: '450px', closeText: ''}).
                     dialog('option', 'title', this.title).
                     dialog('open');

    /// ensure clicks don't propagate to canvas
    /// FIXME directly passing stop_prop here doesn't work for some reason
    $('.ui-dialog').on('mousedown',  function(e){ stop_prop(e);});
  };

  /* Hide omega dialog
   *
   * @overrideed
   */
  this.hide = function(){
    if(!this.opend) return;
    this.opend = false;
    this.component().dialog('close');
  };
}

