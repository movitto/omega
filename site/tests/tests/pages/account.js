pavlov.specify("Omega.Pages.Account", function(){
describe("Omega.Pages.Account", function(){
  var page;
  before(function(){
    page = new Omega.Pages.Account();
  });

  after(function(){
    if(Omega.Session.restore_from_cookie.restore) Omega.Session.restore_from_cookie.restore();
  });

  it("initializes local config", function(){
    assert(page.config).equals(Omega.Config);
  });

  it("inititalizes local node", function(){
    assert(page.node).isOfType(Omega.Node);
  });

  it("initializes account info dialog", function(){
    assert(page.dialog).isOfType(Omega.UI.AccountDialog);
  });

  it("initializes account info details", function(){
    assert(page.details).isOfType(Omega.UI.AccountDetails);
  });

  it("restores session from cookie", function(){
    var restore_from_cookie = sinon.spy(Omega.Session, 'restore_from_cookie');
    var acct = new Omega.Pages.Account();
    sinon.assert.called(restore_from_cookie);
  });

  it("validates sessions", function(){
    var session = new Omega.Session();
    sinon.stub(Omega.Session, 'restore_from_cookie').returns(session);

    var validate = sinon.spy(session, 'validate');
    var acct = new Omega.Pages.Account();
    sinon.assert.calledWith(validate, acct.node, sinon.match.func);
  });

  describe("session validated", function(){
    var acct, session, validate_cb, user;

    before(function(){
      session = new Omega.Session();
      sinon.stub(Omega.Session, 'restore_from_cookie').returns(session);
      var validate = sinon.spy(session, 'validate');
      acct = new Omega.Pages.Account();
      validate_cb = validate.getCall(0).args[1];

      user = new Omega.User({id : 'user', email : 'u@s.er'});
    });

    after(function(){
      if(Omega.Ship.owned_by.restore) Omega.Ship.owned_by.restore();
      if(Omega.Station.owned_by.restore) Omega.Station.owned_by.restore();
      if(Omega.Stat.get.restore) Omega.Stat.get.restore();
    });

    it("populates account info details container", function(){
      var username = sinon.spy(acct.details, 'username');
      var email    = sinon.spy(acct.details, 'email');
      var gravatar = sinon.spy(acct.details, 'gravatar');
      validate_cb({result : user});
      sinon.assert.calledWith(username, 'user');
      sinon.assert.calledWith(email,    'u@s.er');
      sinon.assert.calledWith(gravatar, 'u@s.er');
    });

    it("retrieves ships owned by user", function(){
      var owned_by = sinon.spy(Omega.Ship, 'owned_by');
      validate_cb({result : user});
      sinon.assert.calledWith(owned_by, session.user_id, acct.node, sinon.match.func);
    });

    describe("retrieve ships callback", function(){
      it("processes_entities with ships retrieved", function(){
        var owned_by = sinon.spy(Omega.Ship, 'owned_by');
        validate_cb({result : user});
        var owned_by_cb = owned_by.getCall(0).args[2];
        var process_entities = sinon.spy(acct, 'process_entities');
        var ships = [new Omega.Ship()];
        owned_by_cb(ships);
        sinon.assert.calledWith(process_entities, ships);
      })
    });

    it("retrieves stations owned by user", function(){
      var owned_by = sinon.spy(Omega.Station, 'owned_by');
      validate_cb({result : user});
      sinon.assert.calledWith(owned_by, session.user_id, acct.node, sinon.match.func);
    });

    describe("retrieve stations callback", function(){
      it("processes_entities with ships retrieved", function(){
        var owned_by = sinon.spy(Omega.Station, 'owned_by');
        validate_cb({result : user});
        var owned_by_cb = owned_by.getCall(0).args[2];
        var process_entities = sinon.spy(acct, 'process_entities');
        var stations = [new Omega.Station()];
        owned_by_cb(stations);
        sinon.assert.calledWith(process_entities, stations);
      });
    });

    it("retrieves user stats", function(){
      var get_stat = sinon.spy(Omega.Stat, 'get');
      validate_cb({result : user});
      sinon.assert.calledWith(get_stat, 'with_most', ['entities', 10], acct.node, sinon.match.func);
    });

    describe("retrieve stats callback", function(){
      it("invokes processes_stat with stats retrieved", function(){
        var get_stat = sinon.spy(Omega.Stat, 'get');
        validate_cb({result : user});
        var get_stat_cb = get_stat.getCall(0).args[3];
        var process_stat = sinon.spy(acct, 'process_stat');
        var stat = new Omega.Stat({value : []});
        get_stat_cb(stat);
        sinon.assert.calledWith(process_stat, stat);
      })
    });
  });

  describe("invalid session", function(){
    it("clears session", function(){
      session = new Omega.Session();
      sinon.stub(Omega.Session, 'restore_from_cookie').returns(session);
      var validate = sinon.spy(session, 'validate');
      var acct = new Omega.Pages.Account();
      validate_cb = validate.getCall(0).args[1];
      validate_cb({error : {}})
      assert(acct.session).isNull();
    })
  });

  describe("#wire_up", function(){
    it("wires up details", function(){
      var wire_up_details = sinon.spy(page.details, 'wire_up');
      page.wire_up();
      sinon.assert.called(wire_up_details);
    });
  });

  describe("#process_entities", function(){
    it("processes each entity", function(){
      var entities = [new Omega.Ship(), new Omega.Station()];
      var process_entity = sinon.spy(page, 'process_entity')
      page.process_entities(entities);
      sinon.assert.calledWith(process_entity, entities[0]);
      sinon.assert.calledWith(process_entity, entities[1]);
    });
  });

  describe("#process_entity", function(){
    it("adds entity to account info entity details", function(){
      var add_entity = sinon.spy(page.details, 'entity');
      var ship = new Omega.Ship();
      page.process_entity(ship);
      sinon.assert.calledWith(add_entity, ship);
    });
  });

  //describe("#process_stats", function(){
  //  describe("local user is in stats", function(){
  //    it("adds badge to account info badges") // NIY
  //  })
  //});
});});
