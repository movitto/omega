/// Test Mixin usage through Planet
pavlov.specify("Omega.PlanetGfxInitializer", function(){
describe("Omega.PlanetGfxInitializer", function(){
  describe("#init_gfx", function(){
    var event_cb, planet, mesh, axis;

    before(function(){
      event_cb = function(){};
      planet   = Omega.Gen.planet();
      planet.type = 0;

      mesh = new Omega.PlanetMesh({type : 0});
      sinon.stub(planet._retrieve_resource('mesh'), 'clone').returns(mesh);

      axis = new Omega.PlanetAxis();
      sinon.stub(planet._retrieve_resource('axis'), 'clone').returns(axis);
    });

    after(function(){
      planet._retrieve_resource('mesh').clone.restore();
      planet._retrieve_resource('axis').clone.restore();

      if(Omega.PlanetMaterial.load.restore)
        Omega.PlanetMaterial.load.restore();
    });

    it("loads planet gfx", function(){
      sinon.spy(planet, 'load_gfx');
      planet.init_gfx(event_cb);
      sinon.assert.called(planet.load_gfx);
    });

    it("clones Planet mesh", function(){
      planet.init_gfx(event_cb);
      assert(planet.mesh).equals(mesh);
    });

    it("sets mesh omega_entity", function(){
      planet.init_gfx(event_cb);
      assert(planet.mesh.omega_entity).equals(planet);
    });

    it("clones Planet axis", function(){
      planet.init_gfx(event_cb);
      assert(planet.axis).equals(axis);
    });

    it("sets axis orientation", function(){
      sinon.stub(planet.location, 'orientation').returns([0,1,0]);
      sinon.stub(axis, 'set_orientation');
      planet.init_gfx(event_cb);
      sinon.assert.calledWith(axis.set_orientation, 0, 1, 0);
    });

    it("generates random spin scale", function(){
      planet.init_gfx(event_cb);
      assert(planet.spin_scale).isLessThan(1.25);
      assert(planet.spin_scale).isGreaterThan(0.5);
    });

    it("updates graphics", function(){
      sinon.spy(planet, 'update_gfx');
      planet.init_gfx(event_cb);
      sinon.assert.called(planet.update_gfx);
    });

    it("clacs planet orbit", function(){
      sinon.spy(planet, '_calc_orbit');
      planet.init_gfx(event_cb);
      sinon.assert.called(planet._calc_orbit);
    });

    it("creates orbit line", function(){
      planet.init_gfx(event_cb);
      assert(planet.orbit_line).isOfType(Omega.OrbitLine);
      // TODO verify orbit line init w/ planet's orbit
    });

    it("sets last moved", function(){
      planet.init_gfx(event_cb);
      assert(planet.last_moved).isNotNull();
    });

    it("adds tracker, mesh, and orbit mesh to planet scene components", function(){
      planet.init_gfx(event_cb);
      assert(planet.components[0]).equals(planet.position_tracker());
      assert(planet.components[1]).equals(planet.mesh.tmesh);
      assert(planet.components[2]).equals(planet.orbit_line.line);
    });
  });
});});
