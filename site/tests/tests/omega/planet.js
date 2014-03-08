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
    //it("updates planet attributes from other planet") NIY
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
    //it("returns modulated integer color") NIY
  });

  describe("#clicked_in", function(){
    //it("folows planet w/ canvas camera") NIY
  });
});}); // Omega.Planet
