// Test helper

/// TODO rename to run.js

// NIY = Not Implemented Yet
// Specs will fails if stubbed out but not implemented, so
// tests commented out but marked w/ 'NIY' should be implemented later

//////////////////////////////// config/init

QUnit.config.autostart = false;

Omega.Test.init = function(){
  var current  = 0;
  var total    = 0;
  var entities = null;
  Omega.Gen.init(function(){
    entities = Omega.Test.Canvas.Entities(function(){
      current += 1;
      if(current == total)
        QUnit.start();
    });

    for(var e in entities)
      if(entities[e].async_gfx)
        total += entities[e].async_gfx;
  });
}

/// should be triggered after QUnit.load
$(window).on('load', Omega.Test.init);
