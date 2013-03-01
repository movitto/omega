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
  
  test("modify entities container", function() {
    // TODO load entities from fixtures
    var galaxy = {
                   'name'       : 'Zeus',
                   'json_class' : 'Cosmos::Galaxy',
                   'children'   : function() { return []; }
                 };

    var ship = { id : 'ship1', json_class : 'Manufactured::Ship' };

    var entities_container = new OmegaEntitiesContainer();
    //equal($('#locations_list').css('display'), 'none');
    //equal($('#alliances_list').css('display'), 'none');
    //equal($('#entities_list').css('display'), 'none');

    entities_container.add_to_entities_container(galaxy);
    ok(/\s*<li name="Zeus".*>Zeus<\/li>\s*/.test($('#locations_list ul').html()))
    equal($('#locations_list').css('display'), 'block');

    entities_container.add_to_entities_container(ship);
    ok(/\s*<li name="ship1".*>ship1<\/li>\s*/.test($('#entities_list ul').html()))
    equal($('#entities_list').css('display'), 'block');

    // TODO test fleet and entity lists
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

  module("omega_canvas");

  // TODO move to skybox tests
  //test("set canvas background", function() {
  //  // TODO load from fixtures
  //  var system  = { 'background': 'foobar' };

  //  var omega_canvas = new OmegaCanvas();
  //  omega_canvas.set_background(system);

  //  equal($("#omega_canvas").css('backgroundImage'),
  //        'url("http://localhost/womega/images/backgrounds/foobar.png")');
  //});
  
  test("show/hide canvas", function() {
    var omega_canvas = new OmegaCanvas();
    omega_canvas.hide();
    equal($('canvas').css('display'),              'none');
    equal($('.entities_container').css('display'), 'none');
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

  // TODO test click canvas
});
