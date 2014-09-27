pavlov.specify("Omega.UI.Canvas", function(){
describe("Omega.UI.Canvas", function(){
  var canvas;

  before(function(){
    canvas = Omega.Test.canvas();
  });

  it("has a scene", function(){
    assert(canvas.scene).isOfType(THREE.Scene);
  });

  it("has a renderer", function(){
    assert(canvas.renderer).isOfType(THREE.WebGLRenderer);
  });

  it("has a perspective camera", function(){
    assert(canvas.cam).isOfType(THREE.PerspectiveCamera);
  });

  it("has orbit controls", function(){
    assert(canvas.cam_controls).isOfType(THREE.OrbitControls);
  });

  it("sets camera controls dom element to renderer dom element", function(){
    assert(canvas.cam_controls.domElement).equals(canvas.renderer.domElement);
  });

  it("sets camera controls target", function(){
    assert(canvas.cam_controls.target.x).equals(0);
    assert(canvas.cam_controls.target.y).equals(0);
    assert(canvas.cam_controls.target.z).equals(0);
  });

  // it("resizes renderer & camera on window resize"); // NIY

  it("initializes skybox graphics", function(){
    assert(canvas.skybox.mesh).isNotNull();
  });

  it("initializes axis graphics", function(){
    assert(canvas.axis.mesh).isNotNull();
  });

  //describe("#append", function(){ /// NIY
  //})

  describe("#animate", function(){
    var canvas;

    before(function(){
      canvas = new Omega.UI.Canvas();
      sinon.stub(canvas, 'render');
      sinon.stub(canvas, '_detect_hover');
    });

    ///it("requests an animation frame"); /// NIY
    ///it("renderes the scene"); /// NIY

    it("invokes mouse hover detection/update mechanism", function(){
      canvas.animate();
      sinon.assert.called(canvas._detect_hover);
    });
  });

  describe("#render", function(){
    before(function(){
      sinon.stub(canvas.renderer, 'clear');
      sinon.stub(canvas.renderer, 'render');
      sinon.stub(canvas.stats, 'update');
      sinon.stub(canvas.scene, 'getDescendants').returns([new THREE.Mesh()]);
    });

    after(function(){
      canvas.renderer.clear.restore();
      canvas.renderer.render.restore();
      canvas.stats.update.restore();
      canvas.scene.getDescendants.restore();
      canvas.clear();
    });

    it("clears renderer", function(){
      canvas.render();
      sinon.assert.called(canvas.renderer.clear);
    });

    //it("sets sky scene camera rotation from scene camera rotation"); // NIY

    it("invokes 'rendered_in' callbacks in scene children omega objects", function(){
      var entity    = {rendered_in : sinon.spy()};
      var component = {omega_obj : entity};

      canvas.rendered_in = [component];
      canvas.render();
      sinon.assert.calledWith(entity.rendered_in, canvas, component);
    });

    it("renders sky scene", function(){
      canvas.render();
      sinon.assert.calledWith(canvas.renderer.render, canvas.skyScene, canvas.skyCam);
    });

    it("renders regular scene", function(){
      canvas.render();
      sinon.assert.calledWith(canvas.renderer.render, canvas.scene, canvas.cam);
    });

    it("updates stats", function(){
      canvas.render();
      sinon.assert.called(canvas.stats.update);
    });
  });
});});
