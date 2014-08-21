/// Omega Test Page

//////////////////////////////// test page entity tests can use
Omega.Pages.Test = function(parameters){
  this.config  = Omega.Config;
  this.node    = new Omega.Node(this.config);
  this.canvas  = new Omega.UI.Canvas({page: this});
  this.audio_controls = new Omega.UI.AudioControls();
  this.init_registry();
  $.extend(this, parameters);
}

Omega.Pages.Test.prototype = {
  process_entity : function(entity){},

  restore_entities : function(){
    this.entities = [];
  },

  set_session : function(session){
    this.current_session = this.session;
    this.session = session;
  },

  restore_session : function(){
    this.session = this.current_session;
    this.current_session = null;
  },

  set_canvas_root : function(root){
    this.current_root = this.canvas.root;
    this.canvas.root = root;
  },

  restore_canvas_root : function(){
    this.canvas.root = this.current_root;
    this.current_root = null;
  }
}

$.extend(Omega.Pages.Test.prototype, Omega.Pages.HasRegistry);
