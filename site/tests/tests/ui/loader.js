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
        var cb = function(){};
        Omega.UI.Loader.load_system('system1', page, cb)
        sinon.assert.calledWith(with_id, 'system1', page.node, cb);
      });
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
        sinon.assert.calledWith(with_id, 'galaxy1', page.node, cb);
      });
    })
  });
});});
