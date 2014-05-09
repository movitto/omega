pavlov.specify("Omega.UI.CanvasControls", function(){
describe("Omega.UI.CanvasControls", function(){
  var node, page, canvas, controls;
  
  before(function(){
    node     = new Omega.Node();
    page     = new Omega.Pages.Test({node: node});
    canvas   = new Omega.UI.Canvas({page: page});
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
      sinon.spy(controls.locations_list, 'wire_up');
      controls.wire_up();
      sinon.assert.called(controls.locations_list.wire_up);
    });

    it("wires up entities list", function(){
      var controls = new Omega.UI.CanvasControls();
      sinon.spy(controls.entities_list, 'wire_up');
      controls.wire_up();
      sinon.assert.called(controls.entities_list.wire_up);
    });
  });

  describe("missions button click", function(){
    before(function(){
      controls.wire_up();
    });

    after(function(){
      if(Omega.Mission.all.restore)
        Omega.Mission.all.restore();

      Omega.Test.clear_events();
    });

    it("retrieves all missions", function(){
      sinon.spy(Omega.Mission, 'all');
      controls.missions_button.click();
      sinon.assert.calledWith(Omega.Mission.all, node, sinon.match.func);
    });

    it("shows missions dialog", function(){
      sinon.spy(Omega.Mission, 'all');
      sinon.spy(canvas.dialog, 'show_missions_dialog');
      controls.missions_button.click();

      var response = {};
      Omega.Mission.all.omega_callback()(response)
      sinon.assert.calledWith(canvas.dialog.show_missions_dialog, response);
    });
  });
  
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

    it("refreshes clicked item", function(){
      sinon.stub(system, 'refresh');
      $(controls.locations_list.children()[0]).click();
      sinon.assert.calledWith(system.refresh, node, sinon.match.func)
    });

    it("sets canvas scene root", function(){
      sinon.stub(system, 'refresh');
      sinon.stub(canvas, 'set_scene_root');
      $(controls.locations_list.children()[0]).click();
      system.refresh.omega_callback()();
      sinon.assert.calledWith(canvas.set_scene_root, system);
    });
  });

  describe("#entities_list item click", function(){
    var system, ship, focus_stub, render_stub;

    before(function(){
      system = new Omega.SolarSystem({id: 'system1'});
      ship   = new Omega.Ship({id: 'ship1',
                               type : 'corvette',
                               solar_system: system,
                               location: new Omega.Location({x:100, y:200, z:-100})});
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
      canvas.cam = {position : new THREE.Vector3()};
    });

    after(function(){
      Omega.Test.clear_events();
    });

    it("refreshes clicked item system", function(){
      sinon.stub(system, 'refresh');
      $(controls.entities_list.children()[0]).click();
      sinon.assert.calledWith(system.refresh, node, sinon.match.func)
    });

    describe("on system refresh", function(){
      var refresh_cb;

      before(function(){
        sinon.stub(system, 'refresh');
        $(controls.entities_list.children()[0]).click();
        refresh_cb = system.refresh.omega_callback();
      });

      it("sets canvas scene root", function(){
        sinon.spy(canvas, 'set_scene_root');
        refresh_cb();
        sinon.assert.calledWith(canvas.set_scene_root, ship.solar_system);
      });

      it("initializes entity gfx", function(){
        sinon.spy(ship, 'init_gfx');
        refresh_cb();
        sinon.assert.called(ship.init_gfx);
      });

      it("invokes canvas._clicked_entity with entity", function(){
        sinon.spy(canvas, '_clicked_entity');
        refresh_cb();
        sinon.assert.calledWith(canvas._clicked_entity, ship);
      });
    });
  });
});});

