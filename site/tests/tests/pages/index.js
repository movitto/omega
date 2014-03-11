pavlov.specify("Omega.Pages.Index", function(){
describe("Omega.Pages.Index", function(){
  it("loads config", function(){
    var index = new Omega.Pages.Index();
    assert(index.config).equals(Omega.Config);
  });

  it("has a node", function(){
    var index = new Omega.Pages.Index();
    assert(index.node).isOfType(Omega.Node);
  });

  it("has an entities registry", function(){
    var index = new Omega.Pages.Index();
    assert(index.entities).isNotNull(); /// XXX
  });

  it("has a command tracker", function(){
    var index = new Omega.Pages.Index();
    assert(index.command_tracker).isOfType(Omega.UI.CommandTracker);
  });

  it("has a status indicator", function(){
    var index = new Omega.Pages.Index();
    assert(index.status_indicator).isOfType(Omega.UI.StatusIndicator);
  });

  it("has audio controls", function(){
    var index = new Omega.Pages.Index();
    assert(index.audio_controls).isOfType(Omega.UI.AudioControls);
  });

  it("has an effects player", function(){
    var index = new Omega.Pages.Index();
    assert(index.effects_player).isOfType(Omega.UI.EffectsPlayer);
    assert(index.effects_player.page).equals(index);
  });

  it("has an index dialog", function(){
    var index = new Omega.Pages.Index();
    assert(index.dialog).isOfType(Omega.UI.IndexDialog);
    assert(index.dialog.page).isSameAs(index);
  });

  it("has an index nav", function(){
    var index = new Omega.Pages.Index();
    assert(index.nav).isOfType(Omega.UI.IndexNav);
    assert(index.nav.page).isSameAs(index);
  });

  it("has a canvas", function(){
    var index = new Omega.Pages.Index();
    assert(index.canvas).isOfType(Omega.UI.Canvas);
  });

  describe("#wire_up", function(){
    var index,
        wire_nav, wire_dialog, wire_canvas, dialog_follow;

    before(function(){
      index = new Omega.Pages.Index();
      wire_nav    = sinon.stub(index.nav,    'wire_up');
      wire_dialog = sinon.stub(index.dialog, 'wire_up');
      wire_canvas = sinon.stub(index.canvas, 'wire_up');
      wire_audio  = sinon.stub(index.audio_controls, 'wire_up');
      dialog_follow = sinon.stub(index.dialog, 'follow_node');
    });

    it("wires up navigation", function(){
      index.wire_up();
      sinon.assert.called(wire_nav);
    });

    it("wires up dialog", function(){
      index.wire_up();
      sinon.assert.called(wire_dialog);
    });

    it("instructs dialog to follow node", function(){
      index.wire_up();
      sinon.assert.calledWith(dialog_follow, index.node);
    });

    it("wires up canvas", function(){
      index.wire_up();
      sinon.assert.called(wire_canvas);
    });

    it("wires up audio controls", function(){
      index.wire_up();
      sinon.assert.called(wire_audio);
    });

    it("wires up canvas scene change", function(){
      assert(index.canvas._listeners).isUndefined();
      index.wire_up();
      assert(index.canvas._listeners['set_scene_root'].length).equals(1);
    });

    describe("on canvas scene change", function(){
      it("invokes page.scene_change", function(){
        index.wire_up();
        var scene_changed_cb = index.canvas._listeners['set_scene_root'][0];
        var scene_change = sinon.stub(index, 'scene_change');
        scene_changed_cb({data: 'change'});
        sinon.assert.calledWith(scene_change, 'change')
      });
    })

    it("instructs status indicator to follow node", function(){
      var spy   = sinon.spy(index.status_indicator, 'follow_node');
      index.wire_up();
      sinon.assert.calledWith(spy, index.node);
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
      var shspy = sinon.spy(Omega.Ship, 'owned_by');
      var stspy = sinon.spy(Omega.Station, 'owned_by');
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
  });

  describe("#_invalid_session", function(){
    var session, index, load_universe, load_default_systems;
    before(function(){
      index = new Omega.Pages.Index();
      session = new Omega.Session();
      index.session = session;

      /// stub out load universe call
      load_default_systems = sinon.stub(Omega.UI.Loader, 'load_default_systems');
      load_universe = sinon.stub(Omega.UI.Loader, 'load_universe');
    });

    after(function(){
      Omega.UI.Loader.load_universe.restore();
      Omega.UI.Loader.load_default_systems.restore();
      if(Omega.Session.login.restore) Omega.Session.login.restore();
    });

    it("loads universe id", function(){
      index._invalid_session();
      sinon.assert.calledWith(load_universe, index, sinon.match.func);
    });

    it("loads default entities", function(){
      index._invalid_session();
      var load_cb = load_universe.getCall(0).args[1];
      load_cb();
      sinon.assert.called(load_default_systems);
    });
  });
});});
