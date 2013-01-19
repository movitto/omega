require("javascripts/omega/renderer.js");
require("javascripts/omega/canvas.js");

$(document).ready(function(){

  module("omega_selection");
  
  test("select and unselect entity", 3, function() {
    var selection = new OmegaSelection();
    equal(selection.is_selected('foobar'), false);
    selection.select('foobar');
    equal(selection.is_selected('foobar'), true);
    selection.unselect('foobar');
    equal(selection.is_selected('foobar'), false);
  });

  module("omega_scene");

  test("scene change", function() {
    var scene = setup_canvas();

    // TODO load system/children from fixtures
    var star1   = { 'id'        : 'star1',
                    'name'      : 'star1',
                    'load'      : function() {} };
    var planet1 = { 'id'        : 'planet1',
                    'name'      : 'planet1',
                    'load'      : function() {} };

    var system  = { 'id'        : 'Athena',
                    'name'      : 'Athena',
                    'background': 'foobar',
                    'children'  : function(){ return [planet1, star1]; }
                  };

    var changed_called = false;

    scene.on_scene_change(function(){
      changed_called = true;
    });
    scene.set_root(system);

    // ensure scene changed called was invoked
    equal(changed_called, true);

    // ensure root is set
    equal(scene.get_root().name, 'Athena');

    // ensure canvas background is set
    equal($("#omega_canvas").css('backgroundImage'),
          'url("http://localhost/womega/images/backgrounds/foobar.png")');

    // ensure entity container is hidden
    equal($('#omega_entity_container').css('display'), 'none');

    // ensure scene has child entities
    equal(Object.keys(scene.entities()).length, 2);
    equal(scene.has({ 'id' : 'planet1' }), true);
    equal(scene.has({ 'id' : 'planet2' }), false);

    // refresh scene, reensure tests
    changed_called = false;
    scene.refresh();
    equal(changed_called, true);
    equal(scene.get_root().name, 'Athena');
  });

  test("add/remove children", function() {
    var scene = setup_canvas();

    // TODO test w/ callback on planet2
    var added_to_scene = false;

    // TODO load system/children from fixtures
    var star1   = { 'id'         : 'star1',
                    'name'       : 'star1',
                    'load'       : function() {} };
    var planet1 = { 'id'         : 'planet1',
                    'name'       : 'planet1',
                    'load'       : function() {} };
    var system  = { 'id'         : 'Athena',
                    'name'       : 'Athena',
                    'background' : 'foobar',
                    'children'   : function(){ return [star1, planet1]; }
                  };
    var planet2 = { 'id'   : 'planet2',
                    'name' : 'planet2',
                    'load' : function() {}};


    scene.set_root(system);

    equal(Object.keys(scene.entities()).length, 2);
    equal(scene.has(planet2), false);

    scene.add_entity(planet2);
    equal(Object.keys(scene.entities()).length, 3);
    equal(scene.has(planet2), true);

    scene.remove(planet2.id);
    equal(Object.keys(scene.entities()).length, 2);
    equal(scene.has(planet2), false);
  });

});
