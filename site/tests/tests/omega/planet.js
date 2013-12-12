pavlov.specify("Omega.Planet", function(){
describe("Omega.Planet", function(){
  describe("#load_gfx", function(){
    describe("graphics are initialized", function(){
      var orig;

      before(function(){
        orig = {gfx: Omega.Planet.gfx,
                mesh: Omega.Planet.gfx ? Omega.Planet.gfx.mesh : null};
      })

      after(function(){
        Omega.Planet.gfx = orig.gfx;
        if(Omega.Planet.gfx) Omega.Planet.gfx.mesh = orig.mesh;
      });

      it("does nothing / just returns", function(){
        Omega.Planet.gfx = {};
        Omega.Planet.mesh = null;
        new Omega.Planet().load_gfx();
        assert(Omega.Planet.mesh).isNull();
      });
    });

    it("creates mesh for Planet", function(){
      Omega.Test.Canvas.Entities();
      assert(Omega.Planet.gfx.mesh).isOfType(THREE.Mesh);
      assert(Omega.Planet.gfx.mesh.geometry).isOfType(THREE.SphereGeometry);
      assert(Omega.Planet.gfx.mesh.material).isOfType(THREE.MeshLambertMaterial);
    });

    it("creates orbit material for Planet", function(){
      Omega.Test.Canvas.Entities();
      assert(Omega.Planet.gfx.orbit_material).isOfType(THREE.LineBasicMaterial);
    });
  });

  describe("#_load_material", function(){
    it("loads texture corresponding to color", function(){
      var page   = Omega.Test.Page();
      var basepath = 'http://' + page.config.http_host + page.config.url_prefix + page.config.images_path + '/textures/planet';
      var planet = Omega.Test.Canvas.Entities().planet;
      planet.color = '000000';
      var mat = planet._load_material(page.config, function(){});
      assert(mat.map.image.src).equals(basepath + '0.png');
      planet.color = '000001';
      mat = planet._load_material(page.config, function(){});
      assert(mat.map.image.src).equals(basepath + '1.png');
    });
  });

  describe("#_calc_orbit", function(){
    it("sets planet orbit properties", function(){
      var ms  = {e : 0, p : 10, speed: 1.57,
                 dmajx: 0, dmajy : 1, dmajz : 0,
                 dminx: 0, dminy : 0, dminz : 1};
      var loc = new Omega.Location({id : 42, movement_strategy : ms});
      var pl  = new Omega.Planet({location : loc});
      pl._calc_orbit();

      assert(pl.a).equals(10);
      assert(pl.b).equals(10);
      assert(pl.le).equals(0);
      assert(pl.cx).equals(0);
      assert(pl.cy).equals(0);
      assert(pl.cz).equals(0);
      assert(pl.rot_plane.angle).close(1.57,2);
      assert(pl.rot_axis.angle).close(1.57,2);

      assert(pl.rot_plane.axis[0]).equals(0)
      assert(pl.rot_plane.axis[1]).equals(1)
      assert(pl.rot_plane.axis[2]).equals(0)
      assert(pl.rot_axis.axis[0]).equals(1)
      assert(pl.rot_axis.axis[1]).equals(0)
      assert(pl.rot_axis.axis[2]).close(0, 0.00001)
    });
  });

  describe("#_init_orbit_gfx", function(){
    it("calculates orbit", function(){
      var pl  = new Omega.Planet({});
      var calc_orbit = sinon.spy(pl, '_calc_orbit')
      pl._init_orbit_gfx();
      sinon.assert.called(calc_orbit);
    });

    it("creates orbit mesh", function(){
      var ms  = {e : 0, p : 10, speed: 1.57,
                 dmajx: 0, dmajy : 1, dmajz : 0,
                 dminx: 0, dminy : 0, dminz : 1};
      var loc = new Omega.Location({id : 42, movement_strategy : ms});
      var pl  = new Omega.Planet({location : loc});
      pl._init_orbit_gfx();
      assert(pl.orbit_mesh).isOfType(THREE.Line);
      // TODO verify actual line vertices
    });
  });

  describe("#init_gfx", function(){
    var config, event_cb;

    before(function(){
      config   = Omega.Config;
      event_cb = function(){};
    });

    after(function(){
      if(Omega.Planet.gfx){
        if(Omega.Planet.gfx.mesh.clone.restore) Omega.Planet.gfx.mesh.clone.restore();
      }
    });

    it("loads planet gfx", function(){
      var planet = new Omega.Planet();
      var load_gfx  = sinon.spy(planet, 'load_gfx');
      planet.init_gfx(config, event_cb);
      sinon.assert.called(load_gfx);
    });

    it("clones Planet mesh", function(){
      Omega.Test.Canvas.Entities();
      var planet = new Omega.Planet();
      var mesh   = new THREE.Mesh();
      sinon.stub(Omega.Planet.gfx.mesh, 'clone').returns(mesh);
      planet.init_gfx(config, event_cb);
      assert(planet.mesh).equals(mesh);
    });

    it("sets mesh omega_entity", function(){
      var planet = new Omega.Planet();
      planet.init_gfx(config, event_cb);
      assert(planet.mesh.omega_entity).equals(planet);
    });

    it("loads/sets planet mesh material", function(){
      var planet = new Omega.Planet({color: 'ABABAB'});
      var material = new THREE.Material();
      var load_material = sinon.stub(planet, '_load_material');
      load_material.returns(material);

      planet.init_gfx(config, event_cb);
      sinon.assert.calledWith(load_material, config, event_cb, '0xABABAB');
    });

    it("refreshes graphics", function(){
      var planet = new Omega.Planet({});
      var update_gfx = sinon.spy(planet, 'update_gfx');
      planet.init_gfx(config, event_cb);
      sinon.assert.called(update_gfx);
    });

    it("loads planet orbit gfx", function(){
      var planet = new Omega.Planet({});
      var init_orbit_gfx = sinon.spy(planet, '_init_orbit_gfx');
      planet.init_gfx(config, event_cb);
      sinon.assert.called(init_orbit_gfx);
    });

    it("adds mesh and orbit mesh to planet scene components", function(){
      var planet = new Omega.Planet();
      planet.init_gfx(config, event_cb);
      assert(planet.components[0]).equals(planet.mesh);
      assert(planet.components[1]).equals(planet.orbit_mesh);
    });
  });

  describe("#update_gfx", function(){
    it("sets mesh position from planet location", function(){
      var planet = Omega.Test.Canvas.Entities().planet;
      planet.location = new Omega.Location({x : 20, y : 30, z : -20});
      planet.update_gfx();
      assert(planet.mesh.position.x).equals( 20);
      assert(planet.mesh.position.y).equals( 30);
      assert(planet.mesh.position.z).equals(-20);
    });
  });

  describe("#run_effects", function(){
    var pl;

    before(function(){

      // XXX should specify full movement strategy & invoke
      // 'pl._calc_orbit' instead of specifying calculated
      // orbit properties manually
      var loc = new Omega.Location({id : 42, x : 0, y : 0, z : 10,
                 movement_strategy : {speed: -1.57}});
      pl  = new Omega.Planet({
                  location : loc,
                  last_moved : new Date() - 1000,
                  a  : 10,  b : 10,
                  cx :  0, cy :  0, cz : 0,
                  rot_axis  : {angle : 0,
                               axis  : [1, 0, 0]},
                  rot_plane : {angle : 1.57,
                               axis  : [1, 0, 0]}});
    });

    it("moves planet", function(){
      // XXX sinon-qunit enables fake timers by default
      this.clock.restore();

      pl.run_effects();
      assert(pl.location.x).close(10,2);
      assert(pl.location.y).close( 0,2);
      assert(pl.location.z).close( 0,2);
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
});}); // Omega.Planet
