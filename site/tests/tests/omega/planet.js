pavlov.specify("Omega.Planet", function(){
describe("Omega.Planet", function(){
  it("converts location", function(){
    var planet = new Omega.Planet({location :
      {json_class : 'Motel::Location', data : {x: 10, y: 20, z:30}}});
    assert(planet.location).isOfType(Omega.Location);
    assert(planet.location.x).equals(10);
    assert(planet.location.y).equals(20);
    assert(planet.location.z).equals(30);
  });

  describe("#toJSON", function(){
    it("returns planet json data", function(){
      var pl  = {id          : 'pl1',
                 name        : 'pl1n',
                 parent_id   : 'sys1',
                 location    : new Omega.Location({id : 'pl1l'}),
                 color       : 'ABABAB',
                 size        : 100};

      var opl  = new Omega.Planet(pl);
      var json = opl.toJSON();

      pl.json_class  = opl.json_class;
      pl.location    = pl.location.toJSON();
      assert(json).isSameAs(pl);
    });
  });

  describe("#load_gfx", function(){
    describe("graphics are initialized", function(){
      var orig;

      before(function(){
        orig = {gfx: Omega.Planet.gfx,
                cgfx: Omega.Planet.gfx ? Omega.Planet.gfx[0]   : null,
                mesh: Omega.Planet.gfx && Omega.Planet.gfx[0] ?
                      Omega.Planet.gfx[0].mesh : null};
      })

      after(function(){
        Omega.Planet.gfx = orig.gfx;
        if(Omega.Planet.gfx) Omega.Planet.gfx[0] = orig.cgfx;
        if(Omega.Planet.gfx && Omega.Planet.gfx[0])
          Omega.Planet.gfx[0].mesh = orig.mesh;
      });

      it("does nothing / just returns", function(){
        Omega.Planet.gfx = {0 : {mesh : null}};
        new Omega.Planet().load_gfx(Omega.Config);
        assert(Omega.Planet.gfx[0].mesh).isNull();
      });
    });

    it("creates mesh for Planet", function(){
      Omega.Test.Canvas.Entities();
      assert(Omega.Planet.gfx[0].mesh).isOfType(Omega.PlanetMesh);
      assert(Omega.Planet.gfx[0].mesh.tmesh).isOfType(THREE.Mesh);
      assert(Omega.Planet.gfx[0].mesh.tmesh.geometry).isOfType(THREE.SphereGeometry);
      assert(Omega.Planet.gfx[0].mesh.tmesh.material).isOfType(THREE.MeshLambertMaterial);
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

  describe("#init_gfx", function(){
    var config, event_cb, planet;

    before(function(){
      config   = Omega.Config;
      event_cb = function(){};

      var ms  = {e : 0, p : 10, speed: 1.57,
                 dmajx: 0, dmajy : 1, dmajz : 0,
                 dminx: 0, dminy : 0, dminz : 1};
      var loc = new Omega.Location({id : 42, movement_strategy : ms});
      planet  = new Omega.Planet({location : loc, color: '000000'});
    });

    after(function(){
      if(Omega.Planet.gfx && Omega.Planet.gfx[0]){
        if(Omega.Planet.gfx[0].mesh.clone.restore)
          Omega.Planet.gfx[0].mesh.clone.restore();
      }

      if(Omega.PlanetMaterial.load.restore)
        Omega.PlanetMaterial.load.restore();
    });

    it("loads planet gfx", function(){
      var load_gfx = sinon.spy(planet, 'load_gfx');
      planet.init_gfx(config, event_cb);
      sinon.assert.called(load_gfx);
    });

    it("clones Planet mesh", function(){
      Omega.Test.Canvas.Entities();
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
      sinon.assert.calledWith(load_material, config, 0, event_cb);
    });

    it("refreshes graphics", function(){
      var update_gfx = sinon.spy(planet, 'update_gfx');
      planet.init_gfx(config, event_cb);
      sinon.assert.called(update_gfx);
    });

    it("loads planet orbit", function(){
      var calc_orbit = sinon.spy(planet, '_calc_orbit');
      planet.init_gfx(config, event_cb);
      sinon.assert.called(calc_orbit);
    });

    it("creates orbit line", function(){
      planet.init_gfx(config, event_cb);
      assert(planet.orbit_line).isOfType(Omega.PlanetOrbitLine);
      // TODO verify actual line vertices
    });

    it("adds mesh and orbit mesh to planet scene components", function(){
      planet.init_gfx(config, event_cb);
      assert(planet.components[0]).equals(planet.mesh.tmesh);
      assert(planet.components[1]).equals(planet.orbit_line.line);
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

pavlov.specify("Omega.PlanetMaterial", function(){
describe("Omega.PlanetMaterial", function(){
describe("#load", function(){
  it("loads texture corresponding to color", function(){
    var config   = Omega.Config;
    var basepath = 'http://' + config.http_host   +
                               config.url_prefix  +
                               config.images_path +
                               '/textures/planet';

    var mat = Omega.PlanetMaterial.load(config, 0, function(){});
    assert(mat.map.image.src).equals(basepath + '0.png');

    mat = Omega.PlanetMaterial.load(config, 1, function(){});
    assert(mat.map.image.src).equals(basepath + '1.png');
  });
});
});}); // Omega.PlanetMaterial
