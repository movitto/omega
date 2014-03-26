pavlov.specify("Omega.Pages.Account", function(){
describe("Omega.Pages.Account", function(){
  var page;

  before(function(){
    page = new Omega.Pages.Account();
  });

  after(function(){
  });

  it("has a copy of the Omega config", function(){
    assert(page.config).equals(Omega.Config);
  });

  it("has a node", function(){
    assert(page.node).isOfType(Omega.Node);
  });

  it("has an account info dialog instance", function(){
    assert(page.dialog).isOfType(Omega.UI.AccountDialog);
  });

  it("has an account info details instance", function(){
    assert(page.details).isOfType(Omega.UI.AccountDetails);
  });

  describe("#wire_up", function(){
    it("wires up details", function(){
      var wire_up_details = sinon.spy(page.details, 'wire_up');
      page.wire_up();
      sinon.assert.called(wire_up_details);
    });
  });

  describe("#start", function(){
    before(function(){
      sinon.stub(page, 'validate_session');
    });

    it("validates session", function(){
      page.start();
      sinon.assert.called(page.validate_session);
    });

    describe("on session validation", function(){
      it("invokes _valid_session", function(){
        sinon.stub(page, '_valid_session');
        page.start();

        var validated_cb = page.validate_session.getCall(0).args[0];
        validated_cb();
        sinon.assert.called(page._valid_session);
      });
    });
  });

  describe("#_valid_session", function(){
    before(function(){
      page.session = new Omega.Session({user : Omega.Gen.user()});
      sinon.stub(Omega.Ship, 'owned_by');
      sinon.stub(Omega.Station, 'owned_by');
      sinon.stub(Omega.Stat, 'get');
    });

    after(function(){
      Omega.Ship.owned_by.restore();
      Omega.Station.owned_by.restore();
      Omega.Stat.get.restore();
    });

    it("sets details user", function(){
      sinon.stub(page.details, 'set');
      page._valid_session();
      sinon.assert.calledWith(page.details.set, page.session.user);
    });

    it("loads ships owned by user", function(){
      page._valid_session();
      sinon.assert.calledWith(Omega.Ship.owned_by, page.session.user.id,
                              page.node, sinon.match.func);
    });

    it("processes loaded ships", function(){
      var ships = [Omega.Gen.ship()];
      page._valid_session();
      sinon.stub(page, 'process_entities');
      Omega.Ship.owned_by.omega_callback()(ships);
      sinon.assert.calledWith(page.process_entities, ships);
    });

    it("loads stations owned by user", function(){
      page._valid_session();
      sinon.assert.calledWith(Omega.Station.owned_by, page.session.user.id,
                              page.node, sinon.match.func);
    });

    it("processes loaded stations", function(){
      var stations = [Omega.Gen.station()];
      page._valid_session();
      sinon.stub(page, 'process_entities');
      Omega.Station.owned_by.omega_callback()(stations);
      sinon.assert.calledWith(page.process_entities, stations);
    });

    it("retrieves users_with_most entities stat", function(){
      page._valid_session();
      sinon.assert.calledWith(Omega.Stat.get, 'users_with_most',
                              ['entities', 10], page.node, sinon.match.func);
    });

    it("process stat retrieved", function(){
      var stat = {};
      page._valid_session();
      sinon.stub(page, 'process_stat');
      Omega.Stat.get.omega_callback()(stat);
      sinon.assert.calledWith(page.process_stat, stat);
    });
  })

  describe("#process_entities", function(){
    it("processes each entity", function(){
      var entities = [new Omega.Ship(), new Omega.Station()];
      sinon.spy(page, 'process_entity')
      page.process_entities(entities);
      sinon.assert.calledWith(page.process_entity, entities[0]);
      sinon.assert.calledWith(page.process_entity, entities[1]);
    });
  });

  describe("#process_entity", function(){
    it("adds entity to account info entity details", function(){
      sinon.spy(page.details, 'entity');
      var ship = new Omega.Ship();
      page.process_entity(ship);
      sinon.assert.calledWith(page.details.entity, ship);
    });
  });

  describe("#process_stat", function(){
    describe("session user in stat result list", function(){
      var result;

      before(function(){
        page.session = new Omega.Session({user_id : 'user1'});
        result = {stat  : {id : 'stat1', description : 'statd'},
                  value : ['userA1', page.session.user_id]};
      });

      it("adds badge to account details", function(){
        sinon.stub(page.details, 'add_badge');
        page.process_stat(result);
        sinon.assert.calledWith(page.details.add_badge, 'stat1', 'statd', 1);
      });
    });

    describe("session user not in stat result list", function(){
      var result;

      before(function(){
        page.session = new Omega.Session({user_id : 'user1'});
        result = {stat  : {id : 'stat1', description : 'statd'},
                  value : ['userA1']};
      });

      it("does not add badge to account details", function(){
        sinon.stub(page.details, 'add_badge');
        page.process_stat(result);
        sinon.assert.notCalled(page.details.add_badge);
      });
    });
  });
});});
