pavlov.specify("Omega.Pages.Confirm", function(){
describe("Omega.Pages.Confirm", function(){ /// NIY
  var page;

  before(function(){
    page = new Omega.Pages.Confirm();
  });

  /// TODO somehow stub out window.location so 'url' and 'redirect_to' can be tested?

  it("loads config", function(){
    assert(page.config).equals(Omega.Config);
  });

  describe("#registration_code", function(){
    it("returns registration code from the url", function(){
      /// stub out call to window.location
      var url = sinon.stub(page, 'url').returns('http://megaverse.info/confirm.html?rc=123456');
      assert(page.registration_code()).equals('123456');
    });
  });

  describe("#confirm_registration", function(){
    var node, http_invoke;
    before(function(){
      node = new Omega.Node();
      page.node = node;
      http_invoke = sinon.stub(node, 'http_invoke');

      /// stub out call to get registration code
      sinon.stub(page, 'registration_code').returns('ABCDEF');
    });

    it("invokes users::confirm_register", function(){
      page.confirm_registration();
      sinon.assert.calledWith(http_invoke, 'users::confirm_register', 'ABCDEF', sinon.match.func);
    });

    describe("users::confirm_register response", function(){
      it("invokes page._registration_response", function(){
        page.confirm_registration();
        var invoke_cb = http_invoke.getCall(0).args[2];
        var registration_response = sinon.stub(page, '_registration_response');
        invoke_cb();
        sinon.assert.called(registration_response);
      });
    });
  });

  describe("#_registration_response", function(){
    before(function(){
      sinon.stub(window, 'alert');
    });

    after(function(){
      window.alert.restore();
    });

    it("redirects the user to the root url", function(){
      var redirect_to = sinon.stub(page, 'redirect_to');
      page._registration_response();
      sinon.assert.calledWith(redirect_to, 'http://'+Omega.Config.http_host+Omega.Config.url_prefix);
    });
  });
});});
