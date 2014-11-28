pavlov.specify("Omega.Pages.Index", function(){
describe("Omega.Pages.Index", function(){
  var page;

  before(function(){
    page = new Omega.Pages.Index();
  });

  describe("#start", function(){
    before(function(){
      sinon.stub(page.effects_player, 'start');
      sinon.stub(page.splash, 'start');
      sinon.stub(page, 'track_cam');
      sinon.stub(page, 'autologin');
      sinon.stub(page, 'validate_session');
    });

    it("starts effects player", function(){
      page.start();
      sinon.assert.called(page.effects_player.start);
    });

    it("starts splash dialog", function(){
      page.start();
      sinon.assert.called(page.splash.start);
    });

    describe("client should autologin", function(){
      it("autologs in client", function(){
        sinon.stub(page, '_should_autologin').returns(true);
        page.start();
        sinon.assert.called(page.autologin);
      })
    });

    describe("client should not autologin", function(){
      before(function(){
        sinon.stub(page, '_should_autologin').returns(false);
      });

      it("validates session", function(){
        page.start();
        sinon.assert.called(page.validate_session);
      })
    });
  });
});});
