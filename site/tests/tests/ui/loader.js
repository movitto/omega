pavlov.specify("Omega.UI.Loader", function(){
describe("Omega.UI.Loader", function(){
  describe("#preload", function(){
    ///it("preloads all configured resources"); NIY
  });

  describe("#json", function(){
    it("provides singleton THREE.JSONLoader", function(){
      assert(Omega.UI.Loader.json()).isOfType(THREE.JSONLoader);
      assert(Omega.UI.Loader.json()).equals(Omega.UI.Loader.json());
    })
  });

  describe("#clear_universe", function(){
    it("removes local cosmos data", function(){
      $.localStorage.set('omega.cosmos.anything', JSON.stringify('anything'));
      Omega.UI.Loader.clear_universe();
      assert($.localStorage.keys()).doesNotInclude('omega.cosmos.anything');
    });

    it("removes universe_id", function(){
      $.localStorage.set('omega.universe_id', JSON.stringify('foobar'));
      Omega.UI.Loader.clear_universe();
      assert($.localStorage.keys()).doesNotInclude('omega.universe_id');
    });
  });

  describe("#_same_universe", function(){
    describe("specified universe_id is same as local one", function(){
      it("returns true", function(){
        $.localStorage.set('omega.universe_id', JSON.stringify('123'));
        assert(Omega.UI.Loader._same_universe('123')).isTrue();
      });
    });

    describe("specified universe_id is not same as local one", function(){
      it("returns false", function(){
        $.localStorage.set('omega.universe_id', JSON.stringify('123'));
        assert(Omega.UI.Loader._same_universe('456')).isFalse();
      });
    });
  });

  describe("#_set_universe", function(){
    it("stores the universe id", function(){
      $.localStorage.set('omega.universe_id', JSON.stringify('123'));
      Omega.UI.Loader._set_universe('456');
      assert($.localStorage.get('omega.universe_id')).equals('456');
    });
  });

  describe("#load_universe", function(){
    var page, result;

    before(function(){
      page = new Omega.Pages.Test();
      page.node = new Omega.Node();

      result = {value : 'universe_id'};
      sinon.stub(Omega.Stat, 'get');
    })

    after(function(){
      if(Omega.UI.Loader._same_universe.restore)
        Omega.UI.Loader._same_universe.restore();

      if(Omega.UI.Loader.clear_universe.restore)
        Omega.UI.Loader.clear_universe.restore();

      if(Omega.UI.Loader._set_universe.restore)
        Omega.UI.Loader._set_universe.restore();

      Omega.Stat.get.restore();
    });

    it("retrieves universe_id", function(){
      Omega.UI.Loader.load_universe(page);
      sinon.assert.calledWith(Omega.Stat.get, 'universe_id', null,
                              page.node, sinon.match.func);
    });

    describe("universe id is not same as local id", function(){
      it("clears the universe", function(){
        sinon.stub(Omega.UI.Loader, '_same_universe').returns(false);
        sinon.stub(Omega.UI.Loader, 'clear_universe');
        Omega.UI.Loader.load_universe(page);
        Omega.Stat.get.omega_callback()(result);
        sinon.assert.called(Omega.UI.Loader.clear_universe);
      });
    });

    it("sets local universe_id", function(){
      sinon.stub(Omega.UI.Loader, '_set_universe');
      Omega.UI.Loader.load_universe(page);
      Omega.Stat.get.omega_callback()(result);
      sinon.assert.calledWith(Omega.UI.Loader._set_universe, 'universe_id');
    });

    it("invokes callback with universe id", function(){
      var cb = sinon.spy();
      Omega.UI.Loader.load_universe(page, cb);
      Omega.Stat.get.omega_callback()(result);
      sinon.assert.calledWith(cb, 'universe_id');
    });
  });

  describe("#_load_page_system", function(){
    var page, system;

    before(function(){
      page = new Omega.Pages.Test();
      system = Omega.Gen.solar_system();
      page.entity(system.id, system);
    });

    it("returns system from page registry", function(){
      assert(Omega.UI.Loader._load_page_system(system.id, page)).equals(system);
      assert(Omega.UI.Loader._load_page_system('foobar', page)).equals(null);
    });
  });

  describe("#_load_storage_system", function(){
    var page, system;

    before(function(){
      page = new Omega.Pages.Test();
      system = Omega.Gen.solar_system();
    });

    describe("local storage system is null", function(){
      it("returns null", function(){
        $.localStorage.set('omega.cosmos.system1', null);
        assert(Omega.UI.Loader._load_storage_system('system1', page)).isNull();
      });

      it("does not invoke callback", function(){
        var cb = sinon.spy();
        $.localStorage.set('omega.cosmos.system1', null);
        Omega.UI.Loader._load_storage_system('system1', page);
        sinon.assert.notCalled(cb);
      });
    });

    describe("local storage system is the placeholder system", function(){
      it("returns null", function(){
        $.localStorage.set('omega.cosmos.system1', Omega.UI.Loader.placeholder);
        assert(Omega.UI.Loader._load_storage_system('system1', page)).isNull();
      });

      it("does not invoke callback", function(){
        var cb = sinon.spy();
        $.localStorage.set('omega.cosmos.system1', Omega.UI.Loader.placeholder);
        Omega.UI.Loader._load_storage_system('system1', page);
        sinon.assert.notCalled(cb);
      });
    });

    it("stores system in page registry", function(){
      var json = RJR.JRMessage.convert_obj_to_jr_obj(system.toJSON())
      $.localStorage.set('omega.cosmos.system1', json);
      Omega.UI.Loader._load_storage_system('system1', page);

      var entity = page.entity('system1');
      assert(entity).isOfType(Omega.SolarSystem);
      assert(entity.id).equals(system.id);
    });

    it("invokes callback with system", function(){
      var json = RJR.JRMessage.convert_obj_to_jr_obj(system.toJSON())
      $.localStorage.set('omega.cosmos.system1', json);

      var cb = sinon.spy();
      Omega.UI.Loader._load_storage_system('system1', page, cb);
      sinon.assert.calledWith(cb, sinon.match.ofType(Omega.SolarSystem));

      var sys = cb.getCall(0).args[0];
      assert(sys.id).equals(system.id);
    });

    it("returns system", function(){
      var json = RJR.JRMessage.convert_obj_to_jr_obj(system.toJSON())
      $.localStorage.set('omega.cosmos.system1', json);
      var sys = Omega.UI.Loader._load_storage_system('system1', page);
      assert(sys).isOfType(Omega.SolarSystem);
      assert(sys.id).equals(system.id);
    });
  });

  describe("#_load_remote_system", function(){
    var page;

    before(function(){
      sinon.stub(Omega.SolarSystem, 'with_id');
      sinon.stub(Omega.UI.Loader, '_loaded_remote_system');

      page = new Omega.Pages.Test({node : new Omega.Node()});
    });

    after(function(){
      Omega.SolarSystem.with_id.restore();
      Omega.UI.Loader._loaded_remote_system.restore();
    });

    it("stores placeholder system in page registry", function(){
      Omega.UI.Loader._load_remote_system('system1', page)
      assert(page.entity('system1')).equals(Omega.UI.Loader.placeholder);
    });

    it("retrieves system with specified id without children", function(){
      Omega.UI.Loader._load_remote_system('system1', page)
      sinon.assert.calledWith(Omega.SolarSystem.with_id, 'system1',
                   page.node, {children: false}, sinon.match.func);
    });

    describe("on system retrieval", function(){
      it("invokes _loaded_remote_system", function(){
        var cb = function(){};
        Omega.UI.Loader._load_remote_system('system1', page, cb)

        var system = Omega.Gen.solar_system();
        Omega.SolarSystem.with_id.omega_callback()(system);
        sinon.assert.calledWith(Omega.UI.Loader._loaded_remote_system,
                                system, page, cb);
      });
    });

    it("returns placeholder", function(){
      assert(Omega.UI.Loader._load_remote_system('system1', page)).
        equals(Omega.UI.Loader.placeholder);
    });
  });

  describe("_loaded_remote_system", function(){
    var page, system;

    before(function(){
      page = new Omega.Pages.Test({});
      system = Omega.Gen.solar_system();
    });

    it("stores system in page registry", function(){
      Omega.UI.Loader._loaded_remote_system(system, page);
      assert(page.entity(system.id)).equals(system);
    });

    it("stores system in local storage", function(){
      Omega.UI.Loader._loaded_remote_system(system, page);
      var sys = $.localStorage.get('omega.cosmos.' + system.id);
          sys = RJR.JRMessage.convert_obj_from_jr_obj(sys);
      assert(sys.id).equals(system.id);
    });

    it("invokes callback with system", function(){
      var cb = sinon.spy();
      Omega.UI.Loader._loaded_remote_system(system, page, cb);
      sinon.assert.calledWith(cb, system);
    });
  });

  describe("#load_system", function(){
    var system, page, cb;
    before(function(){
      cb = sinon.spy();
      page = new Omega.Pages.Test({});
      system = Omega.Gen.solar_system();
    })

    after(function(){
      if(Omega.UI.Loader._load_page_system.restore)
        Omega.UI.Loader._load_page_system.restore();

      if(Omega.UI.Loader._load_storage_system.restore)
        Omega.UI.Loader._load_storage_system.restore();

      if(Omega.UI.Loader._load_remote_system.restore)
        Omega.UI.Loader._load_remote_system.restore();
    });

    it("retrieves page system", function(){
      sinon.stub(Omega.UI.Loader, '_load_page_system').returns(system);
      assert(Omega.UI.Loader.load_system(system.id, page, cb)).equals(system);
      sinon.assert.calledWith(Omega.UI.Loader._load_page_system,
                              system.id, page, cb);
    });

    describe("page system is null", function(){
      before(function(){
        sinon.stub(Omega.UI.Loader, '_load_page_system').returns(null);
      });

      it("retrieves storage system", function(){
        sinon.stub(Omega.UI.Loader, '_load_storage_system').returns(system);
        assert(Omega.UI.Loader.load_system(system.id, page, cb)).equals(system);
        sinon.assert.calledWith(Omega.UI.Loader._load_storage_system,
                                system.id, page, cb);
      });

      describe("storage system is null", function(){
        before(function(){
          sinon.stub(Omega.UI.Loader, '_load_storage_system').returns(null);
        });

        it("retrieves remote system", function(){
          sinon.stub(Omega.UI.Loader, '_load_remote_system').
            returns(Omega.UI.Loader.placeholder);
          assert(Omega.UI.Loader.load_system(system.id, page, cb)).
            equals(Omega.UI.Loader.placeholder);
          sinon.assert.calledWith(Omega.UI.Loader._load_remote_system,
                                  system.id, page, cb);
        });
      });
    });
  });

  describe("#_load_page_galaxy", function(){
    var page, galaxy;

    before(function(){
      page = new Omega.Pages.Test();
      galaxy = Omega.Gen.galaxy();
      page.entity(galaxy.id, galaxy);
    });

    it("returns galaxy from page registry", function(){
      assert(Omega.UI.Loader._load_page_galaxy(galaxy.id, page)).equals(galaxy);
      assert(Omega.UI.Loader._load_page_galaxy('foobar', page)).equals(null);
    });
  });

  describe("#_load_storage_galaxy", function(){
    var page, galaxy;

    before(function(){
      page = new Omega.Pages.Test();
      galaxy = Omega.Gen.galaxy();
    });

    describe("local storage galaxy is null", function(){
      it("returns null", function(){
        $.localStorage.set('omega.cosmos.galaxy1', null);
        assert(Omega.UI.Loader._load_storage_galaxy('galaxy1', page)).isNull();
      });

      it("does not invoke callback", function(){
        var cb = sinon.spy();
        $.localStorage.set('omega.cosmos.galaxy1', null);
        Omega.UI.Loader._load_storage_galaxy('galaxy1', page);
        sinon.assert.notCalled(cb);
      });
    });

    describe("local storage galaxy is the placeholder galaxy", function(){
      it("returns null", function(){
        $.localStorage.set('omega.cosmos.galaxy1', Omega.UI.Loader.placeholder);
        assert(Omega.UI.Loader._load_storage_galaxy('galaxy1', page)).isNull();
      });

      it("does not invoke callback", function(){
        var cb = sinon.spy();
        $.localStorage.set('omega.cosmos.galaxy1', Omega.UI.Loader.placeholder);
        Omega.UI.Loader._load_storage_galaxy('galaxy1', page);
        sinon.assert.notCalled(cb);
      });
    });

    it("stores galaxy in page registry", function(){
      var json = RJR.JRMessage.convert_obj_to_jr_obj(galaxy.toJSON())
      $.localStorage.set('omega.cosmos.galaxy1', json);
      Omega.UI.Loader._load_storage_galaxy('galaxy1', page);

      var entity = page.entity('galaxy1');
      assert(entity).isOfType(Omega.Galaxy);
      assert(entity.id).equals(galaxy.id);
    });

    it("invokes callback with galaxy", function(){
      var json = RJR.JRMessage.convert_obj_to_jr_obj(galaxy.toJSON())
      $.localStorage.set('omega.cosmos.galaxy1', json);

      var cb = sinon.spy();
      Omega.UI.Loader._load_storage_galaxy('galaxy1', page, cb);
      sinon.assert.calledWith(cb, sinon.match.ofType(Omega.Galaxy));

      var gal = cb.getCall(0).args[0];
      assert(gal.id).equals(galaxy.id);
    });

    it("returns galaxy", function(){
      var json = RJR.JRMessage.convert_obj_to_jr_obj(galaxy.toJSON())
      $.localStorage.set('omega.cosmos.galaxy1', json);
      var gal = Omega.UI.Loader._load_storage_galaxy('galaxy1', page);
      assert(gal).isOfType(Omega.Galaxy);
      assert(gal.id).equals(galaxy.id);
    });
  });

  describe("#_load_remote_galaxy", function(){
    var page;

    before(function(){
      sinon.stub(Omega.Galaxy, 'with_id');
      sinon.stub(Omega.UI.Loader, '_loaded_remote_galaxy');

      page = new Omega.Pages.Test({node : new Omega.Node()});
    });

    after(function(){
      Omega.Galaxy.with_id.restore();
      Omega.UI.Loader._loaded_remote_galaxy.restore();
    });

    it("stores placeholder galaxy in page registry", function(){
      Omega.UI.Loader._load_remote_galaxy('galaxy1', page)
      assert(page.entity('galaxy1')).equals(Omega.UI.Loader.placeholder);
    });

    it("retrieves galaxy with specified id", function(){
      Omega.UI.Loader._load_remote_galaxy('galaxy1', page)
      sinon.assert.calledWith(Omega.Galaxy.with_id, 'galaxy1',
                   page.node, {children: true, recursive: false},
                   sinon.match.func);
    });

    describe("on galaxy retrieval", function(){
      it("invokes _loaded_remote_galaxy", function(){
        var cb = function(){};
        Omega.UI.Loader._load_remote_galaxy('galaxy1', page, cb)

        var galaxy = Omega.Gen.galaxy();
        Omega.Galaxy.with_id.omega_callback()(galaxy);
        sinon.assert.calledWith(Omega.UI.Loader._loaded_remote_galaxy,
                                galaxy, page, cb);
      });
    });

    it("returns placeholder", function(){
      assert(Omega.UI.Loader._load_remote_galaxy('galaxy1', page)).
        equals(Omega.UI.Loader.placeholder);
    });
  });

  describe("_loaded_remote_galaxy", function(){
    var page, galaxy;

    before(function(){
      page = new Omega.Pages.Test({});
      galaxy = Omega.Gen.solar_system();
    });

    it("stores galaxy in page registry", function(){
      Omega.UI.Loader._loaded_remote_galaxy(galaxy, page);
      assert(page.entity(galaxy.id)).equals(galaxy);
    });

    it("stores galaxy in local storage", function(){
      Omega.UI.Loader._loaded_remote_galaxy(galaxy, page);
      var gal = $.localStorage.get('omega.cosmos.' + galaxy.id);
          gal = RJR.JRMessage.convert_obj_from_jr_obj(gal);
      assert(gal.id).equals(galaxy.id);
    });

    it("invokes callback with galaxy", function(){
      var cb = sinon.spy();
      Omega.UI.Loader._loaded_remote_galaxy(galaxy, page, cb);
      sinon.assert.calledWith(cb, galaxy);
    });
  });

  describe("#load_galaxy", function(){
    var galaxy, page, cb;
    before(function(){
      cb = sinon.spy();
      page = new Omega.Pages.Test({});
      galaxy = Omega.Gen.galaxy();
    })

    after(function(){
      if(Omega.UI.Loader._load_page_galaxy.restore)
        Omega.UI.Loader._load_page_galaxy.restore();

      if(Omega.UI.Loader._load_storage_galaxy.restore)
        Omega.UI.Loader._load_storage_galaxy.restore();

      if(Omega.UI.Loader._load_remote_galaxy.restore)
        Omega.UI.Loader._load_remote_galaxy.restore();
    });

    it("retrieves page galaxy", function(){
      sinon.stub(Omega.UI.Loader, '_load_page_galaxy').returns(galaxy);
      assert(Omega.UI.Loader.load_galaxy(galaxy.id, page, cb)).equals(galaxy);
      sinon.assert.calledWith(Omega.UI.Loader._load_page_galaxy,
                              galaxy.id, page, cb);
    });

    describe("page galaxy is null", function(){
      before(function(){
        sinon.stub(Omega.UI.Loader, '_load_page_galaxy').returns(null);
      });

      it("retrieves storage galaxy", function(){
        sinon.stub(Omega.UI.Loader, '_load_storage_galaxy').returns(galaxy);
        assert(Omega.UI.Loader.load_galaxy(galaxy.id, page, cb)).equals(galaxy);
        sinon.assert.calledWith(Omega.UI.Loader._load_storage_galaxy,
                                galaxy.id, page, cb);
      });

      describe("storage galaxy is null", function(){
        before(function(){
          sinon.stub(Omega.UI.Loader, '_load_storage_galaxy').returns(null);
        });

        it("retrieves remote galaxy", function(){
          sinon.stub(Omega.UI.Loader, '_load_remote_galaxy').
            returns(Omega.UI.Loader.placeholder);
          assert(Omega.UI.Loader.load_galaxy(galaxy.id, page, cb)).
            equals(Omega.UI.Loader.placeholder);
          sinon.assert.calledWith(Omega.UI.Loader._load_remote_galaxy,
                                  galaxy.id, page, cb);
        });
      });
    });
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
      sinon.spy(Omega.Ship, 'owned_by');
      Omega.UI.Loader.load_user_entities('foo', node, cb)
      sinon.assert.calledWith(Omega.Ship.owned_by, 'foo', node, cb);
    });

    it("retrieves stations owned by user", function(){
      sinon.spy(Omega.Station, 'owned_by');
      Omega.UI.Loader.load_user_entities('foo', node, cb)
      sinon.assert.calledWith(Omega.Station.owned_by, 'foo', node, cb);
    });
  });

  describe("#load_default_systems", function(){
    var page;

    before(function(){
      page = new Omega.Pages.Test();
      sinon.stub(Omega.Stat, 'get');
      sinon.stub(Omega.UI.Loader, '_loaded_default_systems');
    });

    after(function(){
      Omega.Stat.get.restore();
      Omega.UI.Loader._loaded_default_systems.restore();
    });

    it("loads systems with most entities", function(){
      Omega.UI.Loader.load_default_systems(page)
      sinon.assert.calledWith(Omega.Stat.get,
        'systems_with_most', ['entities', 15],
         page.node, sinon.match.func);
    });

    it("invokes loaded_default_systems w/ entities retrieved", function(){
      var cb = sinon.spy();
      var result = {value: 'value'};
      Omega.UI.Loader.load_default_systems(page, cb)
      Omega.Stat.get.omega_callback()(result);
      sinon.assert.calledWith(Omega.UI.Loader._loaded_default_systems,
        'value', page, cb);
    });
  });

  //describe("#load_interconnects"); // NIY
});});
