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

  describe("#load_universe", function(){
    var page, get_stat, result;

    before(function(){
      page = new Omega.Pages.Test();
      page.node = new Omega.Node();

      get_stat = sinon.stub(Omega.Stat, 'get');
      result   = {value : 'universe_id'};
    })

    after(function(){
      Omega.Stat.get.restore();
    });

    it("retrieves universe_id", function(){
      Omega.UI.Loader.load_universe(page);
      sinon.assert.calledWith(get_stat, 'universe_id', null,
                              page.node, sinon.match.func);
    });

    describe("universe id is not same as local id", function(){
      it("removes local cosmos data", function(){
        $.localStorage.set('omega.cosmos.anything', JSON.stringify('anything'));
        $.localStorage.set('omega.universe_id', JSON.stringify('foobar'));

        Omega.UI.Loader.load_universe(page);
        get_stat.getCall(0).args[3](result);
        assert($.localStorage.keys()).doesNotInclude('omega.cosmos.anything');
      });
    });

    it("sets local universe_id", function(){
      Omega.UI.Loader.load_universe(page);
      get_stat.getCall(0).args[3](result);
      assert($.localStorage.get('omega.universe_id')).equals('universe_id');
    });

    it("invokes callback with universe id", function(){
      var cb = sinon.spy();
      Omega.UI.Loader.load_universe(page, cb);
      get_stat.getCall(0).args[3](result);
      sinon.assert.calledWith(cb, 'universe_id');
    });
  });

  describe("#load_system", function(){
    var page, with_id;
    before(function(){
      page = new Omega.Pages.Test({node : new Omega.Node()});

      with_id = sinon.stub(Omega.SolarSystem, 'with_id');
    });

    after(function(){
      Omega.SolarSystem.with_id.restore();
    });

    describe("registry system set", function(){
      it("returns registry system", function(){
        var entity = {};
        var get = sinon.stub(page, 'entity').returns(entity);
        var system = Omega.UI.Loader.load_system('system1', page)
        sinon.assert.calledWith(get, 'system1')
        assert(system).equals(entity);
      });
    });

    describe("registry system is _not_ set, local storage system set", function(){
      var system;

      before(function(){
        system = new Omega.SolarSystem({id : 'system1'})
        $.localStorage.set('omega.cosmos.' + system.id,
                           RJR.JRMessage.convert_obj_to_jr_obj(system.toJSON()));
      });

      it("returns system from local storage", function(){
        var ret = Omega.UI.Loader.load_system(system.id, page);
        assert(ret).isSameAs(system);
      });

      it("sets system in page registry", function(){
        Omega.UI.Loader.load_system(system.id, page);
        assert(page.entity(system.id)).isSameAs(system);
      });

      it("invokes callback with system", function(){
        var cb = sinon.spy();
        Omega.UI.Loader.load_system(system.id, page, cb);
        sinon.assert.calledWith(cb, system);
      });
    });

    describe("registry and local storage systems _not_ set", function(){
      it("sets/returns system placeholder", function(){
        var entity = sinon.spy(page, 'entity');
        var system = Omega.UI.Loader.load_system('system1', page)
        sinon.assert.calledWith(entity, 'system1', Omega.UI.Loader.placeholder);
        assert(system).equals(Omega.UI.Loader.placeholder);
      });

      it("retrieves system with specified id", function(){
        Omega.UI.Loader.load_system('system1', page)
        sinon.assert.calledWith(with_id, 'system1', page.node, sinon.match.func);
      });

      it("stores system in page entity registry", function(){
        Omega.UI.Loader.load_system('system1', page)

        var with_id_cb = with_id.getCall(0).args[2];
        var system = new Omega.SolarSystem({id : 'system1'});
        var set = sinon.spy(page, 'entity')
        with_id_cb(system)
        sinon.assert.calledWith(set, 'system1', system);
      })

      it("invokes callback", function(){
        var cb = sinon.spy();
        Omega.UI.Loader.load_system('system1', page, cb)

        var with_id_cb = with_id.getCall(0).args[2];
        var system = new Omega.SolarSystem();
        with_id_cb(system)
        sinon.assert.calledWith(cb, system);
      })
    });
  });

  describe("#load_galaxy", function(){
    var page, with_id;
    before(function(){
      page = new Omega.Pages.Test({node : new Omega.Node()});

      with_id = sinon.stub(Omega.Galaxy, 'with_id');
    });

    after(function(){
      Omega.Galaxy.with_id.restore();
    });

    describe("registry galaxy set", function(){
      it("returns registry galaxy", function(){
        var entity = {};
        var get = sinon.stub(page, 'entity').returns(entity);
        var galaxy = Omega.UI.Loader.load_galaxy('galaxy1', page)
        sinon.assert.calledWith(get, 'galaxy1')
        assert(galaxy).equals(entity);
      });
    });

    describe("registry galaxy is _not_ set, local storage galaxy set", function(){
      var galaxy;

      before(function(){
        galaxy = new Omega.Galaxy({id : 'galaxy1'})
        $.localStorage.set('omega.cosmos.' + galaxy.id,
                           RJR.JRMessage.convert_obj_to_jr_obj(galaxy.toJSON()));
      });

      it("returns galaxy from local storage", function(){
        var ret = Omega.UI.Loader.load_galaxy(galaxy.id, page);
        assert(ret).isSameAs(galaxy);
      });

      it("sets galaxy in page registry", function(){
        Omega.UI.Loader.load_galaxy(galaxy.id, page);
        assert(page.entity(galaxy.id)).isSameAs(galaxy);
      });

      it("invokes callback with galaxy", function(){
        var cb = sinon.spy();
        Omega.UI.Loader.load_galaxy(galaxy.id, page, cb);
        sinon.assert.calledWith(cb, galaxy);
      });
    });

    describe("registry and local storage galaxy _not_ set", function(){
      it("sets/returns galaxy placeholder", function(){
        var entity = sinon.spy(page, 'entity');
        var galaxy = Omega.UI.Loader.load_galaxy('galaxy1', page)
        sinon.assert.calledWith(entity, 'galaxy1', Omega.UI.Loader.placeholder);
        assert(galaxy).equals(Omega.UI.Loader.placeholder);
      });

      it("retrieves galaxy with specified id", function(){
        var cb = function(){};
        Omega.UI.Loader.load_galaxy('galaxy1', page, cb)
        sinon.assert.calledWith(with_id, 'galaxy1', page.node, sinon.match.func);
      });

      it("stores galaxy in page entity registry", function(){
        Omega.UI.Loader.load_galaxy('galaxy1', page)

        var with_id_cb = with_id.getCall(0).args[2];
        var galaxy = new Omega.Galaxy({id : 'galaxy1'});
        var set = sinon.spy(page, 'entity')
        with_id_cb(galaxy)
        sinon.assert.calledWith(set, 'galaxy1', galaxy);
      });

      it("invokes callback", function(){
        var cb = sinon.spy();
        Omega.UI.Loader.load_galaxy('galaxy1', page, cb)

        var with_id_cb = with_id.getCall(0).args[2];
        var galaxy = new Omega.Galaxy();
        with_id_cb(galaxy)
        sinon.assert.calledWith(cb, galaxy);
      })
    })
  });

  describe("#load_user_entities", function(){
    var node, cb;
    before(function(){
      node = new Omega.Node();
      cb = function(){};
    });

    after(function(){
      if(Omega.Ship.owned_by.restore) Omega.Ship.owned_by.restore();
      if(Omega.Station.owned_by.restore) Omega.Station.owned_by.restore();
    });

    it("retrieves ships owned by user", function(){
      var spy = sinon.spy(Omega.Ship, 'owned_by');
      Omega.UI.Loader.load_user_entities('foo', node, cb)
      sinon.assert.calledWith(spy, 'foo', node, cb);
    });

    it("retrieves stations owned by user", function(){
      var spy = sinon.spy(Omega.Station, 'owned_by');
      Omega.UI.Loader.load_user_entities('foo', node, cb)
      sinon.assert.calledWith(spy, 'foo', node, cb);
    });
  });
});});
