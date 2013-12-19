pavlov.specify("Omega.UI.CanvasControls", function(){
describe("Omega.UI.CanvasControls", function(){
  var node, page, canvas, controls;
  
  before(function(){
    node = new Omega.Node();
    page = new Omega.Pages.Test({node: node});
    canvas = new Omega.UI.Canvas({page: page});
    controls = new Omega.UI.CanvasControls({canvas: canvas});
  });

  it('has a locations list', function(){
    assert(controls.locations_list).isOfType(Omega.UI.CanvasControlsList);
    assert(controls.locations_list.div_id).equals('#locations_list');
  });

  it('has an entities list', function(){
    assert(controls.entities_list).isOfType(Omega.UI.CanvasControlsList);
    assert(controls.entities_list.div_id).equals('#entities_list');
  });

  it('has a missions button', function(){
    assert(controls.missions_button.selector).equals('#missions_button');
  });

  it('has a cam reset button', function(){
    assert(controls.cam_reset.selector).equals('#cam_reset');
  });

  it('has a reference to canvas the controls control', function(){
    assert(controls.canvas).equals(canvas);
  });

  describe("#wire_up", function(){
    after(function(){
      Omega.Test.clear_events();
    });

    it("registers locations list event handlers", function(){
      var controls = new Omega.UI.CanvasControls();
      controls.locations_list.add({id: 'id1', text: 'item1', data: null});
      assert(controls.locations_list.component()).doesNotHandle('click');
      controls.wire_up();
      assert(controls.locations_list.component()).handles('click');
    });

    it("registers entities list event handlers", function(){
      var controls = new Omega.UI.CanvasControls();
      controls.entities_list.add({id: 'id1', text: 'item1', data: null});
      assert(controls.entities_list.component()).doesNotHandle('click');
      controls.wire_up();
      assert(controls.entities_list.component()).handles('click');
    });

    it("registers missions button event handlers", function(){
      var controls = new Omega.UI.CanvasControls();
      assert(controls.missions_button).doesNotHandle('click');
      controls.wire_up();
      assert(controls.missions_button).handles('click');
    });

    it("registers canvas reset button event handler", function(){
      var controls = new Omega.UI.CanvasControls();
      assert(controls.cam_reset).doesNotHandle('click');
      controls.wire_up();
      assert(controls.cam_reset).handles('click');
    });

    it("registers toggle axis click event handlers", function(){
      var controls = new Omega.UI.CanvasControls();
      assert(controls.toggle_axis).doesNotHandle('click');
      controls.wire_up();
      assert(controls.toggle_axis).handles('click');
    });

    it("unchecks toggle axis control", function(){
      var controls = new Omega.UI.CanvasControls();
      controls.toggle_axis.attr('checked', true);
      controls.wire_up();
      assert(controls.toggle_axis.is('checked')).equals(false);
    });

    it("wires up locations list", function(){
      var controls = new Omega.UI.CanvasControls();
      var spy = sinon.spy(controls.locations_list, 'wire_up');
      controls.wire_up();
      sinon.assert.called(spy);
    });

    it("wires up entities list", function(){
      var controls = new Omega.UI.CanvasControls();
      var spy = sinon.spy(controls.entities_list, 'wire_up');
      controls.wire_up();
      sinon.assert.called(spy);
    });
  });

  describe("missions button click", function(){
    before(function(){
      controls.wire_up();
    });

    after(function(){
      if(Omega.Mission.all.restore) Omega.Mission.all.restore();
      Omega.Test.clear_events();
    });

    it("retrieves all missions", function(){
      var spy = sinon.spy(Omega.Mission, 'all');
      controls.missions_button.click();
      sinon.assert.calledWith(spy, node, sinon.match.func)
    });

    it("shows missions dialog", function(){
      var spy1 = sinon.spy(Omega.Mission, 'all');
      var spy2 = sinon.spy(canvas.dialog, 'show_missions_dialog');
      controls.missions_button.click();

      var response = {};
      spy1.getCall(0).args[1](response)
      sinon.assert.calledWith(spy2, response);
    });
  });
  
  describe("#canvas_reset button clicked", function(){
    before(function(){
      canvas = Omega.Test.Canvas();
      controls = new Omega.UI.CanvasControls({canvas: canvas});
      controls.wire_up();
    });

    after(function(){
      Omega.Test.clear_events();
      if(canvas.reset_cam.restore) canvas.reset_cam.restore();
    });

    it("invokes canvas.reset_cam()", function(){
      var reset_cam = sinon.spy(canvas, 'reset_cam');
      controls.cam_reset.click();
      sinon.assert.called(reset_cam);
    });
  })

  describe("#toggle_axis input clicked", function(){
    before(function(){
      canvas = Omega.Test.Canvas();
      controls = new Omega.UI.CanvasControls({canvas: canvas});
      controls.wire_up();
    });

    after(function(){
      Omega.Test.clear_events();
    });

    describe("input is checked", function(){
      it("adds axis to canvas scene", function(){
        controls.toggle_axis.attr('checked', false);
        controls.toggle_axis.click();
        assert(canvas.scene.getDescendants()).includes(canvas.axis.components[0]);
        assert(canvas.scene.getDescendants()).includes(canvas.axis.components[1]);
        assert(canvas.scene.getDescendants()).includes(canvas.axis.components[2]);
      });
    });

    describe("input is not checked", function(){
      it("removes axis from canvas scene", function(){
        controls.toggle_axis.attr('checked', true);
        controls.toggle_axis.click();
        assert(canvas.scene.getDescendants()).doesNotInclude(canvas.axis.xy);
        assert(canvas.scene.getDescendants()).doesNotInclude(canvas.axis.xz);
        assert(canvas.scene.getDescendants()).doesNotInclude(canvas.axis.yz);
      });
    });

    // it("animates scene") // NIY
  });

  describe("#locations_list item click", function(){
    var system, render_stub;

    before(function(){
      system = new Omega.SolarSystem({id: 'system1'});
      controls.locations_list.add({id: system.id,
                                   text: system.id,
                                   data: system});
      controls.wire_up();

      // stub out call to render, see comment in
      // #entities_list item click before block below
      render_stub = sinon.stub(canvas, 'render');
    });

    after(function(){
      Omega.Test.clear_events();
    });

    it("sets canvas scene root", function(){
      var spy = sinon.spy(canvas, 'set_scene_root');
      $(controls.locations_list.children()[0]).click();
      sinon.assert.calledWith(spy, system);
    });
  });

  describe("#entities_list item click", function(){
    var system, ship, focus_stub, render_stub;

    before(function(){
      system = new Omega.SolarSystem({id: 'system1'});
      ship   = new Omega.Ship({id: 'ship1',
                               solar_system: system,
                               location: new Omega.Location()});
      controls.locations_list.add({id: system.id,
                                   text: system.id,
                                   data: system});
      controls.entities_list.add({id:   ship.id,
                                  text: ship.id,
                                  data: ship});
      controls.wire_up();

      /// since we're using canvas initialized in 'before'
      /// block above and not central Omega.Test.Canvas w/
      /// three.js components, we'll stub out the actual
      /// focus_on and render calls
      focus_stub = sinon.stub(canvas, 'focus_on')
      render_stub = sinon.stub(canvas, 'render')
    });

    after(function(){
      Omega.Test.clear_events();
    });

    it("sets canvas scene root", function(){
      var spy = sinon.spy(canvas, 'set_scene_root');
      $(controls.entities_list.children()[0]).click();
      sinon.assert.calledWith(spy, ship.solar_system);
    });

    it("focuses canvas scene camera on clicked entity's location", function(){
      $(controls.entities_list.children()[0]).click();
      sinon.assert.calledWith(focus_stub, ship.location);
    });

    it("invokes canvas._clicked_entity with entity", function(){
      var clicked = sinon.spy(canvas, '_clicked_entity');
      $(controls.entities_list.children()[0]).click();
      sinon.assert.calledWith(clicked, ship);
    });
  });
});});

