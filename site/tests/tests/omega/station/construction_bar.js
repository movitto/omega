pavlov.specify("Omega.StationConstructionBar", function(){
describe("Omega.StationConstructionBar", function(){
  describe("#update", function(){
    var construction_bar, station;
    before(function(){
      station = new Omega.Station({type : 'manufacturing',
                                   location : new Omega.Location()});
      station.init_gfx();

      construction_bar = station.construction_bar;
    });

    describe("construction percent > 0", function(){
      before(function(){
        station.construction_percent = 0.50;
      });

      it("updates construction progress bar", function(){
        var update = sinon.stub(construction_bar.bar, 'update');
        construction_bar.update();
        sinon.assert.calledWith(update, station.location, 0.50);
      });

      describe("construction progress bar not in station scene components", function(){
        it("adds construction progress bar to station scene components", function(){
          assert(station._has_construction_bar()).isFalse();
          construction_bar.update();
          assert(station._has_construction_bar()).isTrue();
        });
      })
    })

    describe("construction percent == 0 & progress bar in station scene components", function(){
      before(function(){
        station.construction_percent = 0;
      });

      it("does not update construction bar", function(){
        var update = sinon.stub(construction_bar.bar, 'update');
        construction_bar.update();
        sinon.assert.notCalled(update);
      });

      it("removes progress bar from station scene components", function(){
        station._add_construction_bar();
        assert(station._has_construction_bar()).isTrue();
        construction_bar.update();
        assert(station._has_construction_bar()).isFalse();
      });
    })
  });
});}); // Omega.Station
