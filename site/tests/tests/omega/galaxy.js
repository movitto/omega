pavlov.specify("Omega.Galaxy", function(){
describe("Omega.Galaxy", function(){
  describe("#child", function(){
    it("returns solar system child w/ the specified id", function(){
      var system = new Omega.SolarSystem();
      var planet1 = Omega.Gen.planet();
      var planet2 = Omega.Gen.planet();
      system.children = [planet1, planet2];
      assert(system.child(planet1.id)).equals(planet1);
    });
  });

  describe("#refresh", function(){
    var node, galaxy, retrieved;
    before(function(){
      node = new Omega.Node();
      galaxy = Omega.Gen.galaxy();
      retrieved = Omega.Gen.galaxy();

      sinon.stub(Omega.Galaxy, 'with_id');
    });

    after(function(){
      Omega.Galaxy.with_id.restore();
    });

    it("retrieves galaxy from server", function(){
      galaxy.refresh(node);
      sinon.assert.calledWith(Omega.Galaxy.with_id,
        galaxy.id, node, {children: true, recursive: false},
        sinon.match.func);
    });

    it("updates galaxy with result", function(){
      sinon.stub(galaxy, 'update')
      galaxy.refresh(node);
      Omega.Galaxy.with_id.omega_callback()(retrieved);
      sinon.assert.calledWith(galaxy.update, retrieved);
    });

    it("invokes callback with galaxy", function(){
      var cb = sinon.spy();
      galaxy.refresh(node, cb);
      Omega.Galaxy.with_id.omega_callback()(retrieved);
      sinon.assert.called(cb);
    });

    it("dispatches refreshed event", function(){
      var cb = sinon.spy();
      galaxy.addEventListener('refreshed', cb);
      galaxy.refresh(node);
      Omega.Galaxy.with_id.omega_callback()(retrieved, cb);
      sinon.assert.called(cb);
    });
  });

  describe("#update", function(){
    var galaxy,  system1,   system2,
        ngalaxy, nsystem1, nsystem2, nsystem3;

    before(function(){
      galaxy  = Omega.Gen.galaxy();
      system1 = Omega.Gen.solar_system();
      system2 = Omega.Gen.solar_system();
      galaxy.children = [system1, system2, 'systemA'];

      ngalaxy  = Omega.Gen.galaxy();
      nsystem1 = Omega.Gen.solar_system();
      nsystem2 = Omega.Gen.solar_system({id : system2.id});
      nsystem3 = Omega.Gen.solar_system({id : 'systemA'});
      ngalaxy.children = [nsystem1, nsystem2, nsystem3];
    });

    it("adds missing children to galaxy", function(){
      galaxy.update(ngalaxy);
      assert(galaxy.children).includes(nsystem1);
    });

    it("updates galaxy children ids", function(){
      galaxy.update(ngalaxy);
      assert(galaxy.children).includes(nsystem3);
      assert(galaxy.children).doesNotInclude('system3');
    });

    it("updates existing children", function(){
      sinon.spy(system2, 'update');
      galaxy.update(ngalaxy);
      sinon.assert.calledWith(system2.update, nsystem2);
    });
  });

  describe("#toJSON", function(){
    it("returns galaxy json data", function(){
      var gal  = {id        : 'gal1',
                  name      : 'gal1n',
                  location  : new Omega.Location({id : 'gal1l'}),
                  children  : [new Omega.SolarSystem({id : 'sys1',
                                 location : new Omega.Location({id:'loc1'})})]};

      var ogal = new Omega.Galaxy(gal);
      var json = ogal.toJSON();

      gal.json_class  = ogal.json_class;
      gal.location    = gal.location.toJSON();
      gal.children[0] = gal.children[0].toJSON();
      assert(json).isSameAs(gal);
    });
  });

  it("converts children", function(){
    var system = {json_class: 'Cosmos::Entities::SolarSystem', id: 'sys1'};
    var galaxy = new Omega.Galaxy({children: [system]});
    assert(galaxy.children.length).equals(1);
    assert(galaxy.children[0]).isOfType(Omega.SolarSystem);
    assert(galaxy.children[0].id).equals('sys1');
  });

  it("converts location", function(){
    var galaxy = new Omega.Galaxy({location : {json_class : 'Motel::Location', data : {x: 10, y: 20, z:30}}});
    assert(galaxy.location).isOfType(Omega.Location);
    assert(galaxy.location.x).equals(10);
    assert(galaxy.location.y).equals(20);
    assert(galaxy.location.z).equals(30);
  });

  describe("#systems", function(){
    it("returns system children", function(){
      var sys1 = {json_class : 'Cosmos::Entities::SolarSystem', data : {id : 'sys1'}};
      var galaxy = new Omega.Galaxy({children : [sys1]});
      assert(galaxy.children.length).equals(1);
      assert(galaxy.children[0]).isOfType(Omega.SolarSystem);
    });
  });

  describe("#set_children_from", function(){
    var systems, galaxy;

    before(function(){
      systems  = [new Omega.SolarSystem({id : 'sys1'}),
                  new Omega.SolarSystem({id : 'sys2'})]
      gsystems = [new Omega.SolarSystem({id : 'sys1'})]
      galaxy   =  new Omega.Galaxy({children: gsystems});
    });

    it("swaps child systems in from entity list", function(){
      galaxy.set_children_from(systems);
      assert(galaxy.children.length).equals(1);
      assert(galaxy.children[0]).equals(systems[0]);
    });

    it("sets galaxy on systems swapped in", function(){
      galaxy.set_children_from(systems);
      assert(galaxy.children[0].galaxy).equals(galaxy);
      assert(systems[1].galaxy).isUndefined();
    });
  });

  describe("#load_gfx", function(){
    describe("graphics are initialized", function(){
      it("does nothing / just returns", function(){
        var galaxy = new Omega.Galaxy();
        sinon.stub(galaxy, 'gfx_loaded').returns(true);
        sinon.spy(galaxy, '_loaded_gfx');
        galaxy.load_gfx();
        sinon.assert.notCalled(galaxy._loaded_gfx);
      });
    });

    it("creates stars for galaxy", function(){
      var galaxy = Omega.Test.entities()['galaxy'];
      var stars  = galaxy._retrieve_resource('stars');
      assert(stars).isOfType(Omega.GalaxyDensityWave);
      assert(stars.type).equals('stars');
    });

    it("creates clouds for galaxy", function(){
      var galaxy = Omega.Test.entities()['galaxy'];
      var clouds = galaxy._retrieve_resource('clouds');
      assert(clouds).isOfType(Omega.GalaxyDensityWave);
      assert(clouds.type).equals('clouds');
    });
  });

  describe("#init_gfx", function(){
    before(function(){
      /// preiinit using test page
      Omega.Test.entities();
    });

    it("loads galaxy gfx", function(){
      var galaxy    = new Omega.Galaxy();
      var load_gfx  = sinon.spy(galaxy, 'load_gfx');
      galaxy.init_gfx();
      sinon.assert.called(load_gfx);
    });

    it("references Galaxy density_waves", function(){
      var galaxy = new Omega.Galaxy();
      galaxy.init_gfx();
      var stars = galaxy._retrieve_resource('stars');
      var clouds = galaxy._retrieve_resource('clouds');
      assert(galaxy.stars).equals(stars);
      assert(galaxy.clouds).equals(clouds);
    });

    it("adds particle system to galaxy scene components", function(){
      var galaxy = new Omega.Galaxy();
      galaxy.init_gfx();
      var expected = [galaxy.clouds.particles, galaxy.stars.particles];
      assert(galaxy.components).isSameAs(expected);
    });
  });

  describe("#run_effects", function(){
    //it("updates particle system density_wave") // NIY
  });

  describe("#with_id", function(){
    var node, retrieval_cb;

    before(function(){
      node = new Omega.Node();
      retrieval_cb = sinon.spy();
      sinon.stub(node, 'http_invoke');
    });

    it("invokes cosmos::get_entity request", function(){
      Omega.Galaxy.with_id('galaxy1', node, retrieval_cb);
      sinon.assert.calledWith(node.http_invoke,
        'cosmos::get_entity', 'with_id', 'galaxy1',
        'children', false, 'recursive', false,
        sinon.match.func);
    });

    it("passes children and recursive arguments onto cosmos::get_entity", function(){
      Omega.Galaxy.with_id('galaxy1', node,
                           {children : true, recursive : true},
                           retrieval_cb);
      sinon.assert.calledWith(node.http_invoke,
        'cosmos::get_entity', 'with_id', 'galaxy1',
        'children', true, 'recursive', true,
        sinon.match.func);
    });

    describe("cosmos::get_entity callback", function(){
      it("invokes callback", function(){
        Omega.Galaxy.with_id('galaxy1', node, retrieval_cb);
        node.http_invoke.omega_callback()({});
        sinon.assert.called(retrieval_cb);
      });

      it("creates new galaxy instance", function(){
        Omega.Galaxy.with_id('galaxy1', node, retrieval_cb);
        node.http_invoke.omega_callback()({result : {id:'gal1'}});
        var galaxy = retrieval_cb.getCall(0).args[0];
        assert(galaxy).isOfType(Omega.Galaxy);
        assert(galaxy.id).equals('gal1');
      });
    });
  });
});}); // Omega.Galaxy
