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
