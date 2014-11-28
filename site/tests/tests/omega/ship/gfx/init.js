// Test mixin usage through ship
pavlov.specify("Omega.ShipGfxInitializer", function(){
describe("Omega.ShipGfxInitializer", function(){
  var ship;

  before(function(){
    ship = Omega.Gen.ship();
  });

  describe("#init_gfx", function(){
    var type = 'corvette';
    var ship, geo, highlight, lamps, trails, visited, attack_vector, mining_vector,
              trajectory1, trajectory2, hp_bar, destruction, explosions, smoke, material;

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
      material      = new THREE.MeshBasicMaterial();
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
      sinon.stub(ship._retrieve_resource('mesh_material').material, 'clone').returns(material);
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
      ship._retrieve_resource('smoke').clone.restore();
      ship._retrieve_resource('explosions').for_ship.restore();
      ship._retrieve_resource('mesh_material').material.clone.restore();
    });

    it("loads ship gfx", function(){
      sinon.spy(ship, 'load_gfx');
      ship.init_gfx();
      sinon.assert.called(ship.load_gfx);
    });

    it("retrieves Ship geometry and creates mesh", function(){
      var cloned_geo = new THREE.Geometry();
      sinon.stub(geo, 'clone').returns(cloned_geo);

      ship.init_gfx();
      sinon.assert.calledWith(ship._retrieve_async_resource,
                              'ship.'+type+'.mesh_geometry', sinon.match.func);
      assert(ship.mesh).equals(Omega.UI.CanvasEntityGfxStub.instance());

      ship._retrieve_async_resource.omega_callback()(geo);
      assert(ship.mesh).isOfType(Omega.ShipMesh);
      assert(ship.mesh.tmesh.geometry).equals(cloned_geo);
      assert(ship.mesh.tmesh.material).equals(material);
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

    it("adds highlight effects to position tracker", function(){
      ship.include_highlight = true;
      ship.init_gfx();
      assert(ship.position_tracker().children).includes(ship.highlight.mesh);
    });

    it("adds hp bar to position tracker", function(){
      ship.init_gfx();
      assert(ship.position_tracker().children).includes(ship.hp_bar.bar.components[0]);
      assert(ship.position_tracker().children).includes(ship.hp_bar.bar.components[1]);
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

    it("sets scene components to ship position tracker, mining_vector, destruction, and explosions", function(){
      ship.init_gfx();
      assert(ship.components).includes(ship.position_tracker());
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
});});
