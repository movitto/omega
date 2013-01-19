require("javascripts/omega/canvas.js");

$(document).ready(function(){

  module("entity helper");
  
  test("roundTo", function() {
    equal(roundTo(4.21345, 2), 4.21);
  });

  // TODO test convert_entity

  module("omega timer");
  
  asyncTest("start/stop timer", function() {
    var times_called = 0;
    var timer = new OmegaTimer(500, function(){
      times_called += 1;
    });

    setTimeout(function(){
      ok(times_called >= 1);
      timer.stop();
      start();
    }, 1000);
  });

  module("omega registry");
  
  test("get/set entities", function() {
    // TODO load data from fixtures
    var entity1 = { 'id'   : 'entity1' };
    var entity2 = { 'name' : 'entity2' };

    var registry = new OmegaRegistry();
    registry.add(entity1);
    registry.add(entity2);
    equal(Object.keys(registry.entities()).length, 2);

    var rentity = registry.get('entity1');
    equal(rentity, entity1);

    rentity = registry.get('entity2');
    equal(rentity, entity2);
    equal(rentity.id, rentity.name);
  });

  test("registration callbacks", function() {
    // TODO load data from fixtures
    var entity1 = { 'id'   : 'entity1' };

    var callback_called = false;
    var registry = new OmegaRegistry();
    registry.on_registration(function(e){
      callback_called = true;
      equal(e.id, entity1.id);
    });
    registry.add(entity1);
    equal(callback_called, true);
  });

  test("select entities", function() {
    // TODO load data from fixtures
    var entity1 = { 'id'        : 'entity1',
                    'property1' : true,
                    'property2' : true };
    var entity2 = { 'id'        : 'entity2',
                    'property1' : false,
                    'property2' : true };
    var entity3 = { 'id'        : 'entity3',
                    'property1' : true,
                    'property2' : false };

    var registry = new OmegaRegistry();
    registry.add(entity1);
    registry.add(entity2);
    registry.add(entity3);

    var selected = registry.select([function(e){ return e.property1; }]);
    equal(selected.length, 2);
    equal(selected.indexOf(entity1), 0);
    equal(selected.indexOf(entity3), 1);

    selected = registry.select([function(e){ return e.property1 && e.property2; }]);
    equal(selected.length, 1);
    equal(selected.indexOf(entity1), 0);
  });

  test("cache entity", function() {
    // TODO load data from fixtures
    var entity1 = { 'id'        : 'entity1',
                    'property1' : true,
                    'property2' : true };
    
    var registry = new OmegaRegistry();

    var retrieved_called = 0;
    var retrieved = function(entity_id){
      retrieved_called += 1;
    }

    var retrieval_called = 0;
    var retrieval = function(entity_id, rretrieved){
      retrieval_called += 1;
      equal(rretrieved, retrieved);
      registry.add(entity1);
    };

    registry.cached(entity1.id, retrieval, retrieved);
    equal(retrieval_called, 1);
    equal(retrieved_called, 0);

    registry.cached(entity1.id, retrieval, retrieved);
    equal(retrieval_called, 1);
    equal(retrieved_called, 1);
  });

  test("clear registry", function() {
    // TODO load data from fixtures
    var entity1 = { 'id'   : 'entity1' };
    var entity2 = { 'name' : 'entity2' };

    var registry = new OmegaRegistry();
    registry.add(entity1);
    registry.add(entity2);
    equal(Object.keys(registry.entities()).length, 2);

    registry.clear();
    equal(Object.keys(registry.entities()).length, 0);
  });

  // TODO test registry timers?

  module("omega entity");

  test("setting entity properties", function() {
    var ote = new OmegaTestEntity({'id' : 'foobar'});
    equal(ote.id, 'foobar');
  });

  test("on load", function() {
    var ote = new OmegaTestEntity();
    equal(ote.load_called, false);

    ote.load();
    equal(ote.load_called, true);
  });

  test("on clicked", function() {
    var ote = new OmegaTestEntity();
    equal(ote.clicked_called, false);

    ote.clicked();
    equal(ote.clicked_called, true);
  });

  test("on moved", function() {
    var ote = new OmegaTestEntity();
    equal(ote.movement_called, false);

    ote.moved();
    equal(ote.movement_called, true);
  });

  test("is_a", function() {
    var ote = new OmegaTestEntity({'json_class' : 'Foobar'});
    ok(ote.is_a('Foobar'));
    ok(!ote.is_a('Barfoo'));
  });

  test("belongs to user", function() {
    var ote = new OmegaTestEntity({'user_id' : 'foobar'});
    ok(ote.belongs_to_user('foobar'));
    ok(!ote.belongs_to_user('admin'));
  });

  module("omega location");
  
  test("distance_from", function() {
    var loc = new OmegaLocation({x: 100, y: 100, z: 100});
    equal(loc.distance_from(110, 100, 100), 10);
  });

  test("is_within", function() {
    var loc1 = new OmegaLocation({x: 100, y: 100, z: 100});
    var loc2 = new OmegaLocation({x: 100, y: 110, z: 100});
    ok( loc1.is_within(11, loc2));
    ok(!loc1.is_within(5, loc2));
  });

  test("to_s", function() {
    var loc = new OmegaLocation({x: 123.4567, y: 234.5678, z: 345.6789});
    equal(loc.to_s(), '123.46/234.57/345.68');
  });

  //test("toJSON", function() {
  // TODO
  //});

  test("clone", function() {
    var loc = new OmegaLocation({id: 'loc123', parent_id: '420',
                                 x: 123.4567, y: 234.5678, z: 345.6789,
                                 movement_strategy: 'Motel::MovementStrategies::Stopped'});
    var loc2 = loc.clone();
    equal(loc2.id, 'loc123');
    equal(loc2.parent_id, '420');
    equal(loc2.x, 123.4567);
    equal(loc2.y, 234.5678);
    equal(loc2.z, 345.6789);
    equal(loc2.movement_strategy, 'Motel::MovementStrategies::Stopped');
  });

  module("omega galaxy");
  
  test("children", function() {
    var galaxy = new OmegaGalaxy({solar_systems : ['sys1', 'sys2']});
    equal(galaxy.children().length, 2)
    ok(galaxy.children().indexOf('sys1') != -1);
    ok(galaxy.children().indexOf('sys2') != -1);
    ok(galaxy.children().indexOf('sys3') == -1);
  });

  module("omega solar system");
  
  test("children", function() {
    var system = new OmegaSolarSystem({name       : 'system1',
                                       star       : 'star1',
                                       planets    : ['pl1', 'pl2'],
                                       asteroids  : ['ast1', 'ast2'],
                                       jump_gates : ['jg1', 'jg2']});
                                       
    // TODO load from fixtures
    var ship1 = { 'id' : 'ship1',
                  'system_name' : 'system1',
                  'json_class'  : 'Manufactured::Ship' };
    var ship2 = { 'id' : 'ship2',
                  'system_name' : 'system2',
                  'json_class'  : 'Manufactured::Ship' };
    var stat1 = { 'id' : 'station1',
                  'system_name' : 'system1',
                  'json_class'  : 'Manufactured::Station' };
    var stat2 = { 'id' : 'station2',
                  'system_name' : 'system2',
                  'json_class'  : 'Manufactured::Station' };
    var other = { 'id' : 'other',
                  'system_name' : 'system1',
                  'json_class'  : 'Other' };

    $omega_registry.add(ship1);
    $omega_registry.add(ship2);
    $omega_registry.add(stat1);
    $omega_registry.add(stat2);
    $omega_registry.add(other);

    var children = system.children();
    equal(children.length, 9);
    ok(children.indexOf('star1') != -1);
    ok(children.indexOf('pl1')   != -1);
    ok(children.indexOf('pl2')   != -1);
    ok(children.indexOf('ast1')  != -1);
    ok(children.indexOf('ast2')  != -1);
    ok(children.indexOf('jg1')   != -1);
    ok(children.indexOf('jg2')   != -1);
    ok(children.indexOf(ship1)   != -1);
    ok(children.indexOf(stat1)   != -1);
    ok(children.indexOf(ship2)   == -1);
    ok(children.indexOf(stat2)   == -1);
    ok(children.indexOf(other)   == -1);
  });

  // TODO test system scene data loaded & on clicked ?

  //module("omega star");
  
  //test("", function() {
  //});

  // TODO test star scene data loaded

  module("omega planet");
  
  test("children", function() {
    var planet = new OmegaPlanet({moons : ['moon1', 'moon2']});
    equal(planet.children().length, 2)
    ok(planet.children().indexOf('moon1') != -1);
    ok(planet.children().indexOf('moon2') != -1);
    ok(planet.children().indexOf('moon3') == -1);
  });

  // TODO test system scene data loaded, on clicked, on movement, move, and calc_orbit ?

  //module("omega asteroid");

  //test("", function() {
  //});

  // TODO test asteroid scene data loaded

  //module("omega jump gate");
  
  //test("", function() {
  //});

  // TODO test jump gate scene data loaded, on clicked, and on unselected ?

  //module("omega ship");
  
  //test("", function() {
  //});

  // TODO test ship scene data loaded, on unselected, on clicked, and on movement ?

  //module("omega station");
  
  //test("", function() {
  //});

  // TODO test station scene data loaded, on clicked, and on unselected ?
});
