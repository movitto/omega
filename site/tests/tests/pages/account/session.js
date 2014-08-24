pavlov.specify("Omega.Pages.Account", function(){
describe("Omega.Pages.Account", function(){
  var page;

  before(function(){
    page = new Omega.Pages.Account();
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
});});
