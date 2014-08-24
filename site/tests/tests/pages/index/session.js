pavlov.specify("Omega.Pages.Index", function(){
describe("Omega.Pages.Index", function(){
  var page;

  before(function(){
    page = new Omega.Pages.Index();
  });

  describe("#_valid_session", function(){
    var load_universe, load_user_entities;
    before(function(){
      page.session = new Omega.Session();

      /// stub out call to load_universe and load_user_entities
      load_universe = sinon.stub(Omega.UI.Loader, 'load_universe');
      load_user_entities = sinon.stub(Omega.UI.Loader, 'load_user_entities');
    });

    after(function(){
      Omega.UI.Loader.load_universe.restore();
      Omega.UI.Loader.load_user_entities.restore();
    });

    it("shows logout controls", function(){
      sinon.spy(page.nav, 'show_logout_controls');
      page._valid_session();
      sinon.assert.called(page.nav.show_logout_controls);
    });

    it("shows the missions button", function(){
      sinon.spy(page.canvas.controls.missions_button, 'show')
      page._valid_session();
      sinon.assert.called(page.canvas.controls.missions_button.show);
    });

    it("handles events", function(){
      sinon.spy(page, '_handle_events');
      page._valid_session();
      sinon.assert.called(page._handle_events);
    });

    it("loads universe id", function(){
      page._valid_session();
      sinon.assert.calledWith(load_universe, page, sinon.match.func);
    });

    it("loads user entities", function(){
      page._valid_session();
      var load_cb = load_universe.getCall(0).args[1];
      load_cb();
      sinon.assert.called(load_user_entities);
    });

    it("processes entities retrieved", function(){
      page._valid_session();
      var load_cb = load_universe.getCall(0).args[1];
      load_cb();

      var shcb = load_user_entities.getCall(0).args[2];
      var stcb = load_user_entities.getCall(0).args[2];

      var spy = sinon.stub(page, 'process_entities');
      shcb('ships')
      stcb('stations');
      sinon.assert.calledWith(spy, 'ships');
      sinon.assert.calledWith(spy, 'stations');
    });

    describe("autoload root is set", function(){
      it("autoloads root", function(){
        page._valid_session();
        load_universe.omega_callback()();

        sinon.stub(page, 'process_entities');
        sinon.stub(page, '_should_autoload_root').returns(true);
        sinon.stub(page, 'autoload_root');
        load_user_entities.omega_callback()();
        sinon.assert.called(page.autoload_root);
      });
    });
  });

  describe("#_invalid_session", function(){
    var session;

    before(function(){
      session = new Omega.Session();
      page.session = session;

      /// stub out calls were testing
      sinon.stub(page, '_login_anon');
      sinon.stub(Omega.UI.Loader, 'load_default_systems');
      sinon.stub(Omega.UI.Loader, 'load_universe');
    });

    after(function(){
      Omega.UI.Loader.load_universe.restore();
      Omega.UI.Loader.load_default_systems.restore();
      if(Omega.Session.login.restore) Omega.Session.login.restore();
    });

    it("clears session cookies", function(){
      sinon.spy(session, 'clear_cookies');
      page._invalid_session();
      sinon.assert.called(session.clear_cookies);
    });

    it("nullifies session", function(){
      page._invalid_session();
      assert(page.session).isNull();
    });

    it("shows login controls", function(){
      sinon.spy(page.nav, 'show_login_controls');
      page._invalid_session();
      sinon.assert.called(page.nav.show_login_controls);
    });

    it("logs anonymous user in", function(){
      page._invalid_session();
      sinon.assert.called(page._login_anon);
    });

    it("loads universe id", function(){
      page._invalid_session();
      page._login_anon.omega_callback()();
      sinon.assert.calledWith(Omega.UI.Loader.load_universe, page, sinon.match.func);
    });

    it("loads default systems", function(){
      page._invalid_session();
      page._login_anon.omega_callback()();
      Omega.UI.Loader.load_universe.omega_callback()();
      sinon.assert.called(Omega.UI.Loader.load_default_systems);
    });

    it("processes default systems", function(){
      var sys = Omega.Gen.solar_system();
      page._invalid_session();
      page._login_anon.omega_callback()();
      Omega.UI.Loader.load_universe.omega_callback()();

      sinon.stub(page, 'process_system');
      Omega.UI.Loader.load_default_systems.omega_callback()(sys);
      sinon.assert.calledWith(page.process_system, sys);
    });

    describe("autoload root is set", function(){
      it("autoloads root", function(){
        page._invalid_session();
        page._login_anon.omega_callback()();
        Omega.UI.Loader.load_universe.omega_callback()();

        sinon.stub(page, 'process_system');
        sinon.stub(page, '_should_autoload_root').returns(true);
        sinon.stub(page, 'autoload_root');
        Omega.UI.Loader.load_default_systems.omega_callback()();
        sinon.assert.called(page.autoload_root);
      });
    });
  });
});});
