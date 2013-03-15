require("javascripts/omega/canvas.js");

$(document).ready(function(){

  module("entity_container");
  
  test("modify entity container", function() {
    var entity_container = new OmegaEntityContainer();
    entity_container.show(['foo', 'bar']);
    equal($('#omega_entity_container').css('display'), 'block');

    var container_match = new RegExp('foo');
    ok(container_match.test($('#entity_container_contents').text()));

    container_match = new RegExp('bar');
    ok(container_match.test($('#entity_container_contents').text()));

    entity_container.append(['baz', 'money']);

    container_match = new RegExp('baz');
    ok(container_match.test($('#entity_container_contents').text()));

    container_match = new RegExp('money');
    ok(container_match.test($('#entity_container_contents').text()));

    var closed_called = false;
    entity_container.on_closed(function(){
      closed_called = true;
    });

    entity_container.hide();
    equal($('#omega_entity_container').css('display'), 'none');
    equal(closed_called, true);
  });

  test("click entity container close", function() {
    // XXX close click handler operates on $omega_entity_container global
    setup_canvas();

    $('#entity_container_close').click();
    equal($('#omega_entity_container').css('display'), 'none');
  });

  module("entities_container");

  test("hide all entities containers", function() {
    $("#locations_list").show();
    $("#entities_list").show();
    $("#missions_button").show();
    equal($("#locations_list").css('display'), 'block');
    equal($("#entities_list").css('display'),  'block');
    equal($("#missions_button").css('display'),  'block');

    var entities_container = new OmegaEntitiesContainer();
    entities_container.hide_all();
    equal($("#locations_list").css('display'), 'none');
    equal($("#entities_list").css('display'),  'none');
    equal($("#missions_button").css('display'),  'none');
  });
  
  test("modify entities container", function() {
    // TODO load entities from fixtures
    var galaxy = {
                   'name'       : 'Zeus',
                   'json_class' : 'Cosmos::Galaxy',
                   'children'   : function() { return []; }
                 };

    var ship = { id : 'ship1', json_class : 'Manufactured::Ship' };

    var mission = { id : 'mission1', json_class : 'Missions::Mission' };

    var entities_container = new OmegaEntitiesContainer();
    //equal($('#locations_list').css('display'), 'none');
    //equal($('#alliances_list').css('display'), 'none');
    //equal($('#entities_list').css('display'), 'none');
    //equal($('#missions_button').css('display'), 'none');

    entities_container.add_to_entities_container(galaxy);
    ok(/\s*<li name="Zeus".*>Zeus<\/li>\s*/.test($('#locations_list ul').html()))
    equal($('#locations_list').css('display'), 'block');

    entities_container.add_to_entities_container(ship);
    ok(/\s*<li name="ship1".*>ship1<\/li>\s*/.test($('#entities_list ul').html()))
    equal($('#entities_list').css('display'), 'block');

    // TODO test fleet and entity lists

    entities_container.add_to_entities_container(mission);
    equal($('#missions_button').css('display'), 'block');
  });

  test("click entities container", function() {
    // TODO load entities from fixtures
    var galaxy = {
                   'id'         : 'Zeus',
                   'name'       : 'Zeus',
                   'json_class' : 'Cosmos::Galaxy',
                   'children'   : function() { return []; }
                 };

    var system = { 'id'         : 'Athena',
                   'name'       : 'Athena',
                   'json_class' : 'Cosmos::SolarSystem',
                   'children'   : function() { return []; }
                 };

    var ship = { id : 'ship1', json_class : 'Manufactured::Ship',
                 system_name : system.name,
                 location : { x : 10, y : 10, z : 10} };

    // necessary intialization
    setup_canvas();
    $omega_registry.add(galaxy);
    $omega_registry.add(system);
    $omega_registry.add(ship);

    equal($omega_scene.get_root(), null);

    var entities_container = new OmegaEntitiesContainer();
    entities_container.add_to_entities_container(galaxy);
    entities_container.add_to_entities_container(ship);

    $('#locations_list ul li:first').click();
    equal($omega_scene.get_root().name, 'Zeus');

    $('#entities_list ul li:first').click();
    equal($omega_scene.get_root().name, 'Athena');
  });

  test("click missions button", function() {
    $user_id = 'mmorsi';
    setup_canvas();

    var mission = new OmegaMission({ id : 'mission1', title : 'mission1', json_class : 'Missions::Mission' });
    $omega_registry.add(mission);

    $('#missions_button').click();
    ok($('.ui-dialog #omega_dialog').html().indexOf('mission1') != -1);

    // TODO test unassigned, assigned to different user, assigned & victorious/failed, assigned and active
  });

  module("omega_canvas");

  test("show/hide canvas", function() {
    var omega_canvas = new OmegaCanvas();
    omega_canvas.hide();
    equal($('canvas').css('display'),              'none');
    equal($('.entities_container').css('display'), 'none');
    equal($('.canvas_button').css('display'),      'none');
    equal($('#camera_controls').css('display'),    'none');
    equal($('#axis_controls').css('display'),      'none');
    equal($('#close_canvas').css('display'),       'none');
    equal($('#show_canvas').css('display'),        'block');

    omega_canvas.show();
    equal($('canvas').css('display'),              'inline');
    equal($('#camera_controls').css('display'),    'block');
    equal($('#axis_controls').css('display'),      'block');
    equal($('#close_canvas').css('display'),       'block');
    equal($('#show_canvas').css('display'),        'none');
  });

  test("close button", function() {
    // XXX close click handler operates on $omega_canvas global
    setup_canvas();

    $('#close_canvas').click();
    equal($('canvas').css('display'),              'none');
    equal($('#close_canvas').css('display'),       'none');
    equal($('#show_canvas').css('display'),        'block');

    $('#show_canvas').click();
    equal($('canvas').css('display'),              'inline');
    equal($('#close_canvas').css('display'),       'block');
    equal($('#show_canvas').css('display'),        'none');
  });

  // TODO test on canvas resize, camera and scene are adjusted accordingly and
  //      on page resize, canvas resize

  // TODO test click canvas

  // verify on login entities owned by user retrieved & systems / galaxyes
  asyncTest("retrieve entities on login", function(){
    setup_canvas();

    var ships = $omega_registry.select([function(e){ return e.json_class == "Manufactured::Ship"; }]);
    equal(ships.length, 0);

    login_test_user($mmorsi_user, function(){
      // wait for entity / cosmos responses to be invoked/returned
      window.setTimeout(function() {
        ships = $omega_registry.select([function(e){ return e.json_class == "Manufactured::Ship"; }]);
        ok(ships.length > 0);
        for(var s in ships){
          var sys = $omega_registry.get(ships[s].system_name);
          ok(sys != null);
          var gal = $omega_registry.get(sys.galaxy_name);
          ok(gal != null);
        }
        start();
      }, 1000);
    });
  });

  // verify on login all missions accessible to user retrieved
  asyncTest("retrieve missions on login", function(){
    setup_canvas();

    var missions = $omega_registry.select([function(e){ return e.json_class == "Missions::Mission"; }]);
    equal(missions.length, 0);

    login_test_user($mmorsi_user, function(){
      // wait for entity / cosmos responses to be invoked/returned
      window.setTimeout(function() {
        missions = $omega_registry.select([function(e){ return e.json_class == "Missions::Mission"; }]);
        ok(missions.length > 1);
        // TODO ensure missions in seeder retrieved
        start();
      }, 1000);
    });
  });

  // verify on logout ui is cleaned up
  asyncTest("cleanup ui on logout", function(){
    $omega_scene = setup_canvas();

    var ast = new OmegaAsteroid({name     : 'ast1',
                                 location : new OmegaLocation({ x : 50, y : 50, z : -30})});
    $omega_scene.add_entity(ast);
    ok($omega_scene.scene_objects().length > 0)

    login_test_user($mmorsi_user, function(){
      // wait for entity / cosmos responses to be invoked/returned
      window.setTimeout(function() {

        logout_test_user(function(){
          equal($omega_scene.scene_objects().length, 0);
          equal($(".entities_container").css('display'), 'none');
          equal($('#omega_entity_container').css('display'), 'none');
          equal($omega_axis.is_showing(), false);
          equal($omega_grid.is_showing(), false);
          // TODO omega skybox.is_showing, omega_registry.has_timer('planet_movement')

          start();
        });
      }, 250);
    });
  });
});
