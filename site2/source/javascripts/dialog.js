function show_dialog(title, selector, text){
  var content = $(selector).html();
  if(text == null) text = "";
  $('#omega_dialog').html(content + text).dialog({title: title, width: '450px'}).dialog('open');
};

function hide_dialog(){
  $('#omega_dialog').dialog('close');
};
