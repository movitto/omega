pavlov.specify("Omega.Pages.Index", function(){
describe("Omega.Pages.Index", function(){
  it("loads config", function(){
    var index = new Omega.Pages.Index();
    assert(index.config).equals();
  });

  it("has a node", function(){
    var index = new Omega.Pages.Index();
    assert(index.node).isOfType(Omega.Node);
  });

  it("has a callback handler", function(){
    var index = new Omega.Pages.Index();
    assert(index.callback_handler).isOfType(Omega.CallbackHandler);
  });

  it("has an effects player", function(){
    var index = new Omega.Pages.Index();
    assert(index.effects_player).isOfType(Omega.UI.EffectsPlayer);
    assert(index.effects_player.page).equals(index);
  });

  it("has an index dialog", function(){
    var index = new Omega.Pages.Index();
    assert(index.dialog).isOfType(Omega.Pages.IndexDialog);
    assert(index.dialog.page).isSameAs(index);
  });

  it("has an index nav", function(){
    var index = new Omega.Pages.Index();
    assert(index.nav).isOfType(Omega.Pages.IndexNav);
    assert(index.nav.page).isSameAs(index);
  });

  it("has a canvas", function(){
    var index = new Omega.Pages.Index();
    assert(index.canvas).isOfType(Omega.UI.Canvas);
  });

  it("has a status indicator", function(){
    var index = new Omega.Pages.Index();
    assert(index.status_indicator).isOfType(Omega.UI.StatusIndicator);
  });

  it("has audio controls", function(){
    var index = new Omega.Pages.Index();
    assert(index.audio_controls).isOfType(Omega.UI.AudioControls);
  });

  it("has a splash screen", function(){
    var index = new Omega.Pages.Index();
    assert(index.splash).isOfType(Omega.UI.SplashScreen);
  });

  describe("#wire_up", function(){
    var index;

    before(function(){
      index = new Omega.Pages.Index();
      sinon.stub(index.nav,    'wire_up');
      sinon.stub(index.dialog, 'wire_up');
      sinon.stub(index.canvas, 'wire_up');
      sinon.stub(index.audio_controls, 'wire_up');
      sinon.stub(index.splash, 'wire_up');
      sinon.stub(index.effects_player, 'wire_up');
      sinon.stub(index.dialog, 'follow_node');
      sinon.stub(index, 'handle_scene_changes');
      sinon.stub(index, '_wire_up_fullscreen');
    });

    it("wires up navigation", function(){
      index.wire_up();
      sinon.assert.called(index.nav.wire_up);
    });

    it("wires up dialog", function(){
      index.wire_up();
      sinon.assert.called(index.dialog.wire_up);
    });

    it("instructs dialog to follow node", function(){
      index.wire_up();
      sinon.assert.calledWith(index.dialog.follow_node, index.node);
    });

    it("wires up splash", function(){
      index.wire_up();
      sinon.assert.called(index.splash.wire_up);
    });

    it("wires up canvas", function(){
      index.wire_up();
      sinon.assert.called(index.canvas.wire_up);
    });

    it("wires up audio controls", function(){
      index.wire_up();
      sinon.assert.called(index.audio_controls.wire_up);
    });

    it("handles scene changes", function(){
      index.wire_up();
      sinon.assert.called(index.handle_scene_changes);
    });

    it("instructs status indicator to follow node", function(){
      var spy   = sinon.spy(index.status_indicator, 'follow_node');
      index.wire_up();
      sinon.assert.calledWith(spy, index.node);
    });

    it("wires up effects_player", function(){
      index.wire_up();
      sinon.assert.called(index.effects_player.wire_up);
    });

    it("wires up fullscreen controls", function(){
      index.wire_up();
      sinon.assert.called(index._wire_up_fullscreen);
    });
  });

  describe("#_wire_up_fullscreen", function(){
    var index;

    before(function(){
      index = new Omega.Pages.Index();
      sinon.stub(Omega.fullscreen, 'request');
    });

    after(function(){
      Omega.fullscreen.request.restore();
    });

    it("handles document keypresses", function(){
      assert($(document)).doesNotHandle('keypress');
      index._wire_up_fullscreen();
      assert($(document)).handles('keypress');
    });

    describe("ctrl-F keyPress triggered", function(){
      it("requests full screen", function(){
        index._wire_up_fullscreen();
        $(document).trigger(jQuery.Event('keypress', {which : 70, ctrlKey : 1}));
        sinon.assert.calledWith(Omega.fullscreen.request, document.documentElement);
      });
    });

    describe("ctrl-f keyPress triggered", function(){
      it("requests full screen", function(){
        index._wire_up_fullscreen();
        $(document).trigger(jQuery.Event('keypress', {which : 102, ctrlKey : 1}));
        sinon.assert.calledWith(Omega.fullscreen.request, document.documentElement);
      });
    });

    describe("other keypress triggered", function(){
      it("does not request fullscreen", function(){
        index._wire_up_fullscreen();
        $(document).trigger(jQuery.Event('keypress', {which : 102}));
        $(document).trigger(jQuery.Event('keypress', {which : 105, ctrlKey : 1}));
        sinon.assert.notCalled(Omega.fullscreen.request);
      });
    });
  });

  describe("#unload", function(){
    it("sets unloading true", function(){
      var index = new Omega.Pages.Index();
      assert(index.unloading).isUndefined();
      index.unload();
      assert(index.unloading).isTrue();
    });

    it("closes node", function(){
      var index = new Omega.Pages.Index();
      sinon.stub(index.node, 'close');
      index.unload();
      sinon.assert.called(index.node.close);
    })
  });

  describe("#start", function(){
    var index;

    before(function(){
      index = new Omega.Pages.Index();
      sinon.stub(index.effects_player, 'start');
      sinon.stub(index.splash, 'start');
      sinon.stub(index, 'autologin');
      sinon.stub(index, 'validate_session');
    });

    it("starts effects player", function(){
      index.start();
      sinon.assert.called(index.effects_player.start);
    });

    it("starts splash dialog", function(){
      index.start();
      sinon.assert.called(index.splash.start);
    });

    describe("client should autologin", function(){
      it("autologs in client", function(){
        sinon.stub(index, '_should_autologin').returns(true);
        index.start();
        sinon.assert.called(index.autologin);
      })
    });

    describe("client should not autologin", function(){
      before(function(){
        sinon.stub(index, '_should_autologin').returns(false);
      });

      it("validates session", function(){
        index.start();
        sinon.assert.called(index.validate_session);
      })
    });
  });


  describe("#_valid_session", function(){
    var index, load_universe, load_user_entities;
    before(function(){
      index = new Omega.Pages.Index();
      index.session = new Omega.Session();

      /// stub out call to load_universe and load_user_entities
      load_universe = sinon.stub(Omega.UI.Loader, 'load_universe');
      load_user_entities = sinon.stub(Omega.UI.Loader, 'load_user_entities');
    });

    after(function(){
      Omega.UI.Loader.load_universe.restore();
      Omega.UI.Loader.load_user_entities.restore();
    });

    it("shows logout controls", function(){
      sinon.spy(index.nav, 'show_logout_controls');
      index._valid_session();
      sinon.assert.called(index.nav.show_logout_controls);
    });

    it("shows the missions button", function(){
      sinon.spy(index.canvas.controls.missions_button, 'show')
      index._valid_session();
      sinon.assert.called(index.canvas.controls.missions_button.show);
    });

    it("handles events", function(){
      sinon.spy(index, '_handle_events');
      index._valid_session();
      sinon.assert.called(index._handle_events);
    });

    it("loads universe id", function(){
      index._valid_session();
      sinon.assert.calledWith(load_universe, index, sinon.match.func);
    });

    it("loads user entities", function(){
      index._valid_session();
      var load_cb = load_universe.getCall(0).args[1];
      load_cb();
      sinon.assert.called(load_user_entities);
    });

    it("processes entities retrieved", function(){
      index._valid_session();
      var load_cb = load_universe.getCall(0).args[1];
      load_cb();

      var shcb = load_user_entities.getCall(0).args[2];
      var stcb = load_user_entities.getCall(0).args[2];

      var spy = sinon.stub(index, 'process_entities');
      shcb('ships')
      stcb('stations');
      sinon.assert.calledWith(spy, 'ships');
      sinon.assert.calledWith(spy, 'stations');
    });

    describe("autoload root is set", function(){
      it("autoloads root", function(){
        index._valid_session();
        load_universe.omega_callback()();

        sinon.stub(index, 'process_entities');
        sinon.stub(index, '_should_autoload_root').returns(true);
        sinon.stub(index, 'autoload_root');
        load_user_entities.omega_callback()();
        sinon.assert.called(index.autoload_root);
      });
    });
  });

  describe("#_invalid_session", function(){
    var session, index;

    before(function(){
      index = new Omega.Pages.Index();
      session = new Omega.Session();
      index.session = session;

      /// stub out calls were testing
      sinon.stub(index, '_login_anon');
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
      index._invalid_session();
      sinon.assert.called(session.clear_cookies);
    });

    it("nullifies session", function(){
      index._invalid_session();
      assert(index.session).isNull();
    });

    it("shows login controls", function(){
      sinon.spy(index.nav, 'show_login_controls');
      index._invalid_session();
      sinon.assert.called(index.nav.show_login_controls);
    });

    it("logs anonymous user in", function(){
      index._invalid_session();
      sinon.assert.called(index._login_anon);
    });

    it("loads universe id", function(){
      index._invalid_session();
      index._login_anon.omega_callback()();
      sinon.assert.calledWith(Omega.UI.Loader.load_universe, index, sinon.match.func);
    });

    it("loads default systems", function(){
      index._invalid_session();
      index._login_anon.omega_callback()();
      Omega.UI.Loader.load_universe.omega_callback()();
      sinon.assert.called(Omega.UI.Loader.load_default_systems);
    });

    it("processes default systems", function(){
      var sys = Omega.Gen.solar_system();
      index._invalid_session();
      index._login_anon.omega_callback()();
      Omega.UI.Loader.load_universe.omega_callback()();

      sinon.stub(index, 'process_system');
      Omega.UI.Loader.load_default_systems.omega_callback()(sys);
      sinon.assert.calledWith(index.process_system, sys);
    });

    describe("autoload root is set", function(){
      it("autoloads root", function(){
        index._invalid_session();
        index._login_anon.omega_callback()();
        Omega.UI.Loader.load_universe.omega_callback()();

        sinon.stub(index, 'process_system');
        sinon.stub(index, '_should_autoload_root').returns(true);
        sinon.stub(index, 'autoload_root');
        Omega.UI.Loader.load_default_systems.omega_callback()();
        sinon.assert.called(index.autoload_root);
      });
    });
  });
});});
