pavlov.specify("Omega.UI.Loader", function(){
describe("Omega.UI.Loader", function(){
  describe("#json", function(){
    it("provides singleton THREE.JSONLoader", function(){
      assert(Omega.UI.Loader.json()).isOfType(THREE.JSONLoader);
      assert(Omega.UI.Loader.json()).equals(Omega.UI.Loader.json());
    })
  });

  describe("#preload", function(){
    ///it("preloads all configured resources"); NIY
  });

  describe("#load_system", function(){
    var page;
    before(function(){
      page = new Omega.Pages.Test({node : new Omega.Node()});
    });

    after(function(){
      if(Omega.SolarSystem.with_id.restore) Omega.SolarSystem.with_id.restore();
    });

    it("retrieves/returns system in page registry", function(){
      var entity = {};
      var get = sinon.stub(page, 'entity').returns(entity);
      var system = Omega.UI.Loader.load_system('system1', page)
      sinon.assert.calledWith(get, 'system1')
      assert(system).equals(entity);
    });

    describe("system is not set", function(){
      it("sets/returns system placeholder", function(){
        var entity = sinon.spy(page, 'entity');
        var system = Omega.UI.Loader.load_system('system1', page)
        sinon.assert.calledWith(entity, 'system1', Omega.UI.Loader.placeholder);
        assert(system).equals(Omega.UI.Loader.placeholder);
      });

      it("retrieves system with specified id", function(){
        var with_id = sinon.spy(Omega.SolarSystem, 'with_id');
        Omega.UI.Loader.load_system('system1', page)
        sinon.assert.calledWith(with_id, 'system1', page.node, sinon.match.func);
      });

      it("stores system in page entity registry", function(){
        var with_id = sinon.spy(Omega.SolarSystem, 'with_id');
        Omega.UI.Loader.load_system('system1', page)

        var with_id_cb = with_id.getCall(0).args[2];
        var system = new Omega.SolarSystem();
        var set = sinon.spy(page, 'entity')
        with_id_cb(system)
        sinon.assert.calledWith(set, 'system1', system);
      })

      it("invokes callback", function(){
        var cb = sinon.spy();
        var with_id = sinon.spy(Omega.SolarSystem, 'with_id');
        Omega.UI.Loader.load_system('system1', page, cb)

        var with_id_cb = with_id.getCall(0).args[2];
        var system = new Omega.SolarSystem();
        with_id_cb(system)
        sinon.assert.calledWith(cb, system);
      })
    })
  });

  describe("#load_galaxy", function(){
    var page;
    before(function(){
      page = new Omega.Pages.Test({node : new Omega.Node()});
    });

    after(function(){
      if(Omega.Galaxy.with_id.restore) Omega.Galaxy.with_id.restore();
    });

    it("retrieves/returns galaxy in page registry", function(){
      var entity = {};
      var get = sinon.stub(page, 'entity').returns(entity);
      var galaxy = Omega.UI.Loader.load_galaxy('galaxy1', page)
      sinon.assert.calledWith(get, 'galaxy1')
      assert(galaxy).equals(entity);
    });

    describe("galaxy is not set", function(){
      it("sets/returns galaxy placeholder", function(){
        var entity = sinon.spy(page, 'entity');
        var galaxy = Omega.UI.Loader.load_galaxy('galaxy1', page)
        sinon.assert.calledWith(entity, 'galaxy1', Omega.UI.Loader.placeholder);
        assert(galaxy).equals(Omega.UI.Loader.placeholder);
      });

      it("retrieves galaxy with specified id", function(){
        var with_id = sinon.spy(Omega.Galaxy, 'with_id');
        var cb = function(){};
        Omega.UI.Loader.load_galaxy('galaxy1', page, cb)
        sinon.assert.calledWith(with_id, 'galaxy1', page.node, sinon.match.func);
      });

      it("stores galaxy in page entity registry", function(){
        var with_id = sinon.spy(Omega.Galaxy, 'with_id');
        Omega.UI.Loader.load_galaxy('galaxy1', page)

        var with_id_cb = with_id.getCall(0).args[2];
        var galaxy = new Omega.Galaxy();
        var set = sinon.spy(page, 'entity')
        with_id_cb(galaxy)
        sinon.assert.calledWith(set, 'galaxy1', galaxy);
      });

      it("invokes callback", function(){
        var cb = sinon.spy();
        var with_id = sinon.spy(Omega.Galaxy, 'with_id');
        Omega.UI.Loader.load_galaxy('galaxy1', page, cb)

        var with_id_cb = with_id.getCall(0).args[2];
        var galaxy = new Omega.Galaxy();
        with_id_cb(galaxy)
        sinon.assert.calledWith(cb, galaxy);
      })
    })
  });
});});
