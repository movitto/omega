// Omega JS Test Utility Methods

Omega.Test = {
  /// return registered jquery event handlers for selector
  /// XXX http://stackoverflow.com/questions/2518421/jquery-find-events-handlers-registered-with-an-object
  events_for : function(element){
    var handlers = jQuery._data(element[0], "events");
    if(typeof handlers === "undefined") handlers = null;
    return handlers;
  },


  /// remove all event handlers
  clear_events : function(){
    $('body *').off();
  },

  /// wait until animation
  on_animation : function(canvas, cb){
    canvas.old_render = canvas.render;
    canvas.render = function(){
      canvas.old_render();
      cb(canvas);
    };
  },

  /// disable jquery dialog
  disable_dialogs : function(){
    this._dialogs_disabled = !!($.fn.dialog.restore);
    if(!this._dialogs_disabled)
      sinon.stub($.fn, 'dialog');
  },

  /// enable jquery dialogs
  enable_dialogs : function(){
    this._dialogs_disabled = !!($.fn.dialog.restore);
    if(this._dialogs_disabled)
      $.fn.dialog.restore();
  },

  /// restores dialog to it's old state/resets state
  reset_dialogs : function(){
    if(this._dialogs_disabled)
      this.disable_dialogs();
    else
      this.enable_dialogs();
  }
};

// Initializes and returns a singleton page
// instance for use in the test suite
// (for use w/ singleton canvas and elsewhere below)
Omega.Test.Page = function(){
  if(typeof($omega_test_page) === "undefined"){
    $omega_test_page = new Omega.Pages.Test();
    $omega_test_page.init_registry();
    $omega_test_page.canvas.setup();
  }
  return $omega_test_page;
};

// Return singleton canvas instance for use in the test suite
Omega.Test.Canvas = function(){
  return Omega.Test.Page().canvas;
};

// Same as Test.Canvas above but for various entities
// which can be rendered to the canvas
Omega.Test.Canvas.Entities = function(event_cb){
  if(typeof($omega_test_canvas_entities) === "undefined"){
    $omega_test_canvas_entities = {
      galaxy       : new Omega.Galaxy(),
      solar_system : new Omega.SolarSystem(),
      star         : new Omega.Star(),
      planet       : new Omega.Planet(),
      jump_gate    : new Omega.JumpGate(),
      asteroid     : new Omega.Asteroid(),
      ship         : new Omega.Ship({type : 'corvette'}), /// TODO other types, and/or a 'test' type w/ its own config
      station      : new Omega.Station({type : 'manufacturing'}) /// TODO other types
    };
    var page     = Omega.Test.Page();
    var config   = page.config;
    if(!event_cb) event_cb = function(){};
    for(var e in $omega_test_canvas_entities){
      $omega_test_canvas_entities[e].location = new Omega.Location();
      $omega_test_canvas_entities[e].location.set(0,0,0);
      $omega_test_canvas_entities[e].location.set_orientation(0,1,0);
      if(e == 'planet')
        $omega_test_canvas_entities[e].location.movement_strategy =
          Omega.Gen.orbit_ms();
      else
        $omega_test_canvas_entities[e].location.movement_strategy =
          {json_class : 'Motel::MovementStrategies::Stopped'};
      $omega_test_canvas_entities[e].init_gfx(event_cb);
    }
  }
  return $omega_test_canvas_entities;
};
