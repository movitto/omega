pavlov.specify("Omega.UI.Canvas", function(){
describe("Omega.UI.Canvas", function(){
  var canvas;

  before(function(){
    canvas = Omega.Test.canvas();
  });

  after(function(){
    canvas.clear();
  });

  it('has a canvas controls instance', function(){
    assert(canvas.controls).isOfType(Omega.UI.CanvasControls);
  });

  it('has a canvas dialog instance', function(){
    assert(canvas.dialog).isOfType(Omega.UI.CanvasDialog);
  });

  it('has a entity container instance', function(){
    assert(canvas.entity_container).isOfType(Omega.UI.CanvasEntityContainer);
    assert(canvas.entity_container.canvas).equals(canvas);
  });

  it('has a reference to page the canvas is on', function(){
    var page   = new Omega.Pages.Test();
    var canvas = new Omega.UI.Canvas({page: page});
    assert(canvas.page).equals(page);
  });

  describe("#wire_up", function(){
    before(function(){
      sinon.spy(canvas.controls, 'wire_up');
      sinon.spy(canvas.entity_container, 'wire_up');
    });

    after(function(){
      Omega.Test.clear_events();
      canvas.controls.wire_up.restore();
      canvas.entity_container.wire_up.restore();
    });

    it("registers canvas mouseup/mousedown/mouseleave event handlers", function(){
      var canvas = new Omega.UI.Canvas();
      assert($(canvas.canvas.selector)).doesNotHandle('mousedown');
      assert($(canvas.canvas.selector)).doesNotHandle('mouseup');
      assert($(canvas.canvas.selector)).doesNotHandle('mouseout');
      canvas.wire_up();
      assert($(canvas.canvas.selector)).handles('mousedown');
      assert($(canvas.canvas.selector)).handles('mouseup');
      assert($(canvas.canvas.selector)).handles('mouseout');
    });

    it("wires up controls", function(){
      canvas.wire_up();
      sinon.assert.called(canvas.controls.wire_up);
    });

    it("wires up entity container", function(){
      canvas.wire_up();
      sinon.assert.called(canvas.entity_container.wire_up);
    });
  });
});});
