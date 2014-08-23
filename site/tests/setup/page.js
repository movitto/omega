/// Omega Test Page

Omega.Pages.Test = function(){
  this.init_page();
  this.init_registry();
  this.init_canvas();
  this.init_audio();
}

Omega.Pages.Test.prototype = {
  process_entity : function(entity){}
}

$.extend(Omega.Pages.Test.prototype, Omega.Pages.Base);
$.extend(Omega.Pages.Test.prototype, Omega.Pages.HasRegistry);
$.extend(Omega.Pages.Test.prototype, Omega.Pages.HasCanvas);
$.extend(Omega.Pages.Test.prototype, Omega.Pages.HasAudio);
