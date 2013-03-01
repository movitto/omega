require("javascripts/omega/canvas.js");

$(document).ready(function(){

  module("canvas.js");

  test("get/set skybox", function(){
    $omega_scene = setup_canvas();

    $omega_skybox = new OmegaSkybox();
    $omega_skybox.set_background({background : 'system1'});
    equal($omega_skybox.get_background(), 'system1');
  });

  test("show/hide skybox", function(){
    $omega_scene = setup_canvas();

    $omega_skybox = new OmegaSkybox();
    $omega_skybox.set_background({background : 'system1'});
    $omega_skybox.show();
    equal($omega_scene.scene_objects().length, 1);
    equal($omega_scene.scene_objects()[0].omega_id, "skybox-mesh");
    equal($omega_scene.scene_objects()[0].position.x, 0);
    equal($omega_scene.scene_objects()[0].position.y, 0);
    equal($omega_scene.scene_objects()[0].position.z, 0);
    // verify skybox mesh,geometry,materials ?

    $omega_skybox.hide();
    equal($omega_scene.scene_objects().length, 0);
  });

  test("show grid", function(){
    $omega_scene = setup_canvas();

    $omega_grid = new OmegaGrid();
    $omega_grid.show();
    equal($omega_scene.scene_objects().length, 1);
    equal($omega_scene.scene_objects()[0].omega_id, "grid-line");

    $omega_grid.hide();
    equal($omega_scene.scene_objects().length, 0);
  });

  test("toggle grid", function(){
    $omega_scene = setup_canvas();

    $omega_grid = new OmegaGrid();
    equal($omega_grid.is_showing(), false);
    equal($omega_scene.scene_objects().length, 0);

    $('#toggle_grid_canvas').attr('checked', true); // XXX not sure why this is needed
    $('#toggle_grid_canvas').trigger('click');
    equal($omega_grid.is_showing(), true);
    equal($omega_scene.scene_objects().length, 1);
    equal($omega_scene.scene_objects()[0].omega_id, "grid-line");

    $('#toggle_grid_canvas').trigger('click');
    equal($omega_grid.is_showing(), false);
    equal($omega_scene.scene_objects().length, 0);
  });

  test("show axis", function(){
    $omega_scene = setup_canvas();

    $omega_axis = new OmegaAxis();
    $omega_axis.show();
    equal($omega_axis.is_showing(), true);
    equal($omega_scene.scene_objects().length, $omega_axis.num_markers + 1);
    equal($omega_scene.scene_objects()[0].omega_id, "axis-line");
    for(var i = 0; i < $omega_axis.num_markers; i++)
      equal($omega_scene.scene_objects()[i+1].omega_id, "distance-marker-" + i);

    $omega_axis.hide();
    equal($omega_axis.is_showing(), false);
    equal($omega_scene.scene_objects().length, 0);
  });

  test("toggle axis", function(){
    $omega_scene = setup_canvas();

    $omega_axis = new OmegaAxis();
    equal($omega_axis.is_showing(), false);
    equal($omega_scene.scene_objects().length, 0);

    $('#toggle_axis_canvas').attr('checked', true); // XXX not sure why this is needed
    $('#toggle_axis_canvas').trigger('click');
    equal($omega_axis.is_showing(), true);
    equal($omega_scene.scene_objects().length, $omega_axis.num_markers + 1);
    equal($omega_scene.scene_objects()[0].omega_id, "axis-line");
    for(var i = 0; i < $omega_axis.num_markers; i++)
      equal($omega_scene.scene_objects()[i+1].omega_id, "distance-marker-" + i);

    $('#toggle_axis_canvas').trigger('click');
    equal($omega_axis.is_showing(), false);
    equal($omega_scene.scene_objects().length, 0);
  });

  test("reset camera", function(){
    $omega_scene = setup_canvas();
    $omega_camera = new OmegaCamera();
    var pos = $omega_camera.position({x : 100, y : -200, z : 300});
    equal(pos.x,  100);
    equal(pos.y, -200);
    equal(pos.z,  300);

    $omega_camera.reset();
    var pos = $omega_camera.position();
    equal(pos.x,  0);
    equal(pos.y,  0);
    equal(pos.z,  1000);
  });

  test("focus camera", function(){
    $omega_scene = setup_canvas();
    $omega_camera = new OmegaCamera();
    var focus = $omega_camera.focus();
    var pos = $omega_scene.position();
    equal(focus.x, pos.x);
    equal(focus.y, pos.y);
    equal(focus.z, pos.z);

    var focus = $omega_camera.focus({x: 100, y : -200});
    equal(focus.x,  100);
    equal(focus.y, -200);
    equal(focus.z, pos.z);
  });

  test("rotate camera", function(){
    $omega_scene = setup_canvas();
    $omega_camera = new OmegaCamera();
    var old_pos = $omega_camera.position();
    $omega_camera.rotate(0.0, 0.2);
    var npos    = $omega_camera.position();
    // need better test of new camera position
    ok(npos.x != old_pos.x);
    ok(npos.y != old_pos.y);
    ok(npos.z != old_pos.z);
    // TODO also ensure that we're focusing in the same direction

    old_pos = $omega_camera.position();
    $omega_camera.rotate(0.2, 0.0);
    var npos= $omega_camera.position();
    ok(npos.x != old_pos.x);
    ok(npos.y != old_pos.y);
    ok(npos.z != old_pos.z);
  });

  test("zoom camera", function(){
    $omega_scene = setup_canvas();
    var old_pos = $omega_camera.position();
    $omega_camera.zoom(20);
    var npos= $omega_camera.position();
    ok(npos.y != old_pos.y);
    ok(npos.z != old_pos.z);
  });

  test("pan camera", function(){
    $omega_scene = setup_canvas();
    var old_pos = $omega_camera.position();
    $omega_camera.pan(20, 30);
    var npos= $omega_camera.position();
    ok(npos.x != old_pos.x);
    ok(npos.y != old_pos.y);

    $omega_camera.position({x : 0, y : 0, z : 1000});
    $omega_camera.focus({x : 0, y : 0, z : 0});
    $omega_camera.pan(20, -20)
    npos = $omega_camera.position();
    equal(npos.x,   20);
    equal(npos.y,  -20);
    equal(npos.z, 1000);
  });

  test("canvas rotate controls", function(){
    $omega_scene = setup_canvas();
    var old_pos = $omega_camera.position();
    $("#cam_rotate_right").trigger("click");
    var npos = $omega_camera.position();
    ok(npos.x != old_pos.x);
    ok(npos.y != old_pos.y);
    ok(npos.z != old_pos.z);

    $omega_camera.reset();
    $("#cam_rotate_left").trigger("click");
    npos = $omega_camera.position();
    ok(npos.x != old_pos.x);
    ok(npos.y != old_pos.y);
    ok(npos.z != old_pos.z);

    $omega_camera.reset();
    $("#cam_rotate_up").trigger("click");
    npos = $omega_camera.position();
    //ok(npos.x != old_pos.x);
    ok(npos.y != old_pos.y);
    ok(npos.z != old_pos.z);

    $omega_camera.reset();
    $("#cam_rotate_down").trigger("click");
    npos = $omega_camera.position();
    //ok(npos.x != old_pos.x);
    ok(npos.y != old_pos.y);
    ok(npos.z != old_pos.z);
  });

  test("canvas zoom controls", function(){
    $omega_scene = setup_canvas();
    var old_pos = $omega_camera.position();
    $("#cam_zoom_out").trigger("click");
    var npos = $omega_camera.position();
    ok(npos.y != old_pos.y);
    ok(npos.z != old_pos.z);

    old_pos = $omega_camera.position();
    $("#cam_zoom_in").trigger("click");
    npos = $omega_camera.position();
    ok(npos.y != old_pos.y);
    ok(npos.z != old_pos.z);
  });

  test("canvas pan controls", function(){
    $omega_scene = setup_canvas();
    var old_pos = $omega_camera.position();
    $("#cam_pan_right").trigger("click");
    ok($omega_camera.position().x != old_pos.x);

    old_pos = $omega_camera.position();
    $("#cam_pan_up").trigger("click");
    ok($omega_camera.position().y != old_pos.y);

    var old_pos = $omega_camera.position();
    $("#cam_pan_left").trigger("click");
    ok($omega_camera.position().x != old_pos.x);

    old_pos = $omega_camera.position();
    $("#cam_pan_down").trigger("click");
    ok($omega_camera.position().y != old_pos.y);
  });

  test("camera reset control", function(){
    $omega_scene = setup_canvas();
    $omega_camera = new OmegaCamera();
    var pos = $omega_camera.position({x : 100, y : -200, z : 300});
    equal(pos.x,  100);
    equal(pos.y, -200);
    equal(pos.z,  300);

    $("#cam_reset").trigger("click");
    var pos = $omega_camera.position();
    equal(pos.x,  0);
    equal(pos.y,  0);
    equal(pos.z,  1000);
  });

  // TODO test select box

  module("entity.js");

  test("load system", function(){
    $omega_scene = setup_canvas();

    var system = new OmegaSolarSystem({name       : 'system1',
                                       location   : { x : 10, y : 20, z : -30}});
    system.load();

    // test scene_objs have been added to system

    equal(system.scene_objs.length, 3);
    equal(system.scene_objs[0].omega_id, system.name + "-sphere");
    // TODO should also:
    //equal(typeof system.scene_objs[0], THREE.Mesh);
    //equal(typeof system.scene_objs[0].geometry, THREE.SphereGeometry);
    equal(system.scene_objs[0].position.x, 10);
    equal(system.scene_objs[0].position.y, 20);
    equal(system.scene_objs[0].position.z, -30);

    equal(system.scene_objs[1].omega_id, system.name + "-plane");
    equal(system.scene_objs[1].position.x, 10);
    equal(system.scene_objs[1].position.y, 20);
    equal(system.scene_objs[1].position.z, -30);

    equal(system.scene_objs[2].omega_id, system.name + "-text");
    equal(system.scene_objs[2].position.x, 10);
    equal(system.scene_objs[2].position.y, 20);
    equal(system.scene_objs[2].position.z, -30 + 50);

    // test scene_objs are rendered to scene
    equal($omega_scene.scene_objects().length, 3)
    equal($omega_scene.scene_objects()[0].omega_id, system.name + "-sphere");
    equal($omega_scene.scene_objects()[0].position.x, 10);
    equal($omega_scene.scene_objects()[0].position.y, 20);
    equal($omega_scene.scene_objects()[0].position.z, -30);

    equal($omega_scene.scene_objects()[1].omega_id, system.name + "-plane");
    equal($omega_scene.scene_objects()[1].position.x, 10);
    equal($omega_scene.scene_objects()[1].position.y, 20);
    equal($omega_scene.scene_objects()[1].position.z, -30);

    equal($omega_scene.scene_objects()[2].omega_id, system.name + "-text");
    equal($omega_scene.scene_objects()[2].position.x, 10);
    equal($omega_scene.scene_objects()[2].position.y, 20);
    equal($omega_scene.scene_objects()[2].position.z, -30 + 50);
  });

  test("load system jump gates", function(){
    $omega_scene = setup_canvas();

    var system1 = new OmegaSolarSystem({id : 'system1', name       : 'system1',
                                        location   : { x : -10, y : -20, z :  30}});
    var system2 = new OmegaSolarSystem({id : 'system2', name       : 'system2',
                                        location   : { x :  10, y :  20, z : -30},
                                        jump_gates : [{endpoint : 'system1' }]});
    $omega_registry.add(system1);
    $omega_registry.add(system2);

    system2.load();

    equal(system2.scene_objs.length, 4);
    equal(system2.scene_objs[0].omega_id, 'system2-system1');
    equal(system2.scene_objs[0].geometry.vertices[0].x, system2.location.x);
    equal(system2.scene_objs[0].geometry.vertices[0].y, system2.location.y);
    equal(system2.scene_objs[0].geometry.vertices[0].z, system2.location.z);
    equal(system2.scene_objs[0].geometry.vertices[1].x, system1.location.x);
    equal(system2.scene_objs[0].geometry.vertices[1].y, system1.location.y);
    equal(system2.scene_objs[0].geometry.vertices[1].z, system1.location.z);

    equal($omega_scene.scene_objects().length, 4);
    equal($omega_scene.scene_objects()[0].omega_id, 'system2-system1');
  });

  asyncTest("system clicked", function(){
    $omega_scene = setup_canvas();

    var system = new OmegaSolarSystem({id         : 'system1',
                                       name       : 'system1',
                                       location   : { x : 10, y : 20, z : -30}});
    var galaxy = new OmegaGalaxy({name : 'galaxy1', solar_systems : [system] });
    $omega_registry.add(system);
    $omega_scene.set_root(galaxy);

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
      equal($omega_scene.get_root().name, system.name);
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

  asyncTest("planet added to scene", 2, function(){
    $omega_scene = setup_canvas();
    var planet = new OmegaPlanet({id : 'Xeno', name     : 'Xeno', color: '101010',
                                  location : new OmegaLocation({ id: 8, x : 10, y : 0, z : -10,
                                    movement_strategy : { semi_latus_rectum : 30, eccentricity: 0.5,
                                                          direction_major_x : 1, direction_major_y : 0, direction_major_z : 0,
                                                          direction_minor_x : 0, direction_minor_y : 1, direction_minor_z : 0 } })});
    var system = new OmegaSolarSystem({id : 'Athena', name       : 'Athena',
                                       location   : { id: 6, x : 10, y : 20, z : -30},
                                       planets  : [planet] });

    $omega_registry.add(system);
    $omega_registry.add(planet);

    // so we can be sure of difference below
    equal($omega_registry.get('Xeno').location.parent_id, null);

    $omega_scene.set_root(system);

    // ensure added_to_scene callback is invoked, for now
    // this just ensures location is updated from server
    window.setTimeout(function() {
      equal($omega_registry.get('Xeno').location.parent_id, 6);
      start();
    }, 250);
  });

  // TODO test planet on_movement / move / cache_movement

  test("load asteroid", function(){
    $omega_scene = setup_canvas();

    var ast = new OmegaAsteroid({name     : 'ast1',
                                 location : { x : 10, y : 0, z : -10}});
    ast.load();

    // test scene_objs have been added to system

    equal(ast.scene_objs.length, 2);
    equal(ast.scene_objs[0].omega_id, ast.name + "-mesh");
    equal(ast.scene_objs[0].position.x, 10);
    equal(ast.scene_objs[0].position.y,  0);
    equal(ast.scene_objs[0].position.z, -10);

    equal(ast.scene_objs[1].omega_id, ast.name + "-sphere");
    equal(ast.scene_objs[1].position.x, 10);
    equal(ast.scene_objs[1].position.y,  0);
    equal(ast.scene_objs[1].position.z, -10);

    equal($omega_scene.scene_objects().length, 2)
    equal($omega_scene.scene_objects()[0].omega_id, ast.name + "-mesh");
    equal($omega_scene.scene_objects()[0].position.x, 10);
    equal($omega_scene.scene_objects()[0].position.y,  0);
    equal($omega_scene.scene_objects()[0].position.z, -10);

    equal($omega_scene.scene_objects()[1].omega_id, ast.name + "-sphere");
    equal($omega_scene.scene_objects()[1].position.x, 10);
    equal($omega_scene.scene_objects()[1].position.y,  0);
    equal($omega_scene.scene_objects()[1].position.z, -10);
  });

  asyncTest("clicked asteroid", function(){
    $omega_scene = setup_canvas();

    // XXX need to wait till asteroid geometry is loaded
    window.setTimeout(function() {
      var ast = new OmegaAsteroid({name     : 'ast1',
                                   location : new OmegaLocation({ x : 50, y : 50, z : -30})});
      var system = new OmegaSolarSystem({name       : 'system1',
                                         location   : { x : 10, y : 20, z : -30},
                                         asteroids  : [ast] });
      $omega_scene.set_root(system);

      // need to animate scene and wait till its ready
      $omega_scene.animate();
      window.setTimeout(function() {

        var pos = ast.scene_objs[0].position;
        var c = canvas_to_xy(pos);
        var e = new jQuery.Event('click');
        e.pageX = c.x;
        e.pageY = c.y;

        $("#omega_canvas").trigger(e);

        equal($('#omega_entity_container').css('display'), 'block');
        ok($('#omega_entity_container').html().indexOf('Asteroid: ast1') != -1);
        // TODO also verify resources are retrieved

        start();
      }, 250);
    }, 250);
  });

  test("load jump gate", function(){
    $omega_scene = setup_canvas();

    var jg = new OmegaJumpGate({endpoint : "sys2",
                                location : new OmegaLocation({ x : 50, y : 50, z : -10})});
                                 
    jg.load();

    // test scene_objs have been added to jump gate

    equal(jg.scene_objs.length, 2);
    equal(jg.scene_objs[0].omega_id, jg.id + "-mesh");
    equal(jg.scene_objs[0].position.x, 50);
    equal(jg.scene_objs[0].position.y, 50);
    equal(jg.scene_objs[0].position.z, -10);
    equal(jg.scene_objs[1].omega_id, jg.id + "-sphere");
    equal(jg.scene_objs[1].position.x, 50);
    equal(jg.scene_objs[1].position.y, 50);
    equal(jg.scene_objs[1].position.z, -10);

    equal($omega_scene.scene_objects().length, 1)
    equal($omega_scene.scene_objects()[0].omega_id, jg.id + "-mesh");
    equal($omega_scene.scene_objects()[0].position.x, 50);
    equal($omega_scene.scene_objects()[0].position.y, 50);
    equal($omega_scene.scene_objects()[0].position.z, -10);
  });

  asyncTest("clicked jump gate", function(){
    $omega_scene = setup_canvas();

    // XXX need to wait till jump gate geometry is loaded
    window.setTimeout(function() {
      var jg = new OmegaJumpGate({id : "sys1-sys2", endpoint : "sys2",
                                  location : new OmegaLocation({ x : 50, y : 50, z : -10, parent_id : 42})});
      var sys1 = new OmegaSolarSystem({id : 'sys1',
                                       location : new OmegaLocation({id : 42}),
                                       jump_gates : [jg] });
      $omega_registry.add(jg);
      $omega_scene.set_root(sys1);
      $omega_skybox.hide();

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
    }, 250);
  });

  test("load ship", function(){
    $omega_scene = setup_canvas();
    $user_id = 'rendered-user';

    var ship = new OmegaShip({id : "ship1", user_id : 'rendered-user',
                              location : new OmegaLocation({ x : 50, y : 50, z : -10})});
                                 
    ship.load();

    // test scene_objs have been added to ship

    equal(ship.scene_objs.length, 1);
    equal(ship.scene_objs[0].material.color.getHex().toString(16), "cc00");
    equal(ship.scene_objs[0].omega_id, "ship1-mesh");
    // verify ship mesh's geometry ?

    equal($omega_scene.scene_objects().length, 1)
    equal($omega_scene.scene_objects()[0].omega_id, "ship1-mesh");
    equal($omega_scene.scene_objects()[0].position.x, 50);
    equal($omega_scene.scene_objects()[0].position.y, 50);
    equal($omega_scene.scene_objects()[0].position.z, -10);
  });

  asyncTest("ship added to scene", 4, function(){
    //$user_id = 'mmorsi';
    $omega_scene = setup_canvas();
    var ship = new OmegaShip({id : 'mmorsi-mining-ship1', system_name : 'Athena', json_class : 'Manufactured::Ship',
                              location : new OmegaLocation({ id: 17 } )});;
    var system = new OmegaSolarSystem({id : 'Athena', name       : 'Athena',
                                       location   : { id: 2 }});

    $omega_registry.add(system);
    $omega_registry.add(ship);

    // so we can be sure of difference below
    equal($omega_registry.get('mmorsi-mining-ship1').location.parent_id, null);

    // login test user so as to be able to query for manufactured entities
    login_test_user($admin_user, function(){
      $omega_scene.set_root(system);

      // ensure entity will be picked up by motel::on_movement handler
      var entity   = null;
      var children = $omega_scene.get_root().children();
      for(var child in children){
        if(children[child].id == 'mmorsi-mining-ship1'){
          entity = children[child];
          break;
        }
      }
      ok(entity != null);

      // ensure added_to_scene callback is invoked, for now
      // this just ensures entity/location is updated from server
      // and we've subscribed to location updates
      window.setTimeout(function() {
        equal($omega_registry.get('mmorsi-mining-ship1').location.parent_id, 2);
        equal($omega_node.has_request_handler('motel::on_movement'), true)
        start();
      }, 250);
    });
  });

  asyncTest("clicked ship", function(){
    $omega_scene = setup_canvas();
    $user_id = 'rendered-user';

    // XXX need to wait till ship geometry is loaded
    window.setTimeout(function() {
      var sys1 = new OmegaSolarSystem({id : 'sys1', name : 'sys1',
                                       location : new OmegaLocation({id : 42})});
      var ship = new OmegaShip({id : "ship1", user_id : 'rendered-user', hp : 500, size: 20,
                                system_name : 'sys1', json_class : "Manufactured::Ship",
                                location : new OmegaLocation({ x : 50, y : 50, z : -10, parent_id : 42})});

      $omega_registry.add(sys1);
      $omega_registry.add(ship);
      $omega_scene.set_root(sys1);

      // need to animate scene and wait till its ready
      $omega_scene.animate();
      window.setTimeout(function() {
        var pos = ship.scene_objs[0].position;
        var c = canvas_to_xy(pos);
        var e = new jQuery.Event('click');
        e.pageX = c.x;
        e.pageY = c.y;

        $("#omega_canvas").trigger(e);

        equal($('#omega_entity_container').css('display'), 'block');
        ok($('#omega_entity_container').html().indexOf('Ship: ship1') != -1);

        // ensure ship is 'selected' color
        equal(ship.scene_objs[0].material.color.getHex().toString(16), "ffff00");

        // unselect ship
        $("#entity_container_close").trigger("click");

        // ensure ship is 'unselected' color
        equal(ship.scene_objs[0].material.color.getHex().toString(16), "cc00");

        start();
      }, 1000);
    }, 250);
                                 
  });

  asyncTest("load docked ship", function(){
    $omega_scene = setup_canvas();

    // create new system / set root location
    var nsys = new OmegaSolarSystem({name : 'Athena',
                                     location : {id : 2}});
    $omega_registry.add(nsys);
    $omega_scene.set_root(nsys);

    login_test_user($admin_user, function(){
      OmegaQuery.entity_with_id('mmorsi-corvette-ship3', function(ship){
        OmegaCommand.dock_ship.exec(ship, 'mmorsi-manufacturing-station1');
        OmegaQuery.entity_with_id('mmorsi-corvette-ship3', function(ship){
          $omega_scene.reload(ship);
          equal(ship.scene_objs.length, 1);
          equal(ship.scene_objs[0].material.color.getHex().toString(16), "99ffff");

          OmegaCommand.undock_ship.exec(ship);
          OmegaQuery.entity_with_id('mmorsi-corvette-ship3', function(ship){
            $omega_scene.reload(ship);
            equal(ship.scene_objs.length, 1);
            equal(ship.scene_objs[0].material.color.getHex().toString(16), "cc0000");
            start();
          });
        });
      });
    });
  });

  asyncTest("load moving ship", function(){
    $omega_scene = setup_canvas();

    // create new system / set root location
    var nsys = new OmegaSolarSystem({name : 'Athena',
                                     location : {id : 2}});
    $omega_registry.add(nsys);
    $omega_scene.set_root(nsys);
    $omega_skybox.hide();

    login_test_user($admin_user, function(){
      OmegaQuery.entity_with_id('mmorsi-corvette-ship2', function(ship){
        OmegaCommand.move_ship.exec(ship, ship.location.x + 50, ship.location.y + 50, ship.location.z + 50);
        OmegaQuery.entity_with_id('mmorsi-corvette-ship2', function(ship){
          $omega_scene.reload(ship);
          equal(ship.location.movement_strategy.json_class, "Motel::MovementStrategies::Linear");

          equal($omega_scene.scene_objects()[0].position.x, ship.location.x);
          equal($omega_scene.scene_objects()[0].position.y, ship.location.y);
          equal($omega_scene.scene_objects()[0].position.z, ship.location.z);
          var oposx = ship.location.x, oposy = ship.location.y, oposz = ship.location.z;

          // wait a few seconds / get updated ship & ensure it moved
          window.setTimeout(function() {
            OmegaQuery.entity_with_id('mmorsi-corvette-ship2', function(nship){
              $omega_scene.reload(nship);
              ok($omega_scene.scene_objects()[0].position.x > oposx);
              ok($omega_scene.scene_objects()[0].position.y > oposy);
              ok($omega_scene.scene_objects()[0].position.z > oposz);
              start();
            });
          }, 1000);
        });
      });
    });
  });

  asyncTest("load attacking ship", function() {
    $omega_scene = setup_canvas();

    // TODO load ships from fixtures
    var new_ship1_id = 'mmorsi-ship-' + guid();
    var new_ship1 = new JRObject('Manufactured::Ship', {
                      'id'         : new_ship1_id,
                      'type'       : 'corvette',
                      'user_id'    : 'mmorsi',
                      'system_name': 'Athena',
                      'location'   : new JRObject("Motel::Location",
                                                  {'x' : -140, 'y' : -140, 'z' : -140})
                    });

    var new_ship2_id = 'opponent-ship-' + guid();
    var new_ship2 = new JRObject('Manufactured::Ship', {
                      'id'         : new_ship2_id,
                      'type'       : 'corvette',
                      'user_id'    : 'opponent',
                      'system_name': 'Athena',
                      'location'   : new JRObject("Motel::Location",
                                                  {'x' : -140, 'y' : -140, 'z' : -140})
                    });

    // create new system / set root location
    var nsys = new OmegaSolarSystem({name : 'Athena',
                                     location : {id : 2}});
    $omega_registry.add(nsys);
    $omega_scene.set_root(nsys);
    $omega_skybox.hide();

    login_test_user($admin_user, function(){
      $omega_node.web_request('manufactured::create_entity', new_ship1, function(){
        $omega_node.web_request('manufactured::create_entity', new_ship2, function(){
          OmegaCommand.launch_attack.exec(new_ship1['value'], new_ship2_id);
          // XXX need to wait at least the attacking poll delay before
          //     attacking commences
          window.setTimeout(function() {
            OmegaQuery.entity_with_id(new_ship1_id, function(ship){
              ship.load();

              // ensure attack line has been added to scene
              equal(ship.scene_objs.length, 3);
              equal($omega_scene.scene_objects().length, 2)
              equal($omega_scene.scene_objects()[1].omega_id, new_ship1_id + "-attacking-line");
              equal($omega_scene.scene_objects()[1].geometry.vertices[0].x, new_ship1['value'].location['value'].x);
              equal($omega_scene.scene_objects()[1].geometry.vertices[0].y, new_ship1['value'].location['value'].y);
              equal($omega_scene.scene_objects()[1].geometry.vertices[0].z, new_ship1['value'].location['value'].z);
              equal($omega_scene.scene_objects()[1].geometry.vertices[1].x, new_ship2['value'].location['value'].x);
              equal($omega_scene.scene_objects()[1].geometry.vertices[1].y, new_ship2['value'].location['value'].y + 25);
              equal($omega_scene.scene_objects()[1].geometry.vertices[1].z, new_ship2['value'].location['value'].z);

              start();
            });
          }, 500);
        });
      });
    });
  });

  asyncTest("load mining ship", function() {
    $omega_scene = setup_canvas();
    // TODO load ship / resource source from fixtures
    var new_ship_id = 'mmorsi-ship-' + guid();
    var new_ship = new JRObject('Manufactured::Ship', {
                      'id'         : new_ship_id,
                      'type'       : 'mining',
                      'user_id'    : 'mmorsi',
                      'system_name': 'Athena',
                      'location'   : new JRObject("Motel::Location",
                                                  {'x' : 40, 'y' : -30, 'z' : 20})
                    });

    var new_rs_type = 'metal';
    var new_rs_name =  guid();
    var new_rs_id   = new_rs_type + '-' + new_rs_name;
    var new_rs = new JRObject('Cosmos::Resource', {
                      'name'       : new_rs_name,
                      'type'       : new_rs_type
                    });

    // create new system / set root location
    var nsys = new OmegaSolarSystem({name : 'Athena',
                                     location : {id : 2}});
    $omega_registry.add(nsys);
    $omega_scene.set_root(nsys);
    $omega_skybox.hide();

    login_test_user($admin_user, function(){
      $omega_node.web_request('manufactured::create_entity', new_ship, function(){
        $omega_node.web_request('cosmos::set_resource', 'ast1', new_rs, 100, function(){
          OmegaCommand.start_mining.exec({ 'id' : new_ship_id }, 'ast1_' + new_rs_id);
          // XXX need to wait at least the mining poll delay before
          //     mining commences
          window.setTimeout(function() {
            OmegaQuery.entity_with_id(new_ship_id, function(ship){
              ship.load();

              // ensure attack line has been added to scene
              equal(ship.scene_objs.length, 3);
              equal($omega_scene.scene_objects().length, 2)
              equal($omega_scene.scene_objects()[1].omega_id, new_ship_id + "-mining-line");
              equal($omega_scene.scene_objects()[1].geometry.vertices[0].x, new_ship['value'].location['value'].x);
              equal($omega_scene.scene_objects()[1].geometry.vertices[0].y, new_ship['value'].location['value'].y);
              equal($omega_scene.scene_objects()[1].geometry.vertices[0].z, new_ship['value'].location['value'].z);
              equal($omega_scene.scene_objects()[1].geometry.vertices[1].x, ship.mining.entity.location.x);
              equal($omega_scene.scene_objects()[1].geometry.vertices[1].y, ship.mining.entity.location.y + 25);
              equal($omega_scene.scene_objects()[1].geometry.vertices[1].z, ship.mining.entity.location.z);

              start();
            });
          }, 500);
        });
      });
    });
  });

  test("load station", function(){
    $omega_scene = setup_canvas();
    $user_id = 'rendered-user';

    var station = new OmegaShip({id : "stat1", user_id : 'rendered-user',
                              location : new OmegaLocation({ x : 50, y : 50, z : -10})});
                                 
    station.load();

    // test scene_objs have been added to jump gate

    equal(station.scene_objs.length, 1);
    equal(station.scene_objs[0].material.color.getHex().toString(16), "cc00");
    equal(station.scene_objs[0].omega_id, "stat1-mesh");
    // ensure geometry's vertices are at the correct locations

    equal($omega_scene.scene_objects().length, 1)
    equal($omega_scene.scene_objects()[0].omega_id, "stat1-mesh");
    equal($omega_scene.scene_objects()[0].position.x, 50);
    equal($omega_scene.scene_objects()[0].position.y, 50);
    equal($omega_scene.scene_objects()[0].position.z, -10);
  });

  asyncTest("clicked station", function(){
    $omega_scene = setup_canvas();
    $user_id = 'rendered-user';

    // XXX need to wait till ship geometry is loaded
    window.setTimeout(function() {
      var sys1 = new OmegaSolarSystem({id : 'sys1', name : 'sys1',
                                       location : new OmegaLocation({id : 42})});
      var station = new OmegaStation({id : "station1", user_id : 'rendered-user', size: 20,
                                system_name : 'sys1', json_class : 'Manufactured::Station',
                                location : new OmegaLocation({ x : 50, y : 50, z : -10, parent_id : 42})});

      $omega_registry.add(sys1);
      $omega_registry.add(station);
      $omega_scene.set_root(sys1);

      // need to animate scene and wait till its ready
      $omega_scene.animate();
      window.setTimeout(function() {
        var pos = station.scene_objs[0].position;
        var c = canvas_to_xy(pos);
        var e = new jQuery.Event('click');
        e.pageX = c.x;
        e.pageY = c.y;

        $("#omega_canvas").trigger(e);

        equal($('#omega_entity_container').css('display'), 'block');
        ok($('#omega_entity_container').html().indexOf('Station: station1') != -1);

        // ensure station is 'selected' color
        equal(station.scene_objs[0].material.color.getHex().toString(16), "ffff00");

        // unselect station
        $("#entity_container_close").trigger("click");

        // ensure station is 'unselected' color
        equal(station.scene_objs[0].material.color.getHex().toString(16), "cc");

        start();
      }, 1000);
    }, 250);
                                 
  });

  asyncTest("station added to scene", 2, function(){
    $omega_scene = setup_canvas();
    var station = new OmegaShip({id : 'mmorsi-manufacturing-station1', system_name : 'Athena',
                                 json_class : 'Manufacturing::Station',
                                 location : new OmegaLocation({ id: 15 } )});
    var system = new OmegaSolarSystem({id : 'Athena', name       : 'Athena',
                                       location   : { id: 2 }});

    $omega_registry.add(system);
    $omega_registry.add(station);

    // so we can be sure of difference below
    equal($omega_registry.get('mmorsi-manufacturing-station1').location.parent_id, null);

    // login test user so as to be able to query for manufactured entities
    login_test_user($admin_user, function(){
      $omega_scene.set_root(system);

      // ensure added_to_scene callback is invoked, for now
      // this just ensures entity/location is updated from server
      // and we've subscribed to location updates
      window.setTimeout(function() {
        equal($omega_registry.get('mmorsi-manufacturing-station1').location.parent_id, 2);
        start();
      }, 250);
    });
  });

});
