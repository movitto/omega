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
  },

  _create_entities : function(){
    this._test_entities = {
      galaxy       : new Omega.Galaxy(),
      solar_system : new Omega.SolarSystem(),
      star         : new Omega.Star(),
      planet       : new Omega.Planet(),
      jump_gate    : new Omega.JumpGate(),
      asteroid     : new Omega.Asteroid(),
      ship         : new Omega.Ship({type : 'corvette'}), /// TODO other types, and/or a 'test' type w/ its own config
      station      : new Omega.Station({type : 'manufacturing'}) /// TODO other types
    };
  },

  _init_entities : function(event_cb){
    var page = new Omega.Pages.Test();
    if(!event_cb) event_cb = function(){};

    for(var e in this._test_entities){
      var entity = this._test_entities[e];

      var loc = new Omega.Location();
      loc.set(0,0,0);
      loc.set_orientation(0,1,0);
      if(e == 'planet')
        loc.movement_strategy = Omega.Gen.orbit_ms();
      else
        loc.movement_strategy = {json_class : 'Motel::MovementStrategies::Stopped'};
      entity.location = loc;

      entity.init_gfx(event_cb);
    }
  },

  entities : function(event_cb){
    if(typeof(this._test_entities) !== "undefined")
      return this._test_entities;
    this._create_entities();
    this._init_entities(event_cb);
    return this._test_entities;
  },

  page : function(){
    if(this._page) return this._page;
    this._page = new Omega.Pages.Test();
    this._page.canvas.init_gl();
    return this._page;
  },

  canvas : function(){
    return this.page().canvas;
  }
};
