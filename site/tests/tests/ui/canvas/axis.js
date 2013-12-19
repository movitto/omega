pavlov.specify("Omega.UI.CanvasAxis", function(){
describe("Omega.UI.CanvasAxis", function(){
  var orig;

  before(function(){
    orig = Omega.UI.CanvasAxis.gfx;
  });

  after(function(){
    Omega.UI.CanvasAxis.gfx = orig;
  });

  it("has the id: canvas_axis", function(){
    var axis = new Omega.UI.CanvasAxis();
    assert(axis.id).equals('canvas_axis');
  });

  describe("#load_gfx", function(){
    describe("graphics are initialized", function(){
      it("does nothing / just returns", function(){
        Omega.UI.CanvasAxis.gfx = {};
        new Omega.UI.CanvasAxis().load_gfx();
        assert(Omega.UI.CanvasAxis.gfx.xy).isUndefined();
      });
    });

    it("creates axis lines", function(){
      var canvas = Omega.Test.Canvas();
      assert(Omega.UI.CanvasAxis.gfx.xy).isOfType(THREE.Line);
      assert(Omega.UI.CanvasAxis.gfx.xz).isOfType(THREE.Line);
      assert(Omega.UI.CanvasAxis.gfx.yz).isOfType(THREE.Line);
    });

    it("creates distance markers", function(){
      var canvas = Omega.Test.Canvas();
      assert(Omega.UI.CanvasAxis.gfx.distances1).isOfType(THREE.Mesh);
      assert(Omega.UI.CanvasAxis.gfx.distances2).isOfType(THREE.Mesh);
      assert(Omega.UI.CanvasAxis.gfx.distances3).isOfType(THREE.Mesh);
    });
  });

  describe("#init_gfx", function(){
    it("loads axis gfx", function(){
      var axis     = new Omega.UI.CanvasAxis();
      var load_gfx = sinon.spy(axis, 'load_gfx');
      axis.init_gfx();
      sinon.assert.called(load_gfx);
    });

    it("adds Axis lines to scene components", function(){
      var axis     = new Omega.UI.CanvasAxis();
      axis.init_gfx();
      assert(axis.components[0]).equals(Omega.UI.CanvasAxis.gfx.xy);
      assert(axis.components[1]).equals(Omega.UI.CanvasAxis.gfx.yz);
      assert(axis.components[2]).equals(Omega.UI.CanvasAxis.gfx.xz);
    });
  });
});}); // Omega.UI.CanvasAxis
