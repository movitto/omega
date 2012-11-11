/* Omega Dialog Operations
 *
 * Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

/////////////////////////////////////// public methods

/* Show the dialog with the specified title,
 * containing the content from the specified select,
 * with additional specified text
 *
 * @param {String} title title to give the dialog
 * @param {String} selector optional css selector of div to populate dialog with
 * @param {String} text optional additional text to add to div
 */
function show_dialog(title, selector, text){
  var content = $(selector).html();
  if(content == null) content = "";
  if(text == null) text = "";
  $('#omega_dialog').html(content + text).dialog({title: title, width: '450px'}).
                                 dialog('option', 'title', title).dialog('open');
};

/* Append text to dialog
 *
 * @param {String} text text to append to dialog
 */
function append_to_dialog(text){
  var d = $('#omega_dialog');
  d.html(d.html() + text);
}

/* Hide omega dialog
 */
function hide_dialog(){
  $('#omega_dialog').dialog('close');
};

///////////////////////////////////////
