/// TODO split into seperate modules along mixin boundries
pavlov.specify("Omega.UI.Canvas", function(){
describe("Omega.UI.Canvas", function(){
  var canvas;

  before(function(){
    canvas = new Omega.UI.Canvas();
  })

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
    after(function(){
      Omega.Test.clear_events();
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
      var canvas = new Omega.UI.Canvas();
      var spy = sinon.spy(canvas.controls, 'wire_up');
      canvas.wire_up();
      sinon.assert.called(spy);
    });

    it("wires up entity container", function(){
      var canvas = new Omega.UI.Canvas();
      var spy = sinon.spy(canvas.entity_container, 'wire_up');
      canvas.wire_up();
      sinon.assert.called(spy);
    });
  });

  //describe("canvas clicked", function(){
  //  it("invokes _canvas_clicked"); // NIY
  //});

  //describe("mouse leaves canvas area", function(){
  //  it("triggers mouse up event"); // NIY
  //});

  //describe("mouse moves in canvas area", function(){
  //  it("updates mouse coordinates"); // NIY
  //});

  // NIY
  //describe("canvas clicked", function(){
  //  describe("click does not intersect omega entity", function(){
  //    it("does nothing")
  //  })

  //  describe("left click", function(){
  //    it("invokes _clicked_entity w/ clicked entity");
  //  })

  //  describe("right click", function(){
  //    it("invokes _rclicked_entity w/ clicked entity")
  //  });
  //});

  //describe("#detect hover", function(){
  //  describe("mouse coordinates do not intersect omega entity", function(){
  //    describe("previously hovering over entity", function(){
  //      it("invokes _unhovered_over w/ previously hovered entity")
  //      it("sets hover num to 0")
  //      it("clears hovered entity")
  //    });

  //    describe("not previously hovering over entity", function(){
  //      it("does nothing");
  //    });
  //  });

  //  describe("mouse coordinates intersect omega entity", function(){
  //    it("sets hovered entity")
  //    describe("hovering over a new entity", function(){
  //      it("sets hover num to 1")
  //    });
  //    describe("still hovering over same entity", function(){
  //      it("increments hover num")
  //    });

  //    it("invokes _hovered_over with entity")
  //  });
  //});

  describe("#_clicked_entity", function(){
    var entity;

    before(function(){
      entity = Omega.Gen.ship();
      canvas = Omega.Test.Canvas();
      sinon.stub(canvas.entity_container, 'show');
    });

    after(function(){
      canvas.entity_container.show.restore();
    });

    describe("entity has details", function(){
      it("shows entity container", function(){
        canvas._clicked_entity(entity);
        sinon.assert.calledWith(canvas.entity_container.show, entity);
      });
    });

    it("invokes entity clicked_in callback", function(){
      sinon.stub(entity, 'clicked_in');
      canvas._clicked_entity(entity);
      sinon.assert.calledWith(entity.clicked_in, canvas);
    });

    it("dispatches 'click' event to entity", function(){
      var cb = sinon.spy();
      entity.addEventListener('click', cb);
      canvas._clicked_entity(entity);
      sinon.assert.called(cb);
    });
  });

  describe("#_rclicked_entity", function(){
    var orig_entity, entity, canvas;

    before(function(){
      entity = Omega.Gen.ship();
      canvas = Omega.Test.Canvas();

      orig_entity = canvas.entity_container.entity;
      canvas.entity_container.entity = entity;
    });

    after(function(){
      canvas.entity_container.entity = orig_entity;
    });

    it("invokes selected context_action callback", function(){
      sinon.stub(entity, 'context_action');
      canvas._rclicked_entity(entity);
      sinon.assert.calledWith(entity.context_action, entity, canvas.page);
    })

    it("dispatch rclick event to entity", function(){
      var cb = sinon.spy();
      entity.addEventListener('rclick', cb);
      canvas._rclicked_entity(entity);
      sinon.assert.called(cb);
    });
  });

  describe("#_hovered_over", function(){
    var entity, canvas;

    before(function(){
      entity = Omega.Gen.solar_system();
      canvas = Omega.Test.Canvas();
    });

    it("invokes entity.on_hover callback", function(){
      sinon.stub(entity, 'on_hover');
      canvas._hovered_over(entity, 2);
      sinon.assert.calledWith(entity.on_hover, canvas, 2);
    });

    it("dispatches hover event to entity", function(){
      var cb = sinon.spy();
      sinon.stub(entity, 'on_hover'); /// stub out on_hover
      entity.addEventListener('hover', cb);
      canvas._hovered_over(entity, 2);
      sinon.assert.called(cb);
    });
  });

  describe("#_unhovered_over", function(){
    var entity, canvas;

    before(function(){
      entity = Omega.Gen.solar_system();
      canvas = Omega.Test.Canvas();
    });

    it("invokes entity.on_unhover callback", function(){
      sinon.stub(entity, 'on_unhover');
      canvas._unhovered_over(entity);
      sinon.assert.calledWith(entity.on_unhover, canvas);
    });

    it("dispatches unhover event to entity", function(){
      var cb = sinon.spy();
      sinon.stub(entity, 'on_unhover'); /// stub out on_hover
      entity.addEventListener('unhover', cb);
      canvas._unhovered_over(entity);
      sinon.assert.called(cb);
    });
  });

  /// TODO update
  describe("canvas after #setup", function(){
    after(function(){
      if(Omega.Test.Canvas().reset_cam.restore)
        Omega.Test.Canvas().reset_cam.restore();
    });

    it("has a scene", function(){
      var canvas = Omega.Test.Canvas();
      assert(canvas.scene).isOfType(THREE.Scene);
    });

    it("has a renderer", function(){
      var canvas = Omega.Test.Canvas();
      assert(canvas.renderer).isOfType(THREE.WebGLRenderer);
    });

    it("has a perspective camera", function(){
      var canvas = Omega.Test.Canvas();
      assert(canvas.cam).isOfType(THREE.PerspectiveCamera);
    });

    it("has orbit controls", function(){
      var canvas = Omega.Test.Canvas();
      assert(canvas.cam_controls).isOfType(THREE.OrbitControls);
    });

    it("sets camera controls dom element to renderer dom element", function(){
      var canvas = Omega.Test.Canvas();
      assert(canvas.cam_controls.domElement).equals(canvas.renderer.domElement);
    });

    it("resets cam", function(){
      var canvas = Omega.Test.Canvas();
      sinon.spy(canvas, 'reset_cam');
      canvas.setup();
      sinon.assert.called(canvas.reset_cam);
    });

    it("sets camera controls target", function(){
      var canvas = Omega.Test.Canvas();
      assert(canvas.cam_controls.target.x).equals(0);
      assert(canvas.cam_controls.target.y).equals(0);
      assert(canvas.cam_controls.target.z).equals(0);
    });

    // it("resizes renderer & camera on window resize"); // NIY

    it("initializes skybox graphics", function(){
      var canvas = Omega.Test.Canvas();
      assert(canvas.skybox.mesh).isNotNull();
    });

    it("initializes axis graphics", function(){
      var canvas = Omega.Test.Canvas();
      assert(canvas.axis.mesh).isNotNull();
    });
  });

  describe("#descendants", function(){
    var canvas;

    before(function(){
      canvas = Omega.Test.Canvas();
    });

    it("returns descendants in all scenes", function(){
      var mesh1 = new THREE.Mesh();
      var mesh2 = new THREE.Mesh();
      canvas.scene.add(mesh1);
      canvas.skyScene.add(mesh2);
      assert(canvas.descendants()).isSameAs([mesh1, mesh2]);
    });
  });

  describe("#animate", function(){
    var canvas;

    before(function(){
      canvas = Omega.Test.Canvas();
      sinon.stub(canvas, '_detect_hover');
    });

    after(function(){
      canvas._detect_hover.restore();
    });

    ///it("requests an animation frame"); /// NIY
    ///it("renderes the scene"); /// NIY

    it("invokes mouse hover detection/update mechanism", function(){
      canvas.animate();
      sinon.assert.called(canvas._detect_hover);
    });
  });

  describe("#render", function(){
    var canvas;

    before(function(){
      canvas = Omega.Test.Canvas();
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
    });

    it("clears renderer", function(){
      canvas.render();
      sinon.assert.called(canvas.renderer.clear);
    });

    //it("sets sky scene camera rotation from scene camera rotation"); // NIY

    it("invokes 'rendered_in' callbacks in scene children omega objects", function(){
      var entity = new Omega.UI.CanvasProgressBar();
      sinon.stub(entity, 'rendered_in');

      canvas.scene.getDescendants()[0].omega_obj = entity;
      canvas.render();
      sinon.assert.calledWith(entity.rendered_in, canvas,
                              canvas.scene.getDescendants()[0]);
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

  describe("#reset_cam", function(){
    var canvas, controls;

    before(function(){
      canvas = Omega.Test.Canvas();
      controls = canvas.cam_controls;
    });

    after(function(){
      if(controls.update.restore) controls.update.restore();
    });

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
      var canvas = Omega.Test.Canvas();
      controls.target.set(100,100,100);
      canvas.reset_cam();
      assert(controls.target.x).close(0, 0.01);
      assert(controls.target.y).close(0, 0.01);
      assert(controls.target.z).close(0, 0.01);
    });

    it("updates camera controls", function(){
      var update = sinon.spy(controls, 'update');
      var canvas = Omega.Test.Canvas();
      canvas.reset_cam();
      sinon.assert.called(update);
    });

    it("hides entity container", function(){
      sinon.spy(canvas.entity_container, 'hide');
      canvas.reset_cam();
      sinon.assert.called(canvas.entity_container.hide);
    });
  });

  describe("#set_scene_root", function(){
    var canvas;
    before(function(){
      canvas = Omega.Test.Canvas();
    });

    after(function(){
      if(canvas.clear.restore) canvas.clear.restore();
      if(canvas.add.restore) canvas.add.restore();
      canvas.clear();
    })

    it("clears the scene", function(){
      var clear = sinon.spy(canvas, 'clear');
      var system = new Omega.SolarSystem({});
      canvas.set_scene_root(system);
      sinon.assert.called(clear);
    });

    it("resets the cam", function(){
      var system = new Omega.SolarSystem({});
      sinon.spy(canvas, 'reset_cam');
      canvas.set_scene_root(system);
      sinon.assert.called(canvas.reset_cam);
    });
    
    it("sets root entity", function(){
      var system = new Omega.SolarSystem({});
      canvas.set_scene_root(system);
      assert(canvas.root).equals(system);
    });

    it("adds children of root to scene", function(){
      var star   = new Omega.Star({id : 1, location : new Omega.Location()});
      var planet = new Omega.Planet({id : 2, location : new Omega.Location()});
      var system = new Omega.SolarSystem({children : [star, planet], location : new Omega.Location()});

      var spy = sinon.stub(canvas, 'add');
      canvas.set_scene_root(system);
      sinon.assert.calledWith(spy, sinon.match.instanceOf(Omega.Star));
      sinon.assert.calledWith(spy, sinon.match.instanceOf(Omega.Planet));
      assert(spy.getCall(0).args[0].id).equals(1);
      assert(spy.getCall(1).args[0].id).equals(2);
    });

    it("animates the scene", function(){
      var system = new Omega.SolarSystem({});
      sinon.spy(canvas, 'animate');
      canvas.set_scene_root(system);
      sinon.assert.called(canvas.animate);
    });

    it("raises set_scene_root event", function(){
      var old_system = new Omega.SolarSystem({});
      var system = new Omega.SolarSystem({});
      canvas.set_scene_root(old_system);

      var listener_cb = sinon.spy();
      canvas.addEventListener('set_scene_root', listener_cb)

      canvas.set_scene_root(system);
      sinon.assert.called(listener_cb);

      var event_data = listener_cb.getCall(0).args[0].data;
      assert(event_data.root).equals(system);
      assert(event_data.old_root).equals(old_system);
    });
  });

  describe("is_root", function(){
    var canvas, system;

    before(function(){
      canvas = Omega.Test.Canvas();
      system = new Omega.SolarSystem({id : 42});
      canvas.set_scene_root(system);
    });

    after(function(){
      Omega.Test.Canvas().clear();
    })

    describe("root entity has specified entity id", function(){
      it("returns true", function(){
        assert(canvas.is_root(42)).isTrue();
      });
    });
    describe("root entity does not have specified entity id", function(){
      it("returns false", function(){
        assert(canvas.is_root(43)).isFalse();
      });
    });
  });

  describe("#focus_on", function(){
    after(function(){
      if(Omega.Test.Canvas().cam_controls.update.restore)
        Omega.Test.Canvas().cam_controls.update.restore();
    });

    it("sets camera controls target", function(){
      var canvas = Omega.Test.Canvas();
      canvas.focus_on({x:100,y:-100,z:2100});
      assert(canvas.cam_controls.target.x).equals(100);
      assert(canvas.cam_controls.target.y).equals(-100);
      assert(canvas.cam_controls.target.z).equals(2100);
    });

    it("updates camera controls", function(){
      var canvas = Omega.Test.Canvas();
      var spy = sinon.spy(canvas.cam_controls, 'update');
      canvas.focus_on({x:100,y:-100,z:2100});
      sinon.assert.called(spy);
    })
  });

  describe("#add", function(){
    var canvas;

    before(function(){
      canvas = Omega.Test.Canvas();
      canvas.page.effects_player = new Omega.UI.EffectsPlayer();
    });

    after(function(){
      Omega.Test.Canvas().clear();
      Omega.Test.Page().effects_player.clear();
      if(canvas.reload.restore) canvas.reload.restore();
    });

    it("initializes entity graphics", function(){
      var star   = new Omega.Star({});
      var spy    = sinon.spy(star, 'init_gfx')
      canvas.add(star);
      sinon.assert.calledWith(spy, sinon.match.func);
      // TODO verify callback animates scene
    });

    it("adds entity components to scene", function(){
      var mesh   = new THREE.Mesh();
      var star   = new Omega.Star({components: [mesh]});
      sinon.stub(star, 'init_gfx'); /// stub out init_gfx
      canvas.add(star);
      assert(canvas.scene.getDescendants()).includes(mesh);
    });

    it("adds entity components to specified scene", function(){
      var scene  = new THREE.Scene();
      var mesh   = new THREE.Mesh();
      var star   = new Omega.Star({components: [mesh]});
      sinon.stub(star, 'init_gfx'); /// stub out init_gfx
      canvas.add(star, scene);
      assert(scene.getDescendants()).includes(mesh);
    });

    it("adds entity to effects player", function(){
      var planet   = Omega.Gen.planet();
      canvas.add(planet);
      assert(canvas.page.effects_player.has(planet.id)).isTrue();
    });

    it("adds entity id to local entities registry", function(){
      var star   = new Omega.Star({id : 42});
      assert(canvas.entities).doesNotInclude(42);
      canvas.add(star);
      assert(canvas.entities).includes(42);
    });
  });

  describe("#remove", function(){
    var canvas;

    before(function(){
      canvas = Omega.Test.Canvas();
      canvas.page.effects_player = new Omega.UI.EffectsPlayer();
    });

    after(function(){
      Omega.Test.Canvas().clear
    });

    it("removes entity components from scene", function(){
      var mesh   = new THREE.Mesh();
      var star   = new Omega.Star({components: [mesh]});
      canvas.add(star);
      canvas.remove(star);
      assert(canvas.scene.getDescendants()).doesNotInclude(mesh);
    });

    it("removes entity components from specified scene", function(){
      var scene  = new THREE.Scene();
      var mesh   = new THREE.Mesh();
      var star   = new Omega.Star({components: [mesh]});
      canvas.add(star, scene);
      canvas.remove(star, scene);
      assert(scene.getDescendants()).doesNotInclude(mesh);
    });

    it("removes entity from effects player", function(){
      var star   = new Omega.Star({});
      canvas.add(star);
      canvas.remove(star);
      assert(canvas.page.effects_player.has(star.id)).isFalse();
    });

    it("removes entity id from local entities registry", function(){
      var star   = new Omega.Star({id : 42});
      canvas.add(star);
      assert(canvas.entities).includes(42);
      canvas.remove(star);
      assert(canvas.entities).doesNotInclude(42);
    });
  });

  describe("#reload", function(){
    var jg, canvas;

    before(function(){
      jg = Omega.Test.Canvas.Entities().jump_gate;
      canvas = Omega.Test.Canvas();
      canvas.add(jg);
    });

    after(function(){
      if(canvas.remove.restore) canvas.remove.restore();
      if(canvas.add.restore) canvas.add.restore();
      Omega.Test.Canvas().clear();
    });

    it("removes entity from canvas", function(){
      var remove = sinon.spy(canvas, 'remove');
      canvas.reload(jg);
      sinon.assert.calledWith(remove, jg);
    });

    it("removes entity from specified canvas scene", function(){
      var scene = new THREE.Scene();
      sinon.spy(canvas, 'remove');
      canvas.reload(jg, scene);
      sinon.assert.calledWith(canvas.remove, jg, scene);
    });

    it("invokes callback with entity", function(){
      var cb = sinon.spy();
      canvas.reload(jg, cb);
      sinon.assert.calledWith(cb, jg);
    });

    it("adds entity to canvas", function(){
      var add = sinon.spy(canvas, 'add');
      canvas.reload(jg);
      sinon.assert.calledWith(add, jg);
    });

    it("adds entity to specified canvas scene", function(){
      var scene = new THREE.Scene();
      var add = sinon.spy(canvas, 'add');
      canvas.reload(jg, scene);
      sinon.assert.calledWith(add, jg, scene);
    });

/// FIXME:
    //describe("entity was not in scene", function(){
    //  it("does not reload entity", function(){
    //    var add = sinon.spy(canvas, 'add');
    //    star = Omega.Test.Canvas.Entities().star;
    //    canvas.reload(star);
    //    sinon.assert.notCalled(add);
    //  })
    //});
  });

  describe("#clear", function(){
    it("clears root entity", function(){
      var system = new Omega.SolarSystem({});
      var canvas = Omega.Test.Canvas();
      canvas.set_scene_root(system);
      canvas.clear();
      assert(canvas.root).isNull();
    });

    it("clears entities list", function(){
      var canvas = Omega.Test.Canvas();
      canvas.entities = [42];
      canvas.clear();
      assert(canvas.entities).isSameAs([]);
    });

    it("clears all components from scene", function(){
      var mesh1  = new THREE.Mesh();
      var mesh2  = new THREE.Mesh();
      var star   = new Omega.Star({components : [mesh1]});

      var canvas = Omega.Test.Canvas();
      canvas.add(star);
      canvas.clear();
      assert(canvas.scene.getDescendants()).doesNotInclude(mesh1);
    });
  });

  describe("#has", function(){
    var canvas;

    before(function(){
      canvas = Omega.Test.Canvas();
      canvas.entities = [42];
    });

    after(function(){
      canvas.clear();
    });

    describe("scene has specified entity id", function(){
      it("returns true", function(){
        assert(canvas.has(42)).isTrue();
      });
    });

    describe("scene does not have specified entity id", function(){
      it("returns false", function(){
        assert(canvas.has(44)).isFalse();
      });
    });
  });
});});
