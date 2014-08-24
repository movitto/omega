pavlov.specify("Omega.Pages.Account", function(){
describe("Omega.Pages.Account", function(){
  var page;

  before(function(){
    page = new Omega.Pages.Account();
  });

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
