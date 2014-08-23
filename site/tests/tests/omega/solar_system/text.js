pavlov.specify("Omega.SolarSystemText", function(){
describe("Omega.SolarSystemText", function(){
  it("has a THREE.Mesh instance", function(){
    var system_text = new Omega.SolarSystemText("system1");
    assert(system_text.text).isOfType(THREE.Mesh);
    assert(system_text.text.geometry).isOfType(THREE.TextGeometry);
    assert(system_text.text.material).isOfType(THREE.MeshBasicMaterial);
  });

  describe("#rendered_in", function(){
    it("updates text to always face cam", function(){
      var canvas = new Omega.UI.Canvas();
      var system_text = new Omega.SolarSystemText("system1");
      sinon.stub(system_text.text, 'lookAt');
      system_text.rendered_in(canvas, system_text.text);
      sinon.assert.calledWith(system_text.text.lookAt,
                              canvas.cam.position);
    });
  });
});});
