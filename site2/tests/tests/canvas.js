require("javascripts/omega/canvas.js");

$(document).ready(function(){

  // TODO test camera / grid / canvas ui / select box ?

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

    var user   = {
                   'name'       : 'foobar',
                   'json_class' : 'Users::User',
                   'alliances' : [{ 'id' : 'ally1' }]
                 };

    var entities_container = new OmegaEntitiesContainer();
    //equal($('#locations_list').css('display'), 'none');
    //equal($('#alliances_list').css('display'), 'none');

    entities_container.add_to_entities_container(galaxy);
    ok($('#locations_list ul').html().indexOf('<li name="Zeus">Zeus</li>') != -1)
    equal($('#locations_list').css('display'), 'block');

    entities_container.add_to_entities_container(user);
    ok($('#alliances_list ul').html().indexOf('<li name="ally1">ally1</li>') != -1)
    equal($('#alliances_list').css('display'), 'block');
  });

  test("click entities container", function() {
    // TODO load entities from fixtures
    var galaxy = {
                   'name'       : 'Zeus',
                   'json_class' : 'Cosmos::Galaxy',
                   'children'   : function() { return []; }
                 };

    // necessary intialization
    setup_canvas();
    $omega_registry.add(galaxy);

    equal($omega_scene.get_root(), null);

    var entities_container = new OmegaEntitiesContainer();
    entities_container.add_to_entities_container(galaxy);
    $('#locations_list ul li:first').click();

    equal($omega_scene.get_root().name, 'Zeus');
  });

  module("omega_canvas");

  test("set canvas background", function() {
    // TODO load from fixtures
    var system  = { 'background': 'foobar' };

    var omega_canvas = new OmegaCanvas();
    omega_canvas.set_background(system);

    equal($("#omega_canvas").css('backgroundImage'),
          'url("http://localhost/womega/images/backgrounds/foobar.png")');
  });
  
  test("show/hide canvas", function() {
    var omega_canvas = new OmegaCanvas();
    omega_canvas.hide();
    equal($('canvas').css('display'),              'none');
    equal($('.entities_container').css('display'), 'none');
    equal($('#camera_controls').css('display'),    'none');
    equal($('#grid_control').css('display'),       'none');
    equal($('#close_canvas').css('display'),       'none');
    equal($('#show_canvas').css('display'),        'block');

    omega_canvas.show();
    equal($('canvas').css('display'),              'block');
    equal($('#camera_controls').css('display'),    'block');
    equal($('#grid_control').css('display'),       'block');
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
    equal($('canvas').css('display'),              'block');
    equal($('#close_canvas').css('display'),       'block');
    equal($('#show_canvas').css('display'),        'none');
  });

  // TODO test click canvas
});
