pavlov.specify("Omega.Asteroid", function(){
describe("Omega.Asteroid", function(){
  it("converts location", function(){
    var ast = new Omega.Asteroid({location : {json_class : 'Motel::Location', data : {x: 10, y: 20, z:30}}});
    assert(ast.location).isOfType(Omega.Location);
    assert(ast.location.x).equals(10);
    assert(ast.location.y).equals(20);
    assert(ast.location.z).equals(30);
  });

  describe("#toJSON", function(){
    it("returns asteroid json data", function(){
      var ast  = {id        : 'ast1',
                  name      : 'ast1n',
                  location  : new Omega.Location({id : 'ast1l'}),
                  parent_id : 'system1',
                  color     : '0A0A0A',
                  size      : 100}
      var oast = new Omega.Asteroid(ast);
      var json = oast.toJSON();

      ast.json_class = oast.json_class;
      ast.location = ast.location.toJSON();
      assert(json).isSameAs(ast);
    });
  });

  describe("#clicked_in", function(){
    var ast, page;

    before(function(){
      ast = new Omega.Asteroid();
      page = new Omega.Pages.Test({canvas : new Omega.UI.Canvas()});
      sinon.stub(page.canvas, 'follow_entity');
    });

    it("instructs canvas to follow asteroid entity", function(){
      ast.clicked_in(page.canvas);
      sinon.assert.calledWith(page.canvas.follow_entity, ast);
    });
  });
});}); // Omega.Asteroid
