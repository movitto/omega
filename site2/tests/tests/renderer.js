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

    scene.on_scene_change('scene_change_test', function(){
      changed_called = true;
    });
    scene.set_root(system);

    // ensure scene changed called was invoked
    equal(changed_called, true);

    // ensure root is set
    equal(scene.get_root().name, 'Athena');

    // ensure skybox background is set
    equal($omega_skybox.get_background(), 'foobar');

    // ensure entity container is hidden
    equal($('#omega_entity_container').css('display'), 'none');

    // ensure scene has child entities
    equal(Object.keys(scene.entities()).length, 2);
    equal(scene.has({ 'id' : 'planet1' }), true);
    equal(scene.has({ 'id' : 'planet2' }), false);

    // TODO test manu entities loaded from server

    // refresh scene, reensure tests
    changed_called = false;
    scene.refresh();
    equal(changed_called, true);
    equal(scene.get_root().name, 'Athena');
  });

  test("add/remove children", function() {
    var scene = setup_canvas();

    var added1_to_scene = false;
    var added2_to_scene = false;

    // TODO load system/children from fixtures
    var star1   = { 'id'         : 'star1',
                    'name'       : 'star1',
                    'load'       : function() {} };
    var planet1 = { 'id'         : 'planet1',
                    'name'       : 'planet1',
                    'load'       : function() {},
                    'added_to_scene' : function(){ added1_to_scene = true ; } };
    var system  = { 'id'         : 'Athena',
                    'name'       : 'Athena',
                    'background' : 'foobar',
                    'children'   : function(){ return [star1, planet1]; }
                  };
    var planet2 = { 'id'   : 'planet2',
                    'name' : 'planet2',
                    'load' : function() {},
                    'added_to_scene' : function(){ added2_to_scene = true ; } };


    scene.set_root(system);

    equal(Object.keys(scene.entities()).length, 2);
    equal(scene.has(planet2), false);
    equal(added1_to_scene, true);

    scene.add_entity(planet2);
    equal(Object.keys(scene.entities()).length, 3);
    equal(scene.has(planet2), true);

    // atm only children added through set_root have their 'added_to_scene' callback invoked
    equal(added2_to_scene, false);

    scene.remove(planet2.id);
    equal(Object.keys(scene.entities()).length, 2);
    equal(scene.has(planet2), false);
  });

  test("clear children", function() {
    var scene = setup_canvas();

    // TODO load system/children from fixtures
    var star1   = { 'id'         : 'star1',
                    'name'       : 'star1',
                    'load'       : function() {} };
    var system  = { 'id'         : 'Athena',
                    'name'       : 'Athena',
                    'background' : 'foobar',
                    'children'   : function(){ return [star1]; }
    scene.set_root(system);
    equal(Object.keys(scene.entities()).length, 1);

    scene.clear();
    equal(Object.keys(scene.entities()).length, 0);
  });

  // TODO test set_size

});
