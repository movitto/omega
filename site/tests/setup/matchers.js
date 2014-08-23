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

