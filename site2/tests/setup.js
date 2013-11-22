// Test helper

// NIY = Not Implemented Yet
// Specs will fails if stubbed out but not implemented, so
// tests commented out but marked w/ 'NIY' should be implemented later

//////////////////////////////// helper methods/data

Omega.Pages.Test = function(parameters){
  this.config  = Omega.Config;
  $.extend(this, parameters);
}

Omega.Pages.Test.prototype = {
}

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
  }
};

// Initializes and returns a singleton page
// instance for use in the test suite
// (for use w/ singleton canvas and elsewhere below)
Omega.Test.Page = function(){
  if(typeof($omega_test_page) === "undefined"){
    $omega_test_page = new Omega.Pages.Test();
  }
  return $omega_test_page;
};

// Initializes and returns a singleton canvas
// instance for use in the test suite
// (so that THREE can be loaded on demand the
//  first time it is needed and only once)
Omega.Test.Canvas = function(){
  if(typeof($omega_test_canvas) === "undefined"){
    var page = Omega.Test.Page();
    $omega_test_canvas = new Omega.UI.Canvas({page : page});
    $omega_test_canvas.setup();
  }
  return $omega_test_canvas;
};

// Same as Test.Canvas above but for various entities
// which can be rendered to the canvas
Omega.Test.Canvas.Entities = function(){
  if(typeof($omega_test_canvas_entities) === "undefined"){
    $omega_test_canvas_entities = {
      star   : new Omega.Star(),
      planet : new Omega.Planet()
    };
    var page     = Omega.Test.Page();
    var config   = page.config;
    var event_cb = function(){};
    for(var e in $omega_test_canvas_entities)
      $omega_test_canvas_entities[e].init_gfx(config, event_cb);
  }
  return $omega_test_canvas_entities;
};

//////////////////////////////// test hooks

//function before_all(details){
//}

//function before_each(details){
//}

//function after_each(details){
//}

//function after_all(details){
//}

//QUnit.moduleStart(before_all);
//QUnit.testStart(before_each);
//QUnit.testDone(after_each);
//QUnit.moduleDone(after_all);

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
    ok(handlers == null || handlers[evnt].length == 0, message);
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
  }
})

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
         }, 'func_eval');
};
