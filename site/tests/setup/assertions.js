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

  isNumeric : function(actual, message){
    ok(typeof(actual) === "number", message);
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
});
