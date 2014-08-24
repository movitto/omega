pavlov.specify("Omega.Pages.Index", function(){
describe("Omega.Pages.Index", function(){
  var page;

  before(function(){
    page = new Omega.Pages.Index();
  });

  it("has a callback handler", function(){
    assert(page.callback_handler).isOfType(Omega.CallbackHandler);
  });


  it("has an index dialog", function(){
    assert(page.dialog).isOfType(Omega.Pages.IndexDialog);
    assert(page.dialog.page).isSameAs(page);
  });

  it("has an index nav", function(){
    assert(page.nav).isOfType(Omega.Pages.IndexNav);
    assert(page.nav.page).isSameAs(page);
  });

  it("has a status indicator", function(){
    assert(page.status_indicator).isOfType(Omega.UI.StatusIndicator);
  });

  it("has a splash screen", function(){
    assert(page.splash).isOfType(Omega.UI.SplashScreen);
  });

  describe("#wire_up", function(){
    before(function(){
      sinon.stub(page.nav,    'wire_up');
      sinon.stub(page.dialog, 'wire_up');
      sinon.stub(page.canvas, 'wire_up');
      sinon.stub(page.audio_controls, 'wire_up');
      sinon.stub(page.splash, 'wire_up');
      sinon.stub(page.effects_player, 'wire_up');
      sinon.stub(page.dialog, 'follow_node');
      sinon.stub(page, 'handle_scene_changes');
      sinon.stub(page, '_wire_up_fullscreen');
    });

    it("wires up navigation", function(){
      page.wire_up();
      sinon.assert.called(page.nav.wire_up);
    });

    it("wires up dialog", function(){
      page.wire_up();
      sinon.assert.called(page.dialog.wire_up);
    });

    it("instructs dialog to follow node", function(){
      page.wire_up();
      sinon.assert.calledWith(page.dialog.follow_node, page.node);
    });

    it("wires up splash", function(){
      page.wire_up();
      sinon.assert.called(page.splash.wire_up);
    });

    it("wires up canvas", function(){
      page.wire_up();
      sinon.assert.called(page.canvas.wire_up);
    });

    it("wires up audio controls", function(){
      page.wire_up();
      sinon.assert.called(page.audio_controls.wire_up);
    });

    it("handles scene changes", function(){
      page.wire_up();
      sinon.assert.called(page.handle_scene_changes);
    });

    it("instructs status indicator to follow node", function(){
      var spy   = sinon.spy(page.status_indicator, 'follow_node');
      page.wire_up();
      sinon.assert.calledWith(spy, page.node);
    });

    it("wires up effects_player", function(){
      page.wire_up();
      sinon.assert.called(page.effects_player.wire_up);
    });

    it("wires up fullscreen controls", function(){
      page.wire_up();
      sinon.assert.called(page._wire_up_fullscreen);
    });
  });

  describe("#_wire_up_fullscreen", function(){
    before(function(){
      sinon.stub(Omega.fullscreen, 'request');
    });

    after(function(){
      Omega.fullscreen.request.restore();
    });

    it("handles document keypresses", function(){
      assert($(document)).doesNotHandle('keypress');
      page._wire_up_fullscreen();
      assert($(document)).handles('keypress');
    });

    describe("ctrl-F keyPress triggered", function(){
      it("requests full screen", function(){
        page._wire_up_fullscreen();
        $(document).trigger(jQuery.Event('keypress', {which : 70, ctrlKey : 1}));
        sinon.assert.calledWith(Omega.fullscreen.request, document.documentElement);
      });
    });

    describe("ctrl-f keyPress triggered", function(){
      it("requests full screen", function(){
        page._wire_up_fullscreen();
        $(document).trigger(jQuery.Event('keypress', {which : 102, ctrlKey : 1}));
        sinon.assert.calledWith(Omega.fullscreen.request, document.documentElement);
      });
    });

    describe("other keypress triggered", function(){
      it("does not request fullscreen", function(){
        page._wire_up_fullscreen();
        $(document).trigger(jQuery.Event('keypress', {which : 102}));
        $(document).trigger(jQuery.Event('keypress', {which : 105, ctrlKey : 1}));
        sinon.assert.notCalled(Omega.fullscreen.request);
      });
    });
  });
});});
