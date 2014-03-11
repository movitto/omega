pavlov.specify("Omega.Planet", function(){
describe("Omega.Planet", function(){
  it("converts location", function(){
    var planet = new Omega.Planet({location :
      {json_class : 'Motel::Location', data : {x: 10, y: 20, z:30}}});
    assert(planet.location).isOfType(Omega.Location);
    assert(planet.location.x).equals(10);
    assert(planet.location.y).equals(20);
    assert(planet.location.z).equals(30);
  });

  describe("#update", function(){
    it("updates planet location", function(){
      var  planet = Omega.Gen.planet();
      var nplanet = Omega.Gen.planet();
      sinon.spy(planet.location, 'update');
      planet.update(nplanet);
      sinon.assert.calledWith(planet.location.update, nplanet.location);
    });
  });

  describe("#toJSON", function(){
    it("returns planet json data", function(){
      var pl  = {id          : 'pl1',
                 name        : 'pl1n',
                 parent_id   : 'sys1',
                 location    : new Omega.Location({id : 'pl1l'}),
                 color       : 'ABABAB',
                 size        : 100};

      var opl  = new Omega.Planet(pl);
      var json = opl.toJSON();

      pl.json_class  = opl.json_class;
      pl.location    = pl.location.toJSON();
      assert(json).isSameAs(pl);
    });
  });

  describe("#colori", function(){
    it("returns modulated integer color", function(){
      var planet = Omega.Gen.planet();
      planet.color = '000000';
      assert(planet.colori()).equals(0);

      planet.color = '000001';
      assert(planet.colori()).equals(1);

      planet.color = planet._num_textures;
      assert(planet.colori()).equals(0);

      planet.color = planet._num_textures + 1;
      assert(planet.colori()).equals(1);
    });
  });

  describe("#clicked_in", function(){
    var page;
    before(function(){
      page = Omega.Test.Page();
      sinon.stub(page.canvas, 'follow');
    });

    after(function(){
      page.canvas.follow.restore();
    });

    it("follows planet w/ canvas camera", function(){
      var planet = Omega.Gen.planet();
      planet.clicked_in(page.canvas);
      sinon.assert.calledWith(page.canvas.follow, planet.location);
    });
  });
});}); // Omega.Planet
