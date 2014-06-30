// Test mixin usage through ship
pavlov.specify("Omega.ShipGfx", function(){
describe("Omega.ShipGfx", function(){
  var ship;

  before(function(){
    ship = Omega.Gen.ship();
  });

  describe("#load_gfx", function(){
    describe("graphics are loaded", function(){
      var orig_gfx;

      before(function(){
        orig_gfx = Omega.Ship.gfx;
        Omega.Ship.gfx = null;
        sinon.stub(ship, 'gfx_loaded').returns(true);
      });

      after(function(){
        Omega.Ship.gfx = orig_gfx;
      });

      it("does nothing / just returns", function(){
        ship.load_gfx();
        assert(Omega.Ship.gfx).isNull();
      });
    });

    it("creates mesh for Ship", function(){
      assert(Omega.Ship.gfx[ship.type].mesh).isOfType(Omega.ShipMesh);
    });

    it("creates highlight effects for Ship", function(){
      assert(Omega.Ship.gfx[ship.type].highlight).
        isOfType(Omega.ShipHighlightEffects);
    });

    it("creates lamps for Ship", function(){
      assert(Omega.Ship.gfx[ship.type].lamps).isOfType(Omega.ShipLamps);
    });

    it("creates trails for Ship", function(){
      assert(Omega.Ship.gfx[ship.type].trails).isOfType(Omega.ShipTrails);
    });

    it("creates attack vector for Ship", function(){
      var ship = Omega.Test.Canvas.Entities().ship;
      assert(Omega.Ship.gfx[ship.type].attack_vector).
        isOfType(Omega.ShipAttackVector);
    });

    it("creates mining vector for Ship", function(){
      var ship = Omega.Test.Canvas.Entities().ship;
      assert(Omega.Ship.gfx[ship.type].mining_vector).
        isOfType(Omega.ShipMiningVector);
    });

    it("creates trajectory vectors for ship", function(){
      var ship = Omega.Test.Canvas.Entities().ship;
      assert(Omega.Ship.gfx[ship.type].trajectory1).isOfType(Omega.ShipTrajectory);
      assert(Omega.Ship.gfx[ship.type].trajectory2).isOfType(Omega.ShipTrajectory);
    });

    //it("creates progress bar for ship hp", function(){ // NIY
    //  var ship = Omega.Test.Canvas.Entities().ship;
    //  assert(Omega.Ship.gfx[ship.type].hp_bar).isOfType(Omega.UI.Canvas.ProgressBar);
    //})

    it("creates destruction effects for ship", function(){
      var ship = Omega.Test.Canvas.Entities().ship;
      assert(Omega.Ship.gfx[ship.type].destruction).
        isOfType(Omega.ShipDestructionEffect);
    });

    it("creates explosion effects for ship", function(){
      var ship = Omega.Test.Canvas.Entities().ship;
      assert(Omega.Ship.gfx[ship.type].explosions).
        isOfType(Omega.ShipExplosionEffect);
    });

    it("creates smoke effects for ship", function(){
      var ship = Omega.Test.Canvas.Entities().ship;
      assert(Omega.Ship.gfx[ship.type].smoke).
        isOfType(Omega.ShipSmokeEffect);
    });

    it("creates docking audio for ship", function(){
      var ship = Omega.Test.Canvas.Entities().ship;
      assert(Omega.Ship.gfx[ship.type].docking_audio).
        isOfType(Omega.ShipDockingAudioEffect);
    });

    it("creates mining audio for ship", function(){
      var ship = Omega.Test.Canvas.Entities().ship;
      assert(Omega.Ship.gfx[ship.type].mining_completed_audio).
        isOfType(Omega.ShipMiningCompletedAudioEffect);
    });

    it("creates destruction audio for ship", function(){
      var ship = Omega.Test.Canvas.Entities().ship;
      assert(Omega.Ship.gfx[ship.type].destruction_audio).
        isOfType(Omega.ShipDestructionAudioEffect);
    });

    it("creates mining completed audio for ship", function(){
      var ship = Omega.Test.Canvas.Entities().ship;
      assert(Omega.Ship.gfx[ship.type].mining_completed_audio).
        isOfType(Omega.ShipMiningCompletedAudioEffect);
    });

    it("creates combat audio for ship", function(){
      var ship = Omega.Test.Canvas.Entities().ship;
      assert(Omega.Ship.gfx[ship.type].combat_audio).
        isOfType(Omega.ShipCombatAudioEffect);
    });

    it("creates movement audio for ship", function(){
      var ship = Omega.Test.Canvas.Entities().ship;
      assert(Omega.Ship.gfx[ship.type].movement_audio).
        isOfType(Omega.ShipMovementAudioEffect);
    });
  });

  describe("#init_gfx", function(){
    var type = 'corvette';
    var ship;

    before(function(){
      /// preiinit using test page
      Omega.Test.Canvas.Entities();

      ship = Omega.Gen.ship({type: type});
    });

    after(function(){
      if(Omega.Ship.gfx[type].mesh.clone.restore)
        Omega.Ship.gfx[type].mesh.clone.restore();

      if(Omega.Ship.gfx[type].highlight.clone.restore)
        Omega.Ship.gfx[type].highlight.clone.restore();

      for(var l = 0; l < Omega.Ship.gfx[type].lamps.length; l++)
        if(Omega.Ship.gfx[type].lamps[l].clone.restore)
          Omega.Ship.gfx[type].lamps[l].clone.restore();

      if(Omega.Ship.gfx[type].lamps.clone.restore)
        Omega.Ship.gfx[type].lamps.clone.restore();

      if(Omega.Ship.gfx[type].trails.clone.restore)
        Omega.Ship.gfx[type].trails.clone.restore();

      if(Omega.Ship.gfx[type].attack_vector.clone.restore)
        Omega.Ship.gfx[type].attack_vector.clone.restore();

      if(Omega.Ship.gfx[type].mining_vector.clone.restore)
        Omega.Ship.gfx[type].mining_vector.clone.restore();

      if(Omega.Ship.gfx[type].trajectory1.clone.restore)
        Omega.Ship.gfx[type].trajectory1.clone.restore();

      if(Omega.Ship.gfx[type].trajectory2.clone.restore)
        Omega.Ship.gfx[type].trajectory2.clone.restore();

      if(Omega.Ship.gfx[type].hp_bar.clone.restore)
        Omega.Ship.gfx[type].hp_bar.clone.restore();

      if(Omega.Ship.gfx[type].destruction.clone.restore)
        Omega.Ship.gfx[type].destruction.clone.restore();

      if(Omega.Ship.gfx[type].explosions.for_ship.restore)
        Omega.Ship.gfx[type].explosions.for_ship.restore();

      if(Omega.Ship.gfx[type].smoke.clone.restore)
        Omega.Ship.gfx[type].smoke.clone.restore();

      if(Omega.Ship.prototype.retrieve_resource.restore)
        Omega.Ship.prototype.retrieve_resource.restore();
    });

    it("loads ship gfx", function(){
      sinon.spy(ship, 'load_gfx');
      ship.init_gfx(Omega.Config);
      sinon.assert.called(ship.load_gfx);
    });

    it("clones template mesh", function(){
      var mesh   = new Omega.ShipMesh({mesh: new THREE.Mesh()});
      var cloned = new Omega.ShipMesh({mesh: new THREE.Mesh()});

      sinon.stub(Omega.Ship.prototype, 'retrieve_resource');
      ship.init_gfx(Omega.Config);
      sinon.assert.calledWith(Omega.Ship.prototype.retrieve_resource,
                              'template_mesh_' + ship.type,
                              sinon.match.func);

      var clone = sinon.stub(mesh, 'clone').returns(cloned);
      Omega.Ship.prototype.retrieve_resource.omega_callback()(mesh);
      assert(ship.mesh).equals(cloned);
    });

    it("sets mesh base position/rotation", function(){
      ship.init_gfx(Omega.Config);
      var template_mesh = Omega.Ship.gfx[ship.type].mesh;
      assert(ship.mesh.base_position).equals(template_mesh.base_position);
      assert(ship.mesh.base_rotation).equals(template_mesh.base_rotation);
    });

    it("sets mesh omega_entity", function(){
      ship.init_gfx(Omega.Config);
      assert(ship.mesh.omega_entity).equals(ship);
    });

    it("updates_gfx in mesh cb", function(){
      sinon.stub(Omega.Ship.prototype, 'retrieve_resource');
      ship.init_gfx(Omega.Config, type);
      var mesh_cb = Omega.Ship.prototype.retrieve_resource.omega_callback();

      sinon.spy(ship, 'update_gfx');
      mesh_cb(Omega.Ship.gfx[ship.type].mesh);
      sinon.assert.called(ship.update_gfx);
    });

    it("adds position tracker to components", function(){
      ship.init_gfx(Omega.Config);
      assert(ship.components).includes(ship.position_tracker());
    });

    it("adds location tracker to position tracker", function(){
      ship.init_gfx(Omega.Config);
      assert(ship.position_tracker().getDescendants()).
        includes(ship.location_tracker());
    });

    it("adds mesh to location tracker", function(){
      ship.init_gfx(Omega.Config);
      assert(ship.location_tracker().getDescendants()).
        includes(ship.mesh.tmesh);
    });

    it("add highlight effects to position tracker", function(){
      ship.init_gfx(Omega.Config);
      assert(ship.position_tracker().getDescendants()).
        includes(ship.highlight.mesh);
    });

    it("adds hp bar to position tracker", function(){
      ship.init_gfx(Omega.Config);
      assert(ship.position_tracker().getDescendants()).
        includes(ship.hp_bar.bar.component1);
      assert(ship.position_tracker().getDescendants()).
        includes(ship.hp_bar.bar.component2);
    });

    it("clones Ship highlight effects", function(){
      var mesh = new Omega.ShipHighlightEffects();
      sinon.stub(Omega.Ship.gfx[type].highlight, 'clone').returns(mesh);
      ship.init_gfx(Omega.Config);
      assert(ship.highlight).equals(mesh);
    });

    it("sets omega_entity on highlight effects", function(){
      ship.init_gfx(Omega.Config);
      assert(ship.highlight.omega_entity).equals(ship);
    });

    it("clones Ship lamps", function(){
      var lamps = new Omega.ShipLamps();
      sinon.stub(Omega.Ship.gfx[ship.type].lamps, 'clone').returns(lamps);
      ship.init_gfx(Omega.Config);
      assert(ship.lamps).equals(lamps);
    });

    /// it("initializes lamp graphics"); NIY

    it("clones Ship trails", function(){
      var trails = new Omega.ShipTrails({config: Omega.Config, type : type});
      sinon.stub(Omega.Ship.gfx[ship.type].trails, 'clone').returns(trails);
      ship.init_gfx(Omega.Config);
      assert(ship.trails).equals(trails);
    });

    it("clones Ship attack vector", function(){
      var mesh = new Omega.ShipAttackVector();
      sinon.stub(Omega.Ship.gfx[type].attack_vector, 'clone').returns(mesh);
      ship.init_gfx(Omega.Config);
      assert(ship.attack_vector).equals(mesh);
    });

    it("clones Ship mining vector", function(){
      var mesh = new Omega.ShipMiningVector();
      sinon.stub(Omega.Ship.gfx[type].mining_vector, 'clone').returns(mesh);
      ship.init_gfx(Omega.Config);
      assert(ship.mining_vector).equals(mesh);
    });

    it("clones Ship trajectory vectors", function(){
      var line1 = Omega.Ship.gfx[type].trajectory1.clone();
      var line2 = Omega.Ship.gfx[type].trajectory1.clone();
      sinon.stub(Omega.Ship.gfx[type].trajectory1, 'clone').returns(line1);
      sinon.stub(Omega.Ship.gfx[type].trajectory2, 'clone').returns(line2);
      ship.init_gfx(Omega.Config);
      assert(ship.trajectory1).equals(line1);
      assert(ship.trajectory2).equals(line2);
    });

    describe("debug graphics are enabled", function(){
      it("adds trajectory graphics to mesh", function(){
        ship.debug_gfx = true;
        ship.init_gfx(Omega.Config);
        assert(ship.mesh.tmesh.getDescendants()).includes(ship.trajectory1.mesh);
        assert(ship.mesh.tmesh.getDescendants()).includes(ship.trajectory2.mesh);
      });
    });

    it("clones Ship hp progress bar", function(){
      var hp_bar = Omega.Ship.gfx[type].hp_bar.clone(); 
      sinon.stub(Omega.Ship.gfx[type].hp_bar, 'clone').returns(hp_bar);
      ship.init_gfx(Omega.Config);
      assert(ship.hp_bar).equals(hp_bar);
    });

    it("clones ship destruction effects", function(){
      var destruction = Omega.Ship.gfx[type].destruction.clone(); 
      sinon.stub(Omega.Ship.gfx[type].destruction, 'clone').returns(destruction);
      ship.init_gfx(Omega.Config);
      assert(ship.destruction).equals(destruction);
    });

    it("creates local references to ship audio", function(){
      ship.init_gfx(Omega.Config);
      assert(ship.destruction_audio).equals(Omega.Ship.gfx[type].destruction_audio);
      assert(ship.combat_audio).equals(Omega.Ship.gfx[type].combat_audio);
      assert(ship.movement_audio).equals(Omega.Ship.gfx[type].movement_audio);
    });

    it("clones ship explosion effects", function(){
      var explosions = new Omega.ShipExplosionEffect();
      sinon.stub(Omega.Ship.gfx[type].explosions, 'for_ship').returns(explosions);
      ship.init_gfx(Omega.Config);
      assert(ship.explosions).equals(explosions);
      assert(ship.explosions.omega_entity).equals(ship);
      sinon.assert.calledWith(Omega.Ship.gfx[type].explosions.for_ship, ship);
    });

    it("clones ship smoke effects", function(){
      var smoke = new Omega.ShipSmokeEffect();
      sinon.stub(Omega.Ship.gfx[type].smoke, 'clone').returns(smoke);
      ship.init_gfx(Omega.Config);
      assert(ship.smoke).equals(smoke);
    });

    it("sets scene components to ship position tracker, trails, attack_vector, mining_vector, destruction, explosions, and smoke", function(){
      ship.init_gfx(Omega.Config);
      assert(ship.components).includes(ship.position_tracker());
      assert(ship.components).includes(ship.trails.particles.mesh);
      assert(ship.components).includes(ship.attack_vector.particles.mesh);
      assert(ship.components).includes(ship.mining_vector.particles.mesh);
      assert(ship.components).includes(ship.destruction.particles.mesh);
      assert(ship.components).includes(ship.explosions.particles.mesh);
      assert(ship.components).includes(ship.smoke.particles.mesh);
    });

    it("adds lamps to mesh", function(){
      ship.init_gfx(Omega.Config);
      var descendants = ship.mesh.tmesh.getDescendants();
      for(var l = 0; l < ship.lamps.olamps.length; l++)
        assert(descendants).includes(ship.lamps.olamps[l].component);
    });

    it("updates_gfx", function(){
      sinon.spy(ship, 'update_gfx');
      ship.init_gfx(Omega.Config);
      sinon.assert.called(ship.update_gfx);
    });

    it("updates movement effects", function(){
      sinon.spy(ship, 'update_movement_effects');
      ship.init_gfx(Omega.Config);
      sinon.assert.called(ship.update_movement_effects);
    });
  });

  describe("#update_attack_gfx", function(){
    it("updates attack vector state", function(){
      ship.init_gfx(Omega.Config);
      sinon.spy(ship.attack_vector, 'update_state');
      ship.update_attack_gfx();
      sinon.assert.called(ship.attack_vector.update_state);
    });

    it("updates attack vector", function(){
      ship.init_gfx(Omega.Config);
      sinon.spy(ship.attack_vector, 'update');
      ship.update_attack_gfx();
      sinon.assert.called(ship.attack_vector.update);
    });

    it("updates explosions state", function(){
      ship.init_gfx(Omega.Config);
      sinon.spy(ship.explosions, 'update_state');
      ship.update_attack_gfx();
      sinon.assert.called(ship.explosions.update_state);
    });
  });

  describe("#update_defense_gfx", function(){
    it("updates hp bar", function(){
      ship.init_gfx(Omega.Config);
      sinon.spy(ship.hp_bar, 'update');
      ship.update_defense_gfx();
      sinon.assert.called(ship.hp_bar.update);
    });

    it("updates smoke effects", function(){
      ship.init_gfx(Omega.Config);
      sinon.spy(ship.smoke, 'update');
      ship.update_defense_gfx();
      sinon.assert.called(ship.smoke.update);
    });

    it("updates smoke effects state", function(){
      ship.init_gfx(Omega.Config);
      sinon.spy(ship.smoke, 'update_state');
      ship.update_defense_gfx();
      sinon.assert.called(ship.smoke.update_state);
    });
  });

  describe("#update_mining_gfx", function(){
    it("updates mining vector", function(){
      ship.init_gfx(Omega.Config);
      sinon.spy(ship.mining_vector, 'update');
      ship.update_mining_gfx();
      sinon.assert.called(ship.mining_vector.update);
    });

    it("updates mining vector state", function(){
      ship.init_gfx(Omega.Config);
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
      ship.init_gfx(Omega.Config);
      sinon.stub(ship.trails, 'update_state');
      ship.update_movement_effects();
      sinon.assert.called(ship.trails.update_state);
    });
  });

  describe("#_run_linear_movement", function(){
    before(function(){
      ship.init_gfx(Omega.Config);
    });

    it("moves ship along linear path", function(){
      ship.location.set(0, 0, 0);
      ship.location.movement_strategy =
        {dx : 1, dy : 0, dz : 0, speed : 10};
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
      ship.init_gfx(Omega.Config);
      page = Omega.Test.Page();
    });

    it("rotates ship according to rotation strategy", function(){
      ship.location.set_orientation(1, 0, 0);
      ship.location.movement_strategy =
        {rot_x : 0, rot_y : 0, rot_z : 1, rot_theta : Math.PI/2};
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
    var page, tracked;

    before(function(){
      tracked = Omega.Gen.ship();
      tracked.location.set(0, 0, 0);

      ship.init_gfx(Omega.Config);
      ship.location.movement_strategy = 
        {json_class : 'Motel::MovementStrategies::Follow',
         tracked_location_id : tracked.id};
      ship.location.set(Omega.Config.follow_distance + 100, 0, 0);

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
      it("does not move ship", function(){
        ship.location.movement_strategy.point_to_target = false;
        ship.location.set_orientation(1, 0, 0);

        var orig = ship.location.coordinates();
        ship._run_follow_movement(page);
        assert(ship.location.coordinates()).isSameAs(orig);
      });
    });

    describe("ship is not on target && further away than min follow distance", function(){
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

    describe("ship is on target and within min follow distance", function(){
      it("does not move ship", function(){
        var coordinates = ship.location.coordinates();
        tracked.location.set(coordinates);
        ship._run_follow_movement(page);
        assert(ship.location.coordinates()).isSameAs(coordinates);
      });
    });

    describe("ship is on target", function(){
      it("updates movement effects", function(){
        sinon.stub(ship.location, 'on_target').returns(true);
        sinon.spy(ship, 'update_movement_effects');
        ship._run_follow_movement(page);
        sinon.assert.called(ship.update_movement_effects);
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
      ship.init_gfx(Omega.Config);
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

    it("runs attack vector effects", function(){
      sinon.spy(ship.attack_vector, 'run_effects');
      ship.run_effects();
      sinon.assert.called(ship.attack_vector.run_effects);
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
      ship.init_gfx(Omega.Config);
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

    it("updates trails", function(){
      sinon.stub(ship.trails, 'update');
      ship.update_gfx();
      sinon.assert.called(ship.trails.update);
    });

    it("updates attack & mining vectors", function(){
      var update_attack = sinon.spy(ship.attack_vector, 'update');
      var update_mining = sinon.spy(ship.mining_vector, 'update');
      ship.update_gfx();
      sinon.assert.called(update_attack);
      sinon.assert.called(update_mining);
    });

    it("updates smoke", function(){
      sinon.stub(ship.smoke, 'update');
      ship.update_gfx();
      sinon.assert.called(ship.smoke.update);
    });
  });
});});
