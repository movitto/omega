$(document).ready(function(){ 
  // lock chat container to its current position
  $('#chat_container').css({
    position: 'absolute',
    top: $('#chat_container').position().top,
    left: $('#chat_container').position().left
  });
});
