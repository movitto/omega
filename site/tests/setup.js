// Test helper

// NIY = Not Implemented Yet
// Specs will fails if stubbed out but not implemented, so
// tests commented out but marked w/ 'NIY' should be implemented later

//////////////////////////////// helper methods

function disable_three_js(){
  // disable three by overloading UIResources().cached
  $old_ui_resources_cached = UIResources().cached;
  UIResources().cached = function(id){ return null ;}
}

function reenable_three_js(){
  if(typeof($old_ui_resources_cached) !== "undefined")
    UIResources().cached = $old_ui_resources_cached;
}

function create_mouse_event(evnt){
  // https://developer.mozilla.org/en-US/docs/Web/API/event.initMouseEvent
  var evnt = document.createEvent("MouseEvents");
  evnt.initMouseEvent(evnt, true, false, window,
                            1, 50, 50, 50, 50,
                            false, false, false, false, 0, null)
  return evnt;
}

// wait until scene animation
function on_animation(scene, cb){
  scene.old_render = scene.render;
  scene.render = function(){
    scene.old_render;
    cb.apply(null, [scene]);
  }
}

// remove generated dialogs, will get recreated with next qunit-fixture
function remove_dialogs(){
  $('#omega_dialog').dialog('destroy')
  $('#omega_dialog').remove();
}

//////////////////////////////// test data

function TestEntity(args){
  $.extend(this, new Entity(args));
  $.extend(this, new CanvasComponent(args));

  this._children = [];

  this.children = function(){
    return this._children;
  }
}

// Extend node, stub out 'invoke' methods on rjr nodes
// so as to not actually perform remote json-rpc calls
function TestNode(args){
  $.extend(this, new Node(args));

  this.rjr_web_node.invoke = sinon.stub()
  this.rjr_ws_node.invoke  = sinon.stub()
  this.rjr_ws_node.open = sinon.stub();
}


//////////////////////////////// test hooks

//function before_all(details){
//}

//function before_each(details){
//}

function after_each(details){
  Entities().clear();
  UIResources().clear_callbacks();
  reenable_three_js();
  remove_dialogs();
}

//function after_all(details){
//}

//QUnit.moduleStart(before_all);
//QUnit.testStart(before_each);
QUnit.testDone(after_each);
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
  }
});

pavlov.specify.extendAssertions({
  isGreaterThan: function(actual, expected, message) {
    ok(actual > expected, message);
  },
  isTypeOf: function(actual, expected, message) {
    ok(typeof(actual) === expected ||
       actual.constructor === expected, message);
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
  empty: function(array, message) {
    ok(array.length == 0, message)
  },
  notEmpty: function(array, message) {
    ok(array.length != 0, message)
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
