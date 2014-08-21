// Test mixin usage through ship
pavlov.specify("Omega.ShipGfx", function(){
describe("Omega.ShipGfx", function(){
  var ship;

  before(function(){
    ship = Omega.Gen.ship();
  });

  describe("#load_gfx", function(){
    describe("graphics are loaded", function(){
      it("does nothing / just returns", function(){
        sinon.stub(ship, 'gfx_loaded').returns(true);
        sinon.spy(ship, '_loaded_gfx');
        ship.load_gfx();
        sinon.assert.notCalled(ship._loaded_gfx);
      });
    });

    it("loads Ship mesh geometry", function(){
      var event_cb = function(){};
      var geometry = Omega.ShipMesh.geometry_for(ship.type);
      sinon.stub(ship, 'gfx_loaded').returns(false);
      sinon.stub(ship, '_load_async_resource');
      ship.load_gfx(event_cb);

      var id = 'ship.' + ship.type + '.mesh_geometry';
      sinon.assert.calledWith(ship._load_async_resource, id, geometry, event_cb);
    });

    it("loads Ship missile geometry", function(){
      var event_cb = function(){};
      var geometry = Omega.ShipMissile.geometry_for(ship.type);
      sinon.stub(ship, 'gfx_loaded').returns(false);
      sinon.stub(ship, '_load_async_resource');
      ship.load_gfx(event_cb);

      var id = 'ship.' + ship.type + '.missile_geometry';
      sinon.assert.calledWith(ship._load_async_resource, id, geometry, event_cb);
    });

    it("creates highlight effects for Ship", function(){
      var ship = Omega.Test.Canvas.Entities()['ship'];
      var highlight = ship._retrieve_resource('highlight');
      assert(highlight).isOfType(Omega.ShipHighlightEffects);
    });

    it("creates lamps for Ship", function(){
      var ship  = Omega.Test.Canvas.Entities()['ship'];
      var lamps = ship._retrieve_resource('lamps');
      assert(lamps).isOfType(Omega.ShipLamps);
    });

    it("creates trails for Ship", function(){
      var ship  = Omega.Test.Canvas.Entities()['ship'];
      var trails = ship._retrieve_resource('trails');
      assert(trails).isOfType(Omega.ShipTrails);
    });

    it("creates attack vector for Ship", function(){
      var ship  = Omega.Test.Canvas.Entities()['ship'];
      var av = ship._retrieve_resource('attack_vector');
      assert(av).isOfType(Omega.ShipAttackVector);
    });

    it("creates mining vector for Ship", function(){
      var ship  = Omega.Test.Canvas.Entities()['ship'];
      var mv = ship._retrieve_resource('mining_vector');
      assert(mv).isOfType(Omega.ShipMiningVector);
    });

    it("creates trajectory vectors for ship", function(){
      var ship  = Omega.Test.Canvas.Entities()['ship'];
      var t1 = ship._retrieve_resource('trajectory1');
      var t2 = ship._retrieve_resource('trajectory2');
      assert(t1).isOfType(Omega.ShipTrajectory);
      assert(t2).isOfType(Omega.ShipTrajectory);
    });

    it("creates progress bar for ship hp", function(){
      var ship  = Omega.Test.Canvas.Entities()['ship'];
      var hp = ship._retrieve_resource('hp_bar');
      assert(hp).isOfType(Omega.ShipHpBar);
    });

    it("creates visited route for ship", function(){
      var ship  = Omega.Test.Canvas.Entities()['ship'];
      var visited = ship._retrieve_resource('visited_route');
      assert(visited).isOfType(Omega.ShipVisitedRoute);
    });

    it("creates destruction effects for ship", function(){
      var ship  = Omega.Test.Canvas.Entities()['ship'];
      var destruction = ship._retrieve_resource('destruction');
      assert(destruction).isOfType(Omega.ShipDestructionEffect);
    });

    it("creates explosion effects for ship", function(){
      var ship  = Omega.Test.Canvas.Entities()['ship'];
      var explosions = ship._retrieve_resource('explosions');
      assert(explosions).isOfType(Omega.ShipExplosionEffect);
    });

    it("creates smoke effects for ship", function(){
      var ship  = Omega.Test.Canvas.Entities()['ship'];
      var smoke = ship._retrieve_resource('smoke');
      assert(smoke).isOfType(Omega.ShipSmokeEffect);
    });

    it("creates docking audio for ship", function(){
      var ship  = Omega.Test.Canvas.Entities()['ship'];
      var audio = ship._retrieve_resource('docking_audio');
      assert(audio).isOfType(Omega.ShipDockingAudioEffect);
    });

    it("creates mining audio for ship", function(){
      var ship  = Omega.Test.Canvas.Entities()['ship'];
      var audio = ship._retrieve_resource('mining_audio');
      assert(audio).isOfType(Omega.ShipMiningAudioEffect);
    });

    it("creates destruction audio for ship", function(){
      var ship  = Omega.Test.Canvas.Entities()['ship'];
      var audio = ship._retrieve_resource('destruction_audio');
      assert(audio).isOfType(Omega.ShipDestructionAudioEffect);
    });

    it("creates mining completed audio for ship", function(){
      var ship  = Omega.Test.Canvas.Entities()['ship'];
      var audio = ship._retrieve_resource('mining_completed_audio');
      assert(audio).isOfType(Omega.ShipMiningCompletedAudioEffect);
    });

    it("creates combat audio for ship", function(){
      var ship  = Omega.Test.Canvas.Entities()['ship'];
      var audio = ship._retrieve_resource('combat_audio');
      assert(audio).isOfType(Omega.ShipCombatAudioEffect);
    });

    it("creates movement audio for ship", function(){
      var ship  = Omega.Test.Canvas.Entities()['ship'];
      var audio = ship._retrieve_resource('movement_audio');
      assert(audio).isOfType(Omega.ShipMovementAudioEffect);
    });
  });

  describe("#init_gfx", function(){
    var type = 'corvette';
    var ship, geo, highlight, lamps, trails, visited, attack_vector, mining_vector,
              trajectory1, trajectory2, hp_bar, destruction, explosions, smoke;

    before(function(){
      ship          = Omega.Gen.ship({type: type});
      geo           = new THREE.Geometry();
      highlight     = new Omega.ShipHighlightEffects();
      lamps         = new Omega.ShipLamps({type : type});
      trails        = new Omega.ShipTrails({type : type});
      visited       = new Omega.ShipVisitedRoute();
      attack_vector = new Omega.ShipAttackVector();
      mining_vector = new Omega.ShipMiningVector();
      trajectory1   = new Omega.ShipTrajectory();
      trajectory2   = new Omega.ShipTrajectory();
      hp_bar        = new Omega.ShipHpBar();
      destruction   = new Omega.ShipDestructionEffect();
      explosions    = new Omega.ShipExplosionEffect();
      smoke         = new Omega.ShipSmokeEffect();
      sinon.stub(ship, '_retrieve_async_resource');
      sinon.stub(ship._retrieve_resource('highlight'),      'clone').returns(highlight);
      sinon.stub(ship._retrieve_resource('lamps'),          'clone').returns(lamps);
      sinon.stub(ship._retrieve_resource('trails'),         'clone').returns(trails);
      sinon.stub(ship._retrieve_resource('visited_route'),  'clone').returns(visited);
      sinon.stub(ship._retrieve_resource('attack_vector'),  'clone').returns(attack_vector);
      sinon.stub(ship._retrieve_resource('mining_vector'),  'clone').returns(mining_vector);
      sinon.stub(ship._retrieve_resource('trajectory1'),    'clone').returns(trajectory1);
      sinon.stub(ship._retrieve_resource('trajectory2'),    'clone').returns(trajectory2);
      sinon.stub(ship._retrieve_resource('hp_bar'),         'clone').returns(hp_bar);
      sinon.stub(ship._retrieve_resource('destruction'),    'clone').returns(destruction);
      sinon.stub(ship._retrieve_resource('smoke'),          'clone').returns(smoke);
      sinon.stub(ship._retrieve_resource('explosions'),     'for_ship').returns(explosions);
    });

    after(function(){
      ship._retrieve_resource('highlight').clone.restore();
      ship._retrieve_resource('lamps').clone.restore();
      ship._retrieve_resource('trails').clone.restore();
      ship._retrieve_resource('visited_route').clone.restore();
      ship._retrieve_resource('attack_vector').clone.restore();
      ship._retrieve_resource('mining_vector').clone.restore();
      ship._retrieve_resource('trajectory1').clone.restore();
      ship._retrieve_resource('trajectory2').clone.restore();
      ship._retrieve_resource('hp_bar').clone.restore();
      ship._retrieve_resource('destruction').clone.restore();
      ship._retrieve_resource('explosions').for_ship.restore();
      ship._retrieve_resource('smoke').clone.restore();
    });

    it("loads ship gfx", function(){
      sinon.spy(ship, 'load_gfx');
      ship.init_gfx();
      sinon.assert.called(ship.load_gfx);
    });

    it("retrieves Ship geometry and creates mesh", function(){
      var cloned_geo = new THREE.Geometry();
      sinon.stub(geo, 'clone').returns(cloned_geo);

      var mat = ship._retrieve_resource('mesh_material').material;
      var cloned_mat = new THREE.MeshBasicMaterial();
      sinon.stub(mat, 'clone').returns(cloned_mat);

      ship.init_gfx();
      sinon.assert.calledWith(ship._retrieve_async_resource,
                              'ship.'+type+'.mesh_geometry', sinon.match.func);
      assert(ship.mesh).equals(Omega.UI.CanvasEntityGfxStub.instance());

      ship._retrieve_async_resource.omega_callback()(geo);
      assert(ship.mesh).isOfType(Omega.ShipMesh);
      assert(ship.mesh.tmesh.geometry).equals(cloned_geo);
      assert(ship.mesh.tmesh.material).equals(cloned_mat);
    });

    it("sets mesh omega_entity", function(){
      ship.init_gfx();
      ship._retrieve_async_resource.omega_callback()(geo);
      assert(ship.mesh.omega_entity).equals(ship);
    });

    it("adds position tracker to components", function(){
      ship.init_gfx();
      assert(ship.components).includes(ship.position_tracker());
    });

    it("adds location tracker to position tracker", function(){
      ship.init_gfx();
      assert(ship.position_tracker().children).includes(ship.location_tracker());
    });

    it("adds mesh to location tracker", function(){
      ship.init_gfx();
      ship._retrieve_async_resource.omega_callback()(geo);
      assert(ship.location_tracker().children).includes(ship.mesh.tmesh);
    });

    it("add highlight effects to position tracker", function(){
      ship.init_gfx();
      assert(ship.position_tracker().children).includes(ship.highlight.mesh);
    });

    it("adds hp bar to position tracker", function(){
      ship.init_gfx();
      assert(ship.position_tracker().children).includes(ship.hp_bar.bar.component1);
      assert(ship.position_tracker().children).includes(ship.hp_bar.bar.component2);
    });

    it("clones Ship highlight effects", function(){
      ship.init_gfx();
      assert(ship.highlight).equals(highlight);
    });

    it("sets omega_entity on highlight effects", function(){
      ship.init_gfx();
      assert(ship.highlight.omega_entity).equals(ship);
    });

    it("clones Ship lamps", function(){
      ship.init_gfx();
      assert(ship.lamps).equals(lamps);
      assert(ship.lamps.omega_entity).equals(ship);
    });

    it("initializes lamp graphics", function(){
      sinon.spy(lamps, 'init_gfx');
      ship.init_gfx();
      sinon.assert.called(lamps.init_gfx);
    });

    it("clones Ship trails", function(){
      ship.init_gfx();
      assert(ship.trails).equals(trails);
      assert(ship.trails.omega_entity).equals(ship);
    });

    it("adds trails to location tracker", function(){
      ship.init_gfx();
      assert(ship.location_tracker().children).includes(ship.trails.particles.mesh);
    });

    it("clones Ship visited route", function(){
      ship.init_gfx();
      assert(ship.visited_route).equals(visited);
      assert(ship.visited_route.omega_entity).equals(ship);
    });

    it("clones Ship attack vector", function(){
      ship.init_gfx();
      assert(ship.attack_vector).equals(attack_vector);
      assert(ship.attack_vector.omega_entity).equals(ship);
    });

    it("sets attack vector position", function(){
      sinon.spy(attack_vector, 'set_position');
      ship.init_gfx();
      sinon.assert.calledWith(attack_vector.set_position, ship.position_tracker().position);
    });

    it("clones Ship mining vector", function(){
      ship.init_gfx();
      assert(ship.mining_vector).equals(mining_vector);
      assert(ship.mining_vector.omega_entity).equals(ship);
    });

    it("clones Ship trajectory vectors", function(){
      ship.init_gfx();
      assert(ship.trajectory1).equals(trajectory1);
      assert(ship.trajectory2).equals(trajectory2);
      assert(ship.trajectory1.omega_entity).equals(ship);
      assert(ship.trajectory2.omega_entity).equals(ship);
    });

    it("updates trajectories", function(){
      sinon.spy(trajectory1, 'update');
      sinon.spy(trajectory2, 'update');
      ship.init_gfx();
      sinon.assert.called(ship.trajectory1.update);
      sinon.assert.called(ship.trajectory2.update);
    });

    describe("debug graphics are enabled", function(){
      it("adds trajectory graphics to mesh", function(){
        ship.debug_gfx = true;
        ship.init_gfx();
        ship._retrieve_async_resource.omega_callback()(geo);
        assert(ship.mesh.tmesh.children).includes(ship.trajectory1.mesh);
        assert(ship.mesh.tmesh.children).includes(ship.trajectory2.mesh);
      });
    });

    it("clones Ship hp progress bar", function(){
      ship.init_gfx();
      assert(ship.hp_bar).equals(hp_bar);
      assert(ship.hp_bar.omega_entity).equals(ship);
    });

    it("initializes hp bar gfx", function(){
      sinon.spy(hp_bar.bar, 'init_gfx');
      ship.init_gfx();
      sinon.assert.called(ship.hp_bar.bar.init_gfx);
    });

    it("clones ship destruction effects", function(){
      ship.init_gfx();
      assert(ship.destruction).equals(destruction);
      assert(ship.destruction.omega_entity).equals(ship);
    });

    it("sets destruction position", function(){
      sinon.spy(destruction, 'set_position');
      ship.init_gfx();
      sinon.assert.calledWith(ship.destruction.set_position, ship.position_tracker().position);
    });

    it("creates local references to ship audio", function(){
      ship.init_gfx();
      assert(ship.destruction_audio).equals(ship._retrieve_resource('destruction_audio'));
      assert(ship.combat_audio).equals(ship._retrieve_resource('combat_audio'));
      assert(ship.movement_audio).equals(ship._retrieve_resource('movement_audio'));
      assert(ship.mining_audio).equals(ship._retrieve_resource('mining_audio'));
      assert(ship.docking_audio).equals(ship._retrieve_resource('docking_audio'));
      assert(ship.mining_completed_audio).equals(ship._retrieve_resource('mining_completed_audio'));
    });

    it("clones ship explosion effects", function(){
      ship.init_gfx();
      assert(ship.explosions).equals(explosions);
      assert(ship.explosions.omega_entity).equals(ship);
      sinon.assert.calledWith(ship._retrieve_resource('explosions').for_ship, ship);
    });

    it("clones ship smoke effects", function(){
      ship.init_gfx();
      assert(ship.smoke).equals(smoke);
      assert(ship.smoke.omega_entity).equals(ship);
    });

    it("adds smoke effects to position tracker", function(){
      ship.init_gfx();
      assert(ship.position_tracker().children).includes(ship.smoke.particles.mesh);
    });

    it("sets scene components to ship position tracker, visited, mining_vector, destruction, and explosions", function(){
      ship.init_gfx();
      assert(ship.components).includes(ship.position_tracker());
      assert(ship.components).includes(ship.visited_route.line);
      assert(ship.components).includes(ship.mining_vector.particles.mesh);
      assert(ship.components).includes(ship.destruction.particles.mesh);
      assert(ship.components).includes(ship.explosions.particles.mesh);
    });

    it("adds lamps to mesh", function(){
      ship.init_gfx();
      ship._retrieve_async_resource.omega_callback()(geo);
      var children = ship.mesh.tmesh.children;
      for(var l = 0; l < ship.lamps.olamps.length; l++)
        assert(children).includes(ship.lamps.olamps[l].component);
    });

    it("updates_gfx", function(){
      sinon.spy(ship, 'update_gfx');
      ship.init_gfx();
      sinon.assert.called(ship.update_gfx);
    });

    it("updates movement effects", function(){
      sinon.spy(ship, 'update_movement_effects');
      ship.init_gfx();
      sinon.assert.called(ship.update_movement_effects);
    });
  });

  describe("#update_attack_gfx", function(){
    it("updates attack vector state", function(){
      ship.init_gfx();
      sinon.spy(ship.attack_vector, 'update_state');
      ship.update_attack_gfx();
      sinon.assert.called(ship.attack_vector.update_state);
    });

    it("updates attack vector", function(){
      ship.init_gfx();
      sinon.spy(ship.attack_vector, 'update');
      ship.update_attack_gfx();
      sinon.assert.called(ship.attack_vector.update);
    });

    it("updates explosions state", function(){
      ship.init_gfx();
      sinon.spy(ship.explosions, 'update_state');
      ship.update_attack_gfx();
      sinon.assert.called(ship.explosions.update_state);
    });
  });

  describe("#update_defense_gfx", function(){
    it("updates hp bar", function(){
      ship.init_gfx();
      sinon.spy(ship.hp_bar, 'update');
      ship.update_defense_gfx();
      sinon.assert.called(ship.hp_bar.update);
    });

    it("updates smoke effects state", function(){
      ship.init_gfx();
      sinon.spy(ship.smoke, 'update_state');
      ship.update_defense_gfx();
      sinon.assert.called(ship.smoke.update_state);
    });
  });

  describe("#update_mining_gfx", function(){
    it("updates mining vector", function(){
      ship.init_gfx();
      sinon.spy(ship.mining_vector, 'update');
      ship.update_mining_gfx();
      sinon.assert.called(ship.mining_vector.update);
    });

    it("updates mining vector state", function(){
      ship.init_gfx();
      sinon.spy(ship.mining_vector, 'update_state');
      ship.update_mining_gfx();
      sinon.assert.called(ship.mining_vector.update_state);
    });
  });

  describe("#update_movement_effects", function(){
    describe("ship is moving linearily", function(){
      it("sets run_movement callback to run_linear_movement", function(){
        ship.location.movement_strategy =
          {json_class : 'Motel::MovementStrategies::Linear'};
        ship.update_movement_effects();
        assert(ship._run_movement).equals(ship._run_linear_movement);
      });
    });

    describe("ship is moving using follow strategy", function(){
      it("sets run_movement callback to run_follow_movement", function(){
        ship.location.movement_strategy =
          {json_class : 'Motel::MovementStrategies::Follow'};
        ship.update_movement_effects();
        assert(ship._run_movement).equals(ship._run_follow_movement);
      });
    });

    describe("ship is moving using rotate strategy", function(){
      it("sets run_movement callback to run_rotation_movement", function(){
        ship.location.movement_strategy =
          {json_class : 'Motel::MovementStrategies::Rotate'};
        ship.update_movement_effects();
        assert(ship._run_movement).equals(ship._run_rotation_movement);
      });
    });

    describe("ship is stopped", function(){
      it("sets run_movement callback to no_movement", function(){
        ship.location.movement_strategy =
          {json_class : 'Motel::MovementStrategies::Stopped'};
        ship.update_movement_effects();
        assert(ship._run_movement).equals(ship._no_movement);
      });
    });

    it("updates trails", function(){
      ship.init_gfx();
      sinon.stub(ship.trails, 'update_state');
      ship.update_movement_effects();
      sinon.assert.called(ship.trails.update_state);
    });
  });

  describe("#_run_linear_movement", function(){
    before(function(){
      ship.init_gfx();
    });

    it("moves ship along linear path", function(){
      ship.location.set(0, 0, 0);
      ship.location.set_orientation(1, 0, 0);
      ship.location.movement_strategy = {speed : 10};
      ship.last_moved = new Date(new Date() - 1000); // last moved 1s ago
      ship._run_linear_movement();
      assert(ship.location.coordinates()).isSameAs([10, 0, 0]);
    });

    it("updates gfx", function(){
      sinon.stub(ship, 'update_gfx');
      ship._run_linear_movement();
      sinon.assert.called(ship.update_gfx);
    });

    it("sets last movement to now", function(){
      ship._run_linear_movement();
      assert(ship.last_moved).isNotNull();
    });

    it("dispatches movement event", function(){
      var spy = sinon.spy();
      ship.addEventListener('movement', spy);
      ship._run_linear_movement();
      sinon.assert.called(spy);
    });
  });

  describe("#_run_rotation_movement", function(){
    var page;

    before(function(){
      ship.init_gfx();
      ship.location.set_orientation(1, 0, 0);
      ship.location.movement_strategy = {rot_x : 0, rot_y : 0, rot_z : 1, rot_theta : Math.PI/2};
      page = Omega.Test.Page();
    });

    it("rotates ship according to rotation strategy", function(){
      ship._run_rotation_movement(page, 1000);
      var orientation = ship.location.orientation();
      assert(orientation[0]).close(0, 0.00001);
      assert(orientation[1]).close(1);
      assert(orientation[2]).close(0);
    });

    it("updates gfx", function(){
      sinon.stub(ship, 'update_gfx');
      ship._run_rotation_movement();
      sinon.assert.called(ship.update_gfx);
    });

    it("sets last movement to now", function(){
      ship._run_rotation_movement();
      assert(ship.last_moved).isNotNull();
    });

    it("dispatches movement event", function(){
      var spy = sinon.spy();
      ship.addEventListener('movement', spy);
      ship._run_rotation_movement();
      sinon.assert.called(spy);
    });
  });

  describe("#_run_follow_movement", function(){
    var distance, page, tracked;

    before(function(){
      distance = Omega.Config.follow_distance;

      tracked = Omega.Gen.ship();
      tracked.location.set(0, 0, 0);

      ship.init_gfx();
      ship.location.movement_strategy = 
        {json_class : 'Motel::MovementStrategies::Follow',
         tracked_location_id : tracked.id,
         distance : distance};
      ship.location.set(distance + 100, 0, 0);

      page = Omega.Test.Page();
      page.entity(tracked.id, tracked);
    });

    after(function(){
      page.clear_entities();
    });

    describe("ship is orienting itself towards target", function(){
      it("_runs_rotation_movement", function(){
        ship.location.movement_strategy.point_to_target = true;
        sinon.spy(ship, '_run_rotation_movement');
        ship.last_moved = new Date(new Date() - 1000); // last moved 1s ago
        ship._run_follow_movement(page);
        sinon.assert.calledWith(ship._run_rotation_movement, page, 1000);
      });
    });

    describe("ship is not facing target", function(){
      it("faces target / runs rotation movement", function(){
        ship.location.movement_strategy.point_to_target = false;
        ship.location.set_orientation(1, 0, 0);

        sinon.spy(ship.location, 'face_target');
        sinon.spy(ship, '_run_rotation_movement');

        ship.last_moved = new Date(new Date() - 1000);
        ship._run_follow_movement(page);
        sinon.assert.called(ship.location.face_target);
        sinon.assert.calledWith(ship._run_rotation_movement, page, 1000)
      });
    });

    describe("ship is not on target", function(){
      it("moves ship towards target", function(){
        var coordinates = ship.location.coordinates();
        ship.location.set_orientation(-1, 0, 0);

        var dist = ship.location.distance_from(tracked.location);
        var dx   = (tracked.location.x - ship.location.x) / dist;
        var dy   = (tracked.location.y - ship.location.y) / dist;
        var dz   = (tracked.location.z - ship.location.z) / dist;

        ship.location.movement_strategy.speed = 1;
        ship.last_moved = new Date(new Date() - 1000); // last moved 1s ago
        ship._run_follow_movement(page);
        assert(ship.location.x).equals(coordinates[0] + dx);
        assert(ship.location.y).equals(coordinates[1] + dy);
        assert(ship.location.z).equals(coordinates[2] + dz);
      });
    });

    describe("ship is on target and target is moving", function(){
      it("matches target speed", function(){
        ship.location.movement_strategy.speed = 100;
        tracked.location.movement_strategy.speed = 10;
        tracked.location.set(ship.location.coordinates());
        ship.last_moved = new Date(new Date() - 1000); // last moved 1s ago

        sinon.spy(ship.location, 'move_linear')
        ship._run_follow_movement(page);
        sinon.assert.calledWith(ship.location.move_linear, 10);
      });
    });

    describe("ship is on target and target not moving", function(){
      it("orbits target", function(){
        ship.last_moved = new Date(new Date() - 1000); // last moved 1s ago
        tracked.location.set(ship.location.coordinates());
        ship.location.movement_strategy.speed = 10;

        sinon.spy(ship, '_run_rotation_movement');
        sinon.spy(ship.location, 'move_linear');

        ship._run_follow_movement(page);
        sinon.assert.calledWith(ship._run_rotation_movement, page, 1000, true);
        sinon.assert.calledWith(ship.location.move_linear, 10);
      });
    });

    it("updates gfx", function(){
      sinon.stub(ship, 'update_gfx');
      ship._run_follow_movement(page);
      sinon.assert.called(ship.update_gfx);
    });

    it("sets last movement to now", function(){
      ship._run_follow_movement(page);
      assert(ship.last_moved).isNotNull();
    });

    it("dispatches movement event", function(){
      var spy = sinon.spy();
      ship.addEventListener('movement', spy);
      ship._run_follow_movement(page);
      sinon.assert.called(spy);
    });
  });

  //describe("#_run_figure8_movement") // NIY

  describe("#_no_movement", function(){
    it("does nothing / just returns", function(){
      var coordinates = ship.location.coordinates();
      var spy = sinon.spy();
      ship.addEventListener('movement', spy);
      ship._no_movement();
      sinon.assert.notCalled(spy);
      assert(ship.location.coordinates()).isSameAs(coordinates);
    });
  });

  describe("#run_effects", function(){
    var ship;

    before(function(){
      ship = Omega.Gen.ship();
      ship.init_gfx();
    });

    it("runs movement", function(){
      sinon.spy(ship, '_run_movement');
      ship.run_effects();
      sinon.assert.called(ship._run_movement);
    });

    it("runs lamp effects", function(){
      sinon.spy(ship.lamps, 'run_effects');
      ship.run_effects();
      sinon.assert.called(ship.lamps.run_effects);
    });

    it("runs trail effects", function(){
      sinon.spy(ship.trails, 'run_effects');
      ship.run_effects();
      sinon.assert.called(ship.trails.run_effects);
    });

    it("runs visited route effects", function(){
      sinon.spy(ship.visited_route, 'run_effects');
      ship.run_effects();
      sinon.assert.called(ship.visited_route.run_effects);
    });

    it("runs attack component effects", function(){
      sinon.spy(ship.attack_component(), 'run_effects');
      ship.run_effects();
      sinon.assert.called(ship.attack_component().run_effects);
    });

    it("runs mining vector effects", function(){
      sinon.spy(ship.mining_vector, 'run_effects');
      ship.run_effects();
      sinon.assert.called(ship.mining_vector.run_effects);
    });

    it("runs destruction effects", function(){
      sinon.spy(ship.destruction, 'run_effects');
      ship.run_effects();
      sinon.assert.called(ship.destruction.run_effects);
    });

    it("runs smoke effects", function(){
      sinon.spy(ship.smoke, 'run_effects');
      ship.run_effects();
      sinon.assert.called(ship.smoke.run_effects);
    });
  });

  describe("#update_gfx", function(){
    var ship;

    before(function(){
      ship = new Omega.Ship({type : 'corvette', location : new Omega.Location()});
      ship.init_gfx();
    });

    it("sets position tracker position from scene location", function(){
      sinon.spy(ship.position_tracker().position, 'set');
      ship.update_gfx();
      sinon.assert.calledWith(ship.position_tracker().position.set,
                              ship.location.x,
                              ship.location.y,
                              ship.location.z);
    });

    it("sets location tracker rotation from location rotation", function(){
      var matrix = new THREE.Matrix4();
      sinon.stub(ship.location, 'rotation_matrix').returns(matrix);
      sinon.spy(ship.location_tracker().rotation, 'setFromRotationMatrix');
      ship.update_gfx();
      sinon.assert.calledWith(ship.location_tracker().rotation.setFromRotationMatrix, matrix);
    });

    it("updates attack component", function(){
      sinon.stub(ship.attack_component(), 'update');
      ship.update_gfx();
      sinon.assert.called(ship.attack_component().update);
    });

    it("updates attack & mining vectors", function(){
      var update_attack = sinon.spy(ship.attack_vector, 'update');
      var update_mining = sinon.spy(ship.mining_vector, 'update');
      ship.update_gfx();
      sinon.assert.called(update_attack);
      sinon.assert.called(update_mining);
    });
  });
});});
