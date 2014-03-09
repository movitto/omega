pavlov.specify("Omega.ShipHighlightEffects", function(){
describe("Omega.ShipHighlightEffects", function(){
  it("has a THREE.Mesh instance", function(){
    var tmesh = new THREE.Mesh();
    var highlight = new Omega.ShipHighlightEffects({mesh : tmesh});
    assert(highlight.mesh).equals(tmesh);
  });

  describe("#update", function(){
    var loc, highlight;

    before(function(){
      loc = new Omega.Location({x : 200, y : -200, z: 50,
                                orientation_x : 0,
                                orientation_y : 0,
                                orientation_z : 1});

      var tmesh = new THREE.Mesh();
      highlight = new Omega.ShipHighlightEffects({mesh : tmesh});
      highlight.omega_entity = {location : loc};
    });


    it("sets highlight postion", function(){
      var props = Omega.ShipHighlightEffects.prototype.highlight_props;
      highlight.update();
      assert(highlight.mesh.position.x).equals(loc.x + props.x);
      assert(highlight.mesh.position.y).equals(loc.y + props.y);
      assert(highlight.mesh.position.z).equals(loc.z + props.z);
    });
  });
});}); // Omega.ShipHighlightEffects

