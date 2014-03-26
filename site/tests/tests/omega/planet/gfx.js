/// Test Mixin usage through Planet
pavlov.specify("Omega.PlanetGfx", function(){
describe("Omega.PlanetGfx", function(){
  var planet;

  before(function(){
    planet = new Omega.Planet();
  });

  describe("#load_gfx", function(){
    describe("graphics are initialized", function(){
      var orig_gfx;

      before(function(){
        orig_gfx = Omega.Planet.gfx;
        Omega.Planet.gfx = null;
        sinon.stub(planet, 'gfx_loaded').returns(true)
      });

      after(function(){
        Omega.Planet.gfx = orig_gfx;
      });

      it("does nothing / just returns", function(){
        planet.load_gfx(Omega.Config);
        assert(Omega.Planet.gfx).isNull();
      });
    });

    it("creates mesh for Planet", function(){
      Omega.Test.Canvas.Entities();
      assert(Omega.Planet.gfx[0].mesh).isOfType(Omega.PlanetMesh);
    });
  });

  describe("#init_gfx", function(){
    var config, event_cb, planet;

    before(function(){
      config   = Omega.Config;
      event_cb = function(){};
      planet   = Omega.Gen.planet();
    });

    after(function(){
      if(Omega.Planet.gfx[0].mesh.clone.restore)
        Omega.Planet.gfx[0].mesh.clone.restore();

      if(Omega.PlanetMaterial.load.restore)
        Omega.PlanetMaterial.load.restore();
    });

    it("loads planet gfx", function(){
      sinon.spy(planet, 'load_gfx');
      planet.init_gfx(config, event_cb);
      sinon.assert.called(planet.load_gfx);
    });

    it("clones Planet mesh", function(){
      var mesh = new Omega.PlanetMesh();
      sinon.stub(Omega.Planet.gfx[0].mesh, 'clone').returns(mesh);
      planet.init_gfx(config, event_cb);
      assert(planet.mesh).equals(mesh);
    });

    it("sets mesh omega_entity", function(){
      planet.init_gfx(config, event_cb);
      assert(planet.mesh.omega_entity).equals(planet);
    });

    it("loads/sets planet mesh material", function(){
      var material      = new THREE.Material();
      var load_material = sinon.stub(Omega.PlanetMaterial, 'load');
      load_material.returns(material);

      planet.init_gfx(config, event_cb);
      sinon.assert.calledWith(load_material, config, planet.colori(), event_cb);
    });

    it("updates graphics", function(){
      sinon.spy(planet, 'update_gfx');
      planet.init_gfx(config, event_cb);
      sinon.assert.called(planet.update_gfx);
    });

    it("clacs planet orbit", function(){
      sinon.spy(planet, '_calc_orbit');
      planet.init_gfx(config, event_cb);
      sinon.assert.called(planet._calc_orbit);
    });

    it("creates orbit line", function(){
      planet.init_gfx(config, event_cb);
      assert(planet.orbit_line).isOfType(Omega.OrbitLine);
      // TODO verify orbit line init w/ planet's orbit
    });

    it("adds mesh and orbit mesh to planet scene components", function(){
      planet.init_gfx(config, event_cb);
      assert(planet.components[0]).equals(planet.tracker_obj);
      assert(planet.components[1]).equals(planet.mesh.tmesh);
      assert(planet.components[2]).equals(planet.orbit_line.line);
    });
  });

  describe("#update_gfx", function(){
    it("sets mesh position from planet location", function(){
      var planet = Omega.Test.Canvas.Entities().planet;
      planet.location = new Omega.Location({x : 20, y : 30, z : -20});
      planet.update_gfx();
      assert(planet.mesh.tmesh.position.x).equals( 20);
      assert(planet.mesh.tmesh.position.y).equals( 30);
      assert(planet.mesh.tmesh.position.z).equals(-20);
    });
  });

  describe("#run_effects", function(){
    var pl;

    before(function(){
      pl  = Omega.Gen.planet();
      pl.location.set(10,0,0);
      pl.location.movement_strategy.dmajx = 0;
      pl.location.movement_strategy.dmajy = 0;
      pl.location.movement_strategy.dmajz = 1;
      pl.location.movement_strategy.dminx = 0;
      pl.location.movement_strategy.dminy = 1;
      pl.location.movement_strategy.dminz = 0;

      pl.init_gfx(Omega.Config);
    });

    it("moves planet", function(){
      // XXX sinon-qunit enables fake timers by default
      this.clock.restore();

      pl.last_moved = new Date() - 1000;
      pl.run_effects();
      assert(pl.location.x).close(  0,2);
      assert(pl.location.y).close(  0,2);
      assert(pl.location.z).close(-10,2);
    });

    it("refreshes planet graphics", function(){
      var update_gfx = sinon.spy(pl, 'update_gfx');
      pl.last_moved = new Date();
      pl.run_effects();
      sinon.assert.called(update_gfx);
    });

    it("sets planet last movement time", function(){
      pl.last_moved = null;
      pl.run_effects();
      assert(pl.last_moved).isNotNull();
    });
  });

});});
