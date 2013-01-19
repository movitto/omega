require("javascripts/omega/user.js");
require("javascripts/omega/commands.js");

$(document).ready(function(){

  // TODO test omega_callback ?

  module("omega_commands");
  
  asyncTest("retrieving all entities", 7, function() {
    login_test_user($admin_user, function(){
      OmegaQuery.all_entities(function(entities){
        ok(entities.length >= 9);
        var ids = [];
        for(var entity in entities) ids.push(entity.id);
        ok(ids.indexOf('mmorsi-manufacturing-station1') != null);
        ok(ids.indexOf('mmorsi-mining-ship1') != null);
        ok(ids.indexOf('mmorsi-corvette-ship1') != null);
        ok(ids.indexOf('mmorsi-corvette-ship2') != null);
        ok(ids.indexOf('mmorsi-corvette-ship3') != null);
        ok(ids.indexOf('opponent-mining-ship2') != null);
        start();
      });
    });
  });
  
  asyncTest("retrieving entities owned by a user", 4, function() {
    login_test_user($admin_user, function(){
      OmegaQuery.entities_owned_by('mmorsi', function(entities){
        ok(entities.length >= 7);
        var ids = [];
        for(var entity in entities) ids.push(entities[entity].id);
        ok(ids.indexOf('mmorsi-manufacturing-station1') != -1);
        ok(ids.indexOf('mmorsi-mining-ship1') != -1);
        ok(ids.indexOf('opponent-mining-ship2') == -1);
        start();
      });
    });
  });
  
  asyncTest("retrieving entities under a system", 3, function() {
    login_test_user($admin_user, function(){
      OmegaQuery.entities_under('Philo', function(entities){
        ok(entities.length == 1);
        var ids = [];
        for(var entity in entities) ids.push(entities[entity].id);
        ok(ids.indexOf('mmorsi-corvette-ship4') ==  0);
        ok(ids.indexOf('mmorsi-corvette-ship3') == -1);
        start();
      });
    });
  });
  
  asyncTest("retrieve entity by id", 1, function() {
    login_test_user($admin_user, function(){
      OmegaQuery.entity_with_id('mmorsi-corvette-ship1', function(entity){
        equal(entity.id, 'mmorsi-corvette-ship1');
        start();
      });
    });
  });
  
  asyncTest("retrieve all galaxies", 2, function() {
    login_test_user($admin_user, function(){
      OmegaQuery.all_galaxies(function(galaxies){
        equal(galaxies.length, 1);
        equal(galaxies[0].name, 'Zeus');
        start();
      });
    });
  });
  
  asyncTest("retrieve system by name", 1, function() {
    login_test_user($admin_user, function(){
      OmegaQuery.system_with_name('Athena', function(system){
        equal(system.name, 'Athena');
        start();
      });
    });
  });
  
  asyncTest("retrieve resource sources", 1, function() {
    login_test_user($admin_user, function(){
      OmegaQuery.resource_sources('ast2', function(resource_sources){
        equal(resource_sources.length, 1);
        start();
      });
    });
  });
  
  asyncTest("retrieve all users", 1, function() {
    login_test_user($admin_user, function(){
      OmegaQuery.all_users(function(users){
        equal(users.length, 9);
        start();
      });
    });
  });
  
  asyncTest("triggering jump gate", 1, function() {
    // TODO load ship from fixtures
    var new_ship_id = 'mmorsi-ship-' + guid();
    var new_ship = new JRObject('Manufactured::Ship', {
                     'id'         : new_ship_id,
                     'type'       : 'corvette',
                     'user_id'    : 'mmorsi',
                     'system_name': 'Athena',
                     'location'   : new JRObject("Motel::Location",
                                                 {'x' : -140, 'y' : -140, 'z' : -140})
                   });

    // log in as admin and create new ship to test jumping w/
    login_test_user($admin_user, function(){
      $omega_node.web_request('manufactured::create_entity', new_ship, function(){

        // need to logout then login as mmorsi as trigger_jump_gate gets all user
        // owned ships around gate
        logout_test_user(function(){
          login_test_user($mmorsi_user, function(){
            // load ship to be pulled in via jg
            OmegaQuery.entity_with_id(new_ship_id, null);

            var jg_loc = {parent_id : 2, x : -150, y : -150, z : -150};
            var jg     = {location  : jg_loc, endpoint : 'Aphrodite', trigger_distance: 100};
            OmegaCommand.trigger_jump_gate.exec(jg, function(jg){
              OmegaQuery.entity_with_id(new_ship_id, function(ship){
                equal(ship.system_name, "Aphrodite");
                start();
              });
            });
          });
        });
      });
    });
  });
  
  asyncTest("moving ship", 1, function() {
    login_test_user($admin_user, function(){
      OmegaQuery.entity_with_id('mmorsi-corvette-ship2', function(ship){
        OmegaCommand.move_ship.exec(ship, ship.location.x + 50, ship.location.y, ship.location.z);
        OmegaQuery.entity_with_id('mmorsi-corvette-ship2', function(ship){
          equal(ship.location.movement_strategy.json_class, "Motel::MovementStrategies::Linear");
          start();
        });
      });
    });
  });
  
  asyncTest("attacking", 1, function() {
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

    login_test_user($admin_user, function(){
      $omega_node.web_request('manufactured::create_entity', new_ship1, function(){
        $omega_node.web_request('manufactured::create_entity', new_ship2, function(){
          OmegaCommand.launch_attack.exec(new_ship1, new_ship2_id);
          OmegaQuery.entity_with_id(new_ship1_id, function(ship){
            // FIXME how to test this succeeds? Need to return attacking target as part of ship
            equal(null, null);
            start();
          });
        });
      });
    });
  });
  
  asyncTest("docking and undocking ship", 2, function() {
    login_test_user($admin_user, function(){
      OmegaQuery.entity_with_id('mmorsi-corvette-ship3', function(ship){
        OmegaCommand.dock_ship.exec(ship, 'mmorsi-manufacturing-station1');
        OmegaQuery.entity_with_id('mmorsi-corvette-ship3', function(ship){
          equal(ship.docked_at.id, "mmorsi-manufacturing-station1");
          start();
        });
        OmegaCommand.undock_ship.exec(ship);
        OmegaQuery.entity_with_id('mmorsi-corvette-ship3', function(ship){
          equal(ship.docked_at, null);
          start();
        });
      });
    });
    stop();
  });
  
  asyncTest("mining", 1, function() {
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

    login_test_user($admin_user, function(){
      $omega_node.web_request('manufactured::create_entity', new_ship, function(){
        $omega_node.web_request('cosmos::set_resource', 'ast1', new_rs, 100, function(){
          OmegaCommand.start_mining.exec({ 'id' : new_ship_id }, 'ast1_' + new_rs_id);
          // XXX need to wait at least the mining poll delay before
          //     mining commences
          window.setTimeout(function() {
            OmegaQuery.entity_with_id(new_ship_id, function(ship){
              ok(ship.mining != null);
              // TODO verify mining target
              start();
            });
          }, 500);
        });
      });
    });
  });
  
  asyncTest("transferring ship resources", 2, function() {
    // TODO load ship / station from fixtures
    var new_ship_id = 'mmorsi-ship-' + guid();
    var new_ship = new JRObject('Manufactured::Ship', {
                      'id'         : new_ship_id,
                      'type'       : 'mining',
                      'user_id'    : 'mmorsi',
                      'system_name': 'Athena',
                      'location'   : new JRObject("Motel::Location",
                                                  {'x' : 40, 'y' : -30, 'z' : 20})
                    });

    var new_stat_id = 'mmorsi-station-' + guid();
    var new_stat    = new JRObject('Manufactured::Station', {
                        'id'         : new_stat_id,
                        'type'       : 'manufacturing',
                        'user_id'    : 'mmorsi',
                        'system_name': 'Athena',
                        'location'   : new JRObject("Motel::Location",
                                                    {'x' : 40, 'y' : 40, 'z' : 40})
                      });


    login_test_user($admin_user, function(){
      $omega_node.web_request('manufactured::create_entity', new_ship, function(){
        $omega_node.web_request('manufactured::create_entity', new_stat, function(){
          OmegaQuery.entity_with_id(new_stat_id, function(stat){
            OmegaCommand.transfer_resources.exec(stat, new_ship_id);
            OmegaQuery.entity_with_id(new_stat_id, function(stat){
              equal(Object.keys(stat.resources).length, 0);
              start();
            });
            OmegaQuery.entity_with_id(new_ship_id, function(ship){
              // TODO verify specific resources before/after transfer
              ok(0 != ship.resources.length);
              start();
            });
          });
        });
      });
    });
    stop();
  });
  
  asyncTest("constructing entities", 1, function() {
    // TODO load station from fixtures
    var new_stat_id = 'mmorsi-station-' + guid();
    var new_stat    = new JRObject('Manufactured::Station', {
                        'id'         : new_stat_id,
                        'type'       : 'manufacturing',
                        'user_id'    : 'mmorsi',
                        'system_name': 'Athena',
                        'location'   : new JRObject("Motel::Location",
                                                    {'x' : 40, 'y' : 40, 'z' : 40})
                      });

    login_test_user($admin_user, function(){
      $omega_node.web_request('manufactured::create_entity', new_stat, function(){
        OmegaQuery.all_entities(function(entities){
          var old = entities.length;
          OmegaCommand.construct_entity.exec({'id' : new_stat_id});
          OmegaQuery.all_entities(function(entities){
            equal(entities.length, old + 1);
            // TODO verify type of newly created entity ?
            start();
          });
        });
      });
    });
  });

});
