//////////////////////////////// helper methods

function disable_three_js(){
  // disable three by overloading UIResources().cached
  $old_ui_resources_cached = UIResources().cached;
  UIResources().cached = function(id){ return null ;}
}

function reenable_three_js(){
  UIResources().cached = $old_ui_resources_cached;
}

//////////////////////////////// test hooks

//function before_all(details){
//}
//
//function before_each(details){
//}
//
//function after_each(details){
//}
//
//function after_all(details){
//}
//
//QUnit.moduleStart(before_all);
//QUnit.testStart(before_each);
//QUnit.testDone(after_each);
//QUnit.moduleDone(after_all);

//////////////////////////////// custom assertions

pavlov.specify.extendAssertions({
  isTypeOf: function(actual, expected, message) {
    ok(typeof(actual) === expected, message);
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
