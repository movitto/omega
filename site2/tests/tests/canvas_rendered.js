require("javascripts/omega/canvas.js");

$(document).ready(function(){

  module("canvas.js");

  test("show grid", function(){
    $omega_scene = setup_canvas();

    $omega_grid = new OmegaGrid();
    $omega_grid.show();
    equal($omega_scene.scene_objects().length, 1);

    $omega_grid.hide();
    equal($omega_scene.scene_objects().length, 0);
  });

  test("rotate camera", function(){
    $omega_scene = setup_canvas();
    $omega_camera = new OmegaCamera();
    var old_pos = $omega_camera.position();
    $omega_camera.rotate(0.0, 0.2);
    // need better test of new camera position
    ok($omega_camera.position() != old_pos);

    old_pos = $omega_camera.position();
    $omega_camera.rotate(0.2, 0.0);
    ok($omega_camera.position() != old_pos);
  });

  test("zoom camera", function(){
    $omega_scene = setup_canvas();
    var old_pos = $omega_camera.position();
    $omega_camera.zoom(20);
    ok($omega_camera.position() != old_pos);
  });

  test("canvas rotate controls", function(){
    $omega_scene = setup_canvas();
    var old_pos = $omega_camera.position();
    $("#cam_rotate_right").trigger("click");
    ok($omega_camera.position() != old_pos);

    old_pos = $omega_camera.position();
    $("#cam_rotate_left").trigger("click");
    ok($omega_camera.position() != old_pos);

    old_pos = $omega_camera.position();
    $("#cam_rotate_up").trigger("click");
    ok($omega_camera.position() != old_pos);

    old_pos = $omega_camera.position();
    $("#cam_rotate_down").trigger("click");
    ok($omega_camera.position() != old_pos);
  });

  test("canvas zoom controls", function(){
    $omega_scene = setup_canvas();
    var old_pos = $omega_camera.position();
    $("#cam_zoom_out").trigger("click");
    ok($omega_camera.position() != old_pos);

    old_pos = $omega_camera.position();
    $("#cam_zoom_in").trigger("click");
    ok($omega_camera.position() != old_pos);
  });

  // TODO test select box

  module("entity.js");

  test("load system", function(){
    $omega_scene = setup_canvas();

    var system = new OmegaSolarSystem({name       : 'system1',
                                       location   : { x : 10, y : 20, z : -30}});
    system.load();

    // test scene_objs have been added to system

    equal(system.scene_objs.length, 2);
    equal(system.scene_objs[0].omega_id, system.name + "-sphere");
    // TODO should also:
    //equal(typeof system.scene_objs[0], THREE.Mesh);
    //equal(typeof system.scene_objs[0].geometry, THREE.SphereGeometry);
    equal(system.scene_objs[0].position.x, 10);
    equal(system.scene_objs[0].position.y, 20);
    equal(system.scene_objs[0].position.z, -30);

    equal(system.scene_objs[1].omega_id, system.name + "-text");
    equal(system.scene_objs[1].position.x, 10 - 50);
    equal(system.scene_objs[1].position.y, 20 - 50);
    equal(system.scene_objs[1].position.z, -30 - 50);

    // test scene_objs are rendered to scene
    equal($omega_scene.scene_objects().length, 2)
    equal($omega_scene.scene_objects()[0].omega_id, system.name + "-sphere");
    equal($omega_scene.scene_objects()[0].position.x, 10);
    equal($omega_scene.scene_objects()[0].position.y, 20);
    equal($omega_scene.scene_objects()[0].position.z, -30);

    equal($omega_scene.scene_objects()[1].omega_id, system.name + "-text");
    equal($omega_scene.scene_objects()[1].position.x, 10 - 50);
    equal($omega_scene.scene_objects()[1].position.y, 20 - 50);
    equal($omega_scene.scene_objects()[1].position.z, -30 - 50);
  });

  asyncTest("system clicked", function(){
    $omega_scene = setup_canvas();

    var system = new OmegaSolarSystem({name       : 'system1',
                                       location   : { x : 10, y : 20, z : -30}});
    $omega_registry.add(system);
    $omega_scene.add_entity(system);

    // need to animate scene and wait till its ready
    $omega_scene.animate();
    window.setTimeout(function() {

      var c = canvas_to_xy(system.scene_objs[0].position);
      var e = new jQuery.Event('click');
      e.pageX = c.x;
      e.pageY = c.y;

      $("#omega_canvas").trigger(e);

      // ensure dialog hidden
      //equal($('#omega_dialog').parent().css('display'), "none");

      // ensure scene root set
      equal($omega_scene.get_root().name, system.name)
      start();
    }, 250);
  });

  test("load star", function(){
    $omega_scene = setup_canvas();

    var star = new OmegaStar({name     : 'star1', color: 'ABABAB',
                              location : { x : 10, y : 0, z : -10}});
    star.load();

    // test scene_objs have been added to star

    equal(star.scene_objs.length, 1);
    equal(star.scene_objs[0].omega_id, star.name + "-sphere");
    equal(star.scene_objs[0].material.color.getHex().toString(16), 'ababab');
    equal(star.scene_objs[0].position.x, 10);
    equal(star.scene_objs[0].position.y,  0);
    equal(star.scene_objs[0].position.z, -10);

    equal($omega_scene.scene_objects().length, 1)
    equal($omega_scene.scene_objects()[0].omega_id, star.name + "-sphere");
    equal($omega_scene.scene_objects()[0].position.x, 10);
    equal($omega_scene.scene_objects()[0].position.y,  0);
    equal($omega_scene.scene_objects()[0].position.z, -10);
  });

  test("load planet", function(){
    $omega_scene = setup_canvas();

    var planet = new OmegaPlanet({name     : 'planet1', color: '101010',
                                  location : new OmegaLocation({ x : 10, y : 0, z : -10,
                                    movement_strategy : { semi_latus_rectum : 30, eccentricity: 0.5,
                                                        direction_major_x : 1, direction_major_y : 0, direction_major_z : 0,
                                                        direction_minor_x : 0, direction_minor_y : 1, direction_minor_z : 0 } }),
                                  moons    : [{name : 'moon1',
                                               location : {x : -20, y : 20, z : -20}}]});
    planet.load();

    ok(planet.orbit.length > 0)

    // test scene_objs have been added to planet

    equal(planet.scene_objs.length, 4);
    equal(planet.scene_objs[0].omega_id, planet.name + "-sphere");
    equal(planet.scene_objs[0].material.color.getHex().toString(16), '101010');
    equal(planet.scene_objs[0].position.x, 10);
    equal(planet.scene_objs[0].position.y,  0);
    equal(planet.scene_objs[0].position.z, -10);

    // TODO test orbit line & geometry (indicies 1,2)

    equal(planet.scene_objs[3].omega_id, planet.moons[0].name + "-sphere");
    equal(planet.scene_objs[3].position.x, 10 - 20);
    equal(planet.scene_objs[3].position.y,  0 + 20);
    equal(planet.scene_objs[3].position.z, -10 - 20);

    equal($omega_scene.scene_objects().length, 3)
    equal($omega_scene.scene_objects()[0].omega_id, planet.name + "-sphere");
    equal($omega_scene.scene_objects()[0].position.x, 10);
    equal($omega_scene.scene_objects()[0].position.y,  0);
    equal($omega_scene.scene_objects()[0].position.z, -10);

    equal($omega_scene.scene_objects()[2].omega_id, planet.moons[0].name + "-sphere");
    equal($omega_scene.scene_objects()[2].position.x, 10 - 20);
    equal($omega_scene.scene_objects()[2].position.y,  0 + 20);
    equal($omega_scene.scene_objects()[2].position.z, -10 - 20);
  });

  // TODO test planet on_movement / move / cache_movement

  test("load asteroid", function(){
    $omega_scene = setup_canvas();

    var ast = new OmegaAsteroid({name     : 'ast1',
                                 location : { x : 10, y : 0, z : -10}});
    ast.load();

    // test scene_objs have been added to system

    equal(ast.scene_objs.length, 1);
    equal(ast.scene_objs[0].omega_id, ast.name + "-text");
    equal(ast.scene_objs[0].position.x, 10);
    equal(ast.scene_objs[0].position.y,  0);
    equal(ast.scene_objs[0].position.z, -10);

    equal($omega_scene.scene_objects().length, 1)
    equal($omega_scene.scene_objects()[0].omega_id, ast.name + "-text");
    equal($omega_scene.scene_objects()[0].position.x, 10);
    equal($omega_scene.scene_objects()[0].position.y,  0);
    equal($omega_scene.scene_objects()[0].position.z, -10);
  });

  asyncTest("clicked asteroid", function(){
    $omega_scene = setup_canvas();

    var ast = new OmegaAsteroid({name     : 'ast1',
                                 location : new OmegaLocation({ x : 50, y : 50, z : -30})});
    $omega_registry.add(ast);
    $omega_scene.add_entity(ast);

    // need to animate scene and wait till its ready
    $omega_scene.animate();
    window.setTimeout(function() {

      var pos = ast.scene_objs[0].position;
      var c = canvas_to_xy(pos);
      c.x += 10; c.y -= 10;
      var e = new jQuery.Event('click');
      e.pageX = c.x;
      e.pageY = c.y;

      $("#omega_canvas").trigger(e);

      equal($('#omega_entity_container').css('display'), 'block');
      ok($('#omega_entity_container').html().indexOf('Asteroid: ast1') != -1);
      // TODO also verify resources are retrieved

      start();
    }, 250);
  });

  test("load jump gate", function(){
    $omega_scene = setup_canvas();

    var jg = new OmegaJumpGate({endpoint : "sys2",
                                location : new OmegaLocation({ x : 50, y : 50, z : -10})});
                                 
    jg.load();

    // test scene_objs have been added to jump gate

    equal(jg.scene_objs.length, 3);
    equal(jg.scene_objs[0].position.x, 50);
    equal(jg.scene_objs[0].position.y, 50);
    equal(jg.scene_objs[0].position.z, -10);

    equal($omega_scene.scene_objects().length, 1)
    equal($omega_scene.scene_objects()[0].position.x, 50);
    equal($omega_scene.scene_objects()[0].position.y, 50);
    equal($omega_scene.scene_objects()[0].position.z, -10);
  });

  asyncTest("clicked jump gate", function(){
    $omega_scene = setup_canvas();

    var sys1 = new OmegaSolarSystem({id : 'sys1',
                                     location : new OmegaLocation({id : 42})});
    var jg = new OmegaJumpGate({id : "sys1-sys2", endpoint : "sys2",
                                location : new OmegaLocation({ x : 50, y : 50, z : -10, parent_id : 42})});
    $omega_registry.add(sys1);
    $omega_registry.add(jg);
    $omega_scene.set_root(sys1);
    $omega_scene.add_entity(jg);

    // need to animate scene and wait till its ready
    $omega_scene.animate();
    window.setTimeout(function() {

      var pos = jg.scene_objs[0].position;
      var c = canvas_to_xy(pos);
      var e = new jQuery.Event('click');
      e.pageX = c.x;
      e.pageY = c.y;
      $("#omega_canvas").trigger(e);

      // additional selection sphere
      var so = $omega_scene.scene_objects();
      equal(so.length, 2)
      equal(so[1].position.x, 50);
      equal(so[1].position.y, 50);
      equal(so[1].position.z, -10);

      equal($('#omega_entity_container').css('display'), 'block');
      ok($('#omega_entity_container').html().indexOf('Jump Gate to sys2') != -1);

      // test jg on_unselected
      $("#entity_container_close").trigger("click");
      equal($omega_scene.scene_objects().length, 1)

      start();
    }, 250);
  });

  test("load ship", function(){
    $omega_scene = setup_canvas();
    $user_id = 'rendered-user';

    var ship = new OmegaShip({id : "ship1", user_id : 'rendered-user',
                              location : new OmegaLocation({ x : 50, y : 50, z : -10})});
                                 
    ship.load();

    // test scene_objs have been added to jump gate

    equal(ship.scene_objs.length, 6);
    equal(ship.scene_objs[0].material.color.getHex().toString(16), "cc00");
    equal(ship.scene_objs[2].material.color.getHex().toString(16), "cc00");
    // ensure geometry's vertices are at the correct locations

    equal($omega_scene.scene_objects().length, 3)
    equal($omega_scene.scene_objects()[2].position.x, 50);
    equal($omega_scene.scene_objects()[2].position.y, 50);
    equal($omega_scene.scene_objects()[2].position.z, -10);
  });

  asyncTest("clicked ship", function(){
    $omega_scene = setup_canvas();
    $user_id = 'rendered-user';

    var sys1 = new OmegaSolarSystem({id : 'sys1',
                                     location : new OmegaLocation({id : 42})});
    var ship = new OmegaShip({id : "ship1", user_id : 'rendered-user', hp : 500, size: 20,
                              location : new OmegaLocation({ x : 50, y : 50, z : -10, parent_id : 42})});

    $omega_registry.add(sys1);
    $omega_registry.add(ship);
    $omega_scene.set_root(sys1);
    $omega_scene.add_entity(ship);

    // need to animate scene and wait till its ready
    $omega_scene.animate();
    window.setTimeout(function() {
      var pos = ship.scene_objs[4].position;
      var c = canvas_to_xy(pos);
      var e = new jQuery.Event('click');
      e.pageX = c.x;
      e.pageY = c.y;

      $("#omega_canvas").trigger(e);

      equal($('#omega_entity_container').css('display'), 'block');
      ok($('#omega_entity_container').html().indexOf('Ship: ship1') != -1);

      // ensure ship is 'selected' color
      equal(ship.scene_objs[0].material.color.getHex().toString(16), "ffff00");
      equal(ship.scene_objs[2].material.color.getHex().toString(16), "ffff00");

      // unselect ship
      $("#entity_container_close").trigger("click");

      // ensure ship is 'unselected' color
      equal(ship.scene_objs[0].material.color.getHex().toString(16), "cc00");
      equal(ship.scene_objs[2].material.color.getHex().toString(16), "cc00");

      start();
    }, 1000);
                                 
  });

  // TODO test ship docked, attacking, mining, movement

  test("load station", function(){
    $omega_scene = setup_canvas();
    $user_id = 'rendered-user';

    var station = new OmegaShip({id : "stat1", user_id : 'rendered-user',
                              location : new OmegaLocation({ x : 50, y : 50, z : -10})});
                                 
    station.load();

    // test scene_objs have been added to jump gate

    equal(station.scene_objs.length, 6);
    equal(station.scene_objs[0].material.color.getHex().toString(16), "cc00");
    equal(station.scene_objs[2].material.color.getHex().toString(16), "cc00");
    // ensure geometry's vertices are at the correct locations

    equal($omega_scene.scene_objects().length, 3)
    equal($omega_scene.scene_objects()[2].position.x, 50);
    equal($omega_scene.scene_objects()[2].position.y, 50);
    equal($omega_scene.scene_objects()[2].position.z, -10);
  });

  asyncTest("clicked station", function(){
    $omega_scene = setup_canvas();
    $user_id = 'rendered-user';

    var sys1 = new OmegaSolarSystem({id : 'sys1',
                                     location : new OmegaLocation({id : 42})});
    var station = new OmegaStation({id : "station1", user_id : 'rendered-user', size: 20,
                              location : new OmegaLocation({ x : 50, y : 50, z : -10, parent_id : 42})});

    $omega_registry.add(sys1);
    $omega_registry.add(station);
    $omega_scene.set_root(sys1);
    $omega_scene.add_entity(station);

    // need to animate scene and wait till its ready
    $omega_scene.animate();
    window.setTimeout(function() {
      var pos = station.scene_objs[4].position;
      var c = canvas_to_xy(pos);
      var e = new jQuery.Event('click');
      e.pageX = c.x;
      e.pageY = c.y;

      $("#omega_canvas").trigger(e);

      equal($('#omega_entity_container').css('display'), 'block');
      ok($('#omega_entity_container').html().indexOf('Station: station1') != -1);

      // ensure station is 'selected' color
      equal(station.scene_objs[0].material.color.getHex().toString(16), "ffff00");
      equal(station.scene_objs[2].material.color.getHex().toString(16), "ffff00");

      // unselect station
      $("#entity_container_close").trigger("click");

      // ensure station is 'unselected' color
      equal(station.scene_objs[0].material.color.getHex().toString(16), "cc");
      equal(station.scene_objs[2].material.color.getHex().toString(16), "cc");

      start();
    }, 1000);
                                 
  });

});
