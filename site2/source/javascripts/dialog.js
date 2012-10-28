function show_dialog(title, selector, text){
  // TODO change title (first one is always used)
  var content = $(selector).html();
  if(content == null) content = "";
  if(text == null) text = "";
  $('#omega_dialog').html(content + text).dialog({title: title, width: '450px'}).dialog('open');
};

function hide_dialog(){
  $('#omega_dialog').dialog('close');
};
