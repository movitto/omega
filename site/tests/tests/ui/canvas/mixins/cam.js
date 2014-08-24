pavlov.specify("Omega.UI.Canvas", function(){
describe("Omega.UI.Canvas", function(){
  var canvas;

  before(function(){
    canvas = Omega.Test.canvas();
  });

  describe("#reset_cam", function(){
    var controls;

    before(function(){
      controls = canvas.cam_controls;
      sinon.spy(controls, 'update');
      sinon.spy(canvas.entity_container, 'hide');
    });

    after(function(){
      controls.update.restore();
      canvas.entity_container.hide.restore();
    })

    it("sets camera controls position", function(){
      controls.object.position.set(100,100,100);
      canvas.root = Omega.Gen.solar_system();
      var position = canvas.default_position_for(canvas.root);
      canvas.reset_cam();
      assert(controls.object.position.x).close(position[0], 0.01);
      assert(controls.object.position.y).close(position[1], 0.01);
      assert(controls.object.position.z).close(position[2], 0.01);
    });

    it("sets camera controls target", function(){
      controls.target.set(100,100,100);
      canvas.reset_cam();
      assert(controls.target.x).close(0, 0.01);
      assert(controls.target.y).close(0, 0.01);
      assert(controls.target.z).close(0, 0.01);
    });

    it("updates camera controls", function(){
      canvas.reset_cam();
      sinon.assert.called(controls.update);
    });

    it("hides entity container", function(){
      canvas.reset_cam();
      sinon.assert.called(canvas.entity_container.hide);
    });
  });

  describe("#focus_on", function(){
    before(function(){
      sinon.spy(canvas.cam_controls, 'update');
    });

    after(function(){
      canvas.cam_controls.update.restore();
    });

    it("sets camera controls target", function(){
      canvas.focus_on({x:100,y:-100,z:2100});
      assert(canvas.cam_controls.target.x).equals(100);
      assert(canvas.cam_controls.target.y).equals(-100);
      assert(canvas.cam_controls.target.z).equals(2100);
    });

    it("updates camera controls", function(){
      canvas.focus_on({x:100,y:-100,z:2100});
      sinon.assert.called(canvas.cam_controls.update);
    })
  });
});});
