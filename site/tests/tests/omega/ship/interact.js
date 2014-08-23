// Test mixin usage through ship
pavlov.specify("Omega.ShipInteraction", function(){
describe("Omega.ShipInteraction", function(){
  var ship, page;

  before(function(){
    ship = Omega.Gen.ship();
    ship.location.set(0,0,0);
    page = new Omega.Pages.Test();
  });

  describe("#context_action", function(){
    before(function(){
      page.session = new Omega.Session({user_id : 'user1'});
      ship.user_id = 'user1';

      /// stub out move / follow calls
      sinon.spy(ship, '_move');
      sinon.spy(ship, '_follow');
    });

    describe("user not logged in", function(){
      it("does not invoke move/follow", function(){
        page.session = null;
        ship.context_action(new Omega.Ship(), page);
        sinon.assert.notCalled(ship._move);
        sinon.assert.notCalled(ship._follow);
      });
    });

    describe("user does not own ship", function(){
      it("does not invoke move/follow", function(){
        ship.user_id = 'foo';
        ship.context_action(new Omega.Ship(), page);
        sinon.assert.notCalled(ship._move);
        sinon.assert.notCalled(ship._follow);
      });
    });

    describe("_should_move_to entity returns true", function(){
      it("moves to entity + offset", function(){
        sinon.stub(ship, '_should_move_to').returns(true);

        var loc = new Omega.Location();
        loc.set(100, 100, 100);
        var entity = new Omega.Station({location : loc});
        ship.context_action(entity, page);
        sinon.assert.calledWith(ship._move, page);

        var config_offset = Omega.Config.movement_offset;
        var move_offset   = ship._move.getCall(0).args;
        for(var o = 1; o < 4; o++){
          assert(move_offset[o]).isLessThan(100 + config_offset.max);
          assert(move_offset[o]).isGreaterThan(100 + config_offset.min);
        }
      });
    });

    describe("_should_follow entity returns true", function(){
      it("follows entity", function(){
        sinon.stub(ship, '_should_move_to').returns(false);
        sinon.stub(ship, '_should_follow').returns(true);
        ship.context_action({id : 'entity1'}, page);
        sinon.assert.calledWith(ship._follow, page, 'entity1')
      });
    });
  });
});});
