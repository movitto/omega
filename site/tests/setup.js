// Test helper

// NIY = Not Implemented Yet
// Specs will fails if stubbed out but not implemented, so
// tests commented out but marked w/ 'NIY' should be implemented later

//////////////////////////////// test page entity tests can use

Omega.Pages.Test = function(parameters){
  this.config  = Omega.Config;
  this.node    = new Omega.Node(this.config);
  this.canvas  = new Omega.UI.Canvas({page: this});
  this.audio_controls = new Omega.UI.AudioControls();
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

$.extend(Omega.Pages.Test.prototype, new Omega.UI.Registry());

//////////////////////////////// helper methods / shared test data

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
      $omega_test_canvas_entities[e].init_gfx(config, event_cb);
    }
  }
  return $omega_test_canvas_entities;
};

//////////////////////////////// test hooks

function before_all(details){
  /// clear cookies
  /// FIXME XXX for some reason cookie removal isn't working in this content
  /// so if cookies pre-exist some tests may fail
  Omega.Session.prototype.clear_cookies();

  Omega.Test.disable_dialogs();
}

function before_each(details){
  Omega.UI.Loader.clear_universe();
}

//function after_each(details){
//}

function after_all(details){
  /// clear cookies
  Omega.Session.prototype.clear_cookies();
}

QUnit.moduleStart(before_all);
QUnit.testStart(before_each);
//QUnit.testDone(after_each);
QUnit.moduleDone(after_all);

//////////////////////////////// custom assertions

// https://raw.github.com/JamesMGreene/qunit-assert-close/master/qunit-assert-close.js
// adapted to pavlov
pavlov.specify.extendAssertions({
  /**
   * Checks that the first two arguments are equal, or are numbers close enough to be considered equal
   * based on a specified maximum allowable difference.
   *
   * @example assert.close(3.141, Math.PI, 0.001);
   *
   * @param Number actual
   * @param Number expected
   * @param Number maxDifference (the maximum inclusive difference allowed between the actual and expected numbers)
   * @param String message (optional)
   */
  close: function(actual, expected, maxDifference, message) {
    var passes = (actual === expected) || Math.abs(actual - expected) <= maxDifference;
    ok(passes, message);
  },

  /**
   * Checks that the first two arguments are numbers with differences greater than the specified
   * minimum difference.
   *
   * @example assert.notClose(3.1, Math.PI, 0.001);
   *
   * @param Number actual
   * @param Number expected
   * @param Number minDifference (the minimum exclusive difference allowed between the actual and expected numbers)
   * @param String message (optional)
   */
  notClose: function(actual, expected, minDifference, message) {
    ok(Math.abs(actual - expected) > minDifference, message);
  },

  // Check if set values are close to the specified set
  areCloseTo : function(actual, expected, maxDifference, message){
    ok(actual.length == expected.length, message);
    for(var i = 0; i < actual.length; i++){
      ok(Math.abs(actual[i] - expected[i]) <= maxDifference, message);
    }
  },

  isLessThan: function(actual, expected, message) {
    ok(actual < expected, message);
  },

  isGreaterThan: function(actual, expected, message) {
    ok(actual > expected, message);
  },

  isAtLeast: function(actual, expected, message) {
    ok(actual >= expected, message);
  },

  isOfType: function(actual, expected, message){
    ok(actual.__proto__ === expected.prototype, message);
  },

  includes: function(array, value, message) {
    var found = false;
    for(var ai in array){
      // use QUni.equiv to perform a deep object comparison
      if(QUnit.equiv(array[ai], value)){
        found = true
        break
      }
    }
    ok(found, message)
  },

  doesNotInclude: function(array, value, message){
    var found = false;
    for(var ai in array){
      if(QUnit.equiv(array[ai], value)){
        found = true
        break
      }
    }
    ok(!found, message);
  },

  contains : function(string, value, message){
    ok(string.indexOf(value) != -1, message);
  },

  empty: function(array, message) {
    ok(array.length == 0, message)
  },

  notEmpty: function(array, message) {
    ok(array.length != 0, message)
  },

  isVisible: function(actual, message){
    ok(actual.is(':visible'), message);
  },

  isHidden: function(actual, message){
    ok(actual.is(':hidden'), message);
  },

  handles: function(actual, evnt, message){
    var handlers = Omega.Test.events_for(actual);
    ok(handlers != null && handlers[evnt].length > 0, message);
  },

  doesNotHandle: function(actual, evnt, message){
    var handlers = Omega.Test.events_for(actual);
    ok(handlers == null || handlers[evnt] == null || handlers[evnt].length == 0,
       message);
  },

  handlesChild: function(actual, evnt, selector, message){
    var handlers = Omega.Test.events_for(actual);
    var check = (handlers != null && handlers[evnt].length > 0);
    if(check) check = ($.grep(handlers[evnt],
                function(h){return h.selector == selector;}).length > 0);
    ok(check, message);
  },

  doesNotHandleChild: function(actual, evnt, selector, message){
    var handlers = Omega.Test.events_for(actual);
    var check = (handlers == null || handlers[evnt].length == 0);
    if(!check) check = ($.grep(handlers[evnt],
                 function(h){return h.selector == selector;}).length == 0);
    ok(check, message);
  },

  handlesEvent : function(actual, evnt, message){
    var listeners = actual._listeners;
    var check = (listeners && listeners[evnt] && listeners[evnt].length > 0);
    ok(check, message);
  },

  doesNotHandleEvent : function(actual, evnt, message){
    var listeners = actual._listeners;
    var check = (!listeners || !listeners[evnt] || listeners[evnt].length == 0);
    ok(check, message);
  }
})

//////////////////////////////// sinon.spy helper

/// Custom extension to sinon.spy returning the omega callback passed to it.
/// Assumes the callback is the last function argument passed in
sinon.spy.omega_callback = function(n){
  if(!n) n = 0;
  var args = this.getCall(n).args;
  for(var a = args.length - 1; a >= 0; a--)
    if(typeof(args[a]) === "function")
      return args[a];
  return null;
};

//////////////////////////////// custom matchers

// function domain: http://en.wikipedia.org/wiki/Domain_of_a_function
//
// matches functions by how they evaluate,
// specify expected return value as first argument and parameters
// to pass to function to generate that return value as remaining arguments
sinon.match.func_domain = function(){
  var params = args_to_arry(arguments);
  var expected_return = params.shift();
  return sinon.match(function(value){
           return sinon.match.func &&
                  value.apply(null, params) == expected_return;
         }, 'func_domain');
};

// matches type in same manner as pavlov isOfType above
sinon.match.ofType = function(expected){
  return sinon.match(function(value){
           return value.__proto__ == expected.prototype;
         }, 'type');
};

// matches location by coordinates
sinon.match.loc = function(x,y,z){
  return sinon.match(function(value){
           return value.json_class == 'Motel::Location' &&
                  value.x == x && value.y == y && value.z == z;
         }, 'loc');
};

//////////////////////////////// config/init

QUnit.config.autostart = false;

Omega.Test.init = function(){
  /// preload all canvas entity resources before starting test suite
  var loaded = 0, entities_with_resources = [];
  var start_on_load = function(){
    loaded += 1;
    if(loaded == entities_with_resources.length+1)
      QUnit.start();
  };

  var entities = Omega.Test.Canvas.Entities();
  for(var e in entities){
    if(entities[e].retrieve_resource)
      entities_with_resources.push(entities[e]);
  }

  for(var e = 0; e < entities_with_resources.length; e++)
    entities_with_resources[e].retrieve_resource('mesh', start_on_load);

  Omega.Gen.init(Omega.Config, start_on_load);
}

/// should be triggered after QUnit.load
$(window).on('load', Omega.Test.init);
