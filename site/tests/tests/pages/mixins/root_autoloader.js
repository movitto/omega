pavlov.specify("Omega.Pages.RootAutoloader", function(){
describe("Omega.Pages.RootAutoloader", function(){
  describe("#_default_root_id", function(){
    var page, url, orig_config;

    before(function(){
      page = $.extend({}, Omega.Pages.RootAutoloader);

      url = $.url(window.location);
      sinon.stub($, 'url').returns(url);
      orig_config = Omega.Config.default_root;
    });

    after(function(){
      $.url.restore();
      Omega.Config.default_root = orig_config;
    });

    it("returns url 'root' param", function(){
      sinon.stub(url, 'param').returns('custom');
      assert(page._default_root_id()).equals('custom');
    });

    it("returns config 'default_root'", function(){
      sinon.stub(url, 'param').returns(null);
      Omega.Config.default_root = 'custom';
      assert(page._default_root_id()).equals('custom');
    });

    describe("url root param and config default_root not set", function(){
      it("returns null", function(){
        sinon.stub(url, 'param').returns(null);
        Omega.Config.default_root = null;
        assert(page._default_root_id()).equals(null);
      });
    });
  });

  describe("#_default_root", function(){
    var page, sys1, sys2, gal1;

    before(function(){
      page = $.extend({}, Omega.Pages.RootAutoloader,
                          Omega.Pages.HasRegistry);
      page.init_registry();
      sys1 = Omega.Gen.solar_system();
      sys2 = Omega.Gen.solar_system();
      gal1 = Omega.Gen.galaxy();
      sinon.stub(page, 'systems').returns([sys1, sys2])
      sinon.stub(page, 'galaxies').returns([gal1]);
    });

    describe("default root id is random", function(){
      it("returns random system or galaxy from entities registry", function(){
        sinon.stub(page, '_default_root_id').returns('random');
        assert([sys1, sys2, gal1]).includes(page._default_root());
      });
    });

    it("return entity with specified id from entities registry", function(){
      page.entity(sys1.id, sys1);
      sinon.stub(page, '_default_root_id').returns(sys1.id);
      assert(page._default_root()).equals(sys1);
    });

    it("return entity with specified name from entities registry", function(){
      sys1.name = 'name';
      page.entity(sys1.id, sys1);
      sinon.stub(page, '_default_root_id').returns(sys1.name);
      assert(page._default_root()).equals(sys1);
    });
  });

  describe("#_should_autoload_root", function(){
    var page;
    before(function(){
      page = $.extend({}, Omega.Pages.RootAutoloader);
    });

    describe("already autoloaded", function(){
      it("returns false", function(){
        page.autoloaded = true;
        assert(page._should_autoload_root()).isFalse();
      });
    });

    describe("default root is null", function(){
      it("returns false", function(){
        page.autoloaded = false;
        sinon.stub(page, '_default_root').returns(null);
        assert(page._should_autoload_root()).isFalse();
      });
    });

    describe("not autoloaded and default root is set", function(){
      it("returns true", function(){
        page.autoloaded = false;
        sinon.stub(page, '_default_root').returns(Omega.Gen.solar_system());
        assert(page._should_autoload_root()).isTrue();
      })
    })
  });

  describe("#autoload_root", function(){
    var page, sys1;
    before(function(){
      page = $.extend({node : new Omega.Node(),
                       canvas : new Omega.UI.Canvas()},
                      Omega.Pages.RootAutoloader, Omega.Pages.HasRegistry);
      page.init_registry();
      sys1 = Omega.Gen.solar_system();

      sinon.stub(page, '_default_root').returns(sys1);
      sinon.stub(sys1, 'refresh');
    });

    it("sets autoloaded to true", function(){
      page.autoload_root();
      assert(page.autoloaded).isTrue();
    });

    it("refreshes default root", function(){
      page.autoload_root();
      sinon.assert.calledWith(sys1.refresh, page.node, sinon.match.func);
    });

    it("sets scene root to default root", function(){
      sinon.stub(page.canvas, 'set_scene_root');
      page.autoload_root();
      sys1.refresh.omega_callback()();
      sinon.assert.calledWith(page.canvas.set_scene_root, sys1);
    });
  });

});});
