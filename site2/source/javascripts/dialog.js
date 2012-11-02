function show_dialog(title, selector, text){
  var content = $(selector).html();
  if(content == null) content = "";
  if(text == null) text = "";
  $('#omega_dialog').html(content + text).dialog({title: title, width: '450px'}).
                                 dialog('option', 'title', title).dialog('open');
};

function append_to_dialog(text){
  var d = $('#omega_dialog');
  d.html(d.html() + text);
}

function hide_dialog(){
  $('#omega_dialog').dialog('close');
};
