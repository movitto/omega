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

    it("registers canvas click event handler", function(){
      var canvas = new Omega.UI.Canvas();
      assert($(canvas.canvas.selector)).doesNotHandle('click');
      canvas.wire_up();
      assert($(canvas.canvas.selector)).handles('click');
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

//  describe("user clicks canvas", function(){
//    describe("user clicked on entity in scene", function(){
//      it("invokes canvas._clicked_entity");
//    });
//  });
//
//  describe("#_clicked_entity", function(){
//    describe("entity has details", function(){
//      it("shows entity in entity container");
//    });
//
//    it("invokes clicked_in method on entity");
//
//    it("raises click event on entity", async(function(){
//      var mesh1  = new THREE.Mesh(new THREE.SphereGeometry(1000, 100, 100),
//                                  new THREE.MeshBasicMaterial({color: 0xABABAB}));
//      var mesh2  = mesh1.clone();
//      mesh1.position.set(1000, 0, 0);
//      mesh2.position.set(0, 0, 0);
//
//      mesh1.omega_entity = new Omega.Ship({id: 'sh1'});
//      mesh2.omega_entity = new Omega.Ship({id: 'sh2'});
//
//      var spy1 = sinon.spy();
//      var spy2 = sinon.spy();
//      mesh1.omega_entity.addEventListener('click', spy1);
//      mesh2.omega_entity.addEventListener('click', spy2);
//
//      var canvas = Omega.Test.Canvas();
//      canvas.scene.add(mesh1);
//      canvas.scene.add(mesh2);
//
//      var side = canvas.canvas.offset().left - canvas.canvas.width();
//      canvas.canvas.css({right: $(document).width() - side});
//      canvas.canvas.show();
//      canvas.animate();
//on_animation(canvas, function(){
//
//// TODO wait for animation?
//
//    var evnt = new jQuery.Event("click");
//    evnt.pageX = canvas.canvas.offset().left + canvas.canvas.width()/2;
//    evnt.pageY = canvas.canvas.offset().top  + canvas.canvas.height()/2;
//console.log(evnt)
//// TODO incorrect position?
//    canvas.canvas.trigger(evnt);
//    //sinon.assert.calledWith(spy2, {type: 'click'})
//    //sinon.assert.notCalled(spy1);
//    start();
//
//});
//    }));
//  });

  describe("canvas after #setup", function(){
    it("has a scene", function(){
      var canvas = Omega.Test.Canvas();
      assert(canvas.scene).isOfType(THREE.Scene);
    });

    it("has a renderer", function(){
      var canvas = Omega.Test.Canvas();
      assert(canvas.renderer).isOfType(THREE.WebGLRenderer);
      assert(canvas.renderTarget).isOfType(THREE.WebGLRenderTarget);
    });

    it("has two effects composers", function(){
      var canvas = Omega.Test.Canvas();
      assert(canvas.composer).isOfType(THREE.EffectComposer);
      assert(canvas.shader_composer).isOfType(THREE.EffectComposer);
    })

    it("has a perspective camera", function(){
      var canvas = Omega.Test.Canvas();
      assert(canvas.cam).isOfType(THREE.PerspectiveCamera);
    });

    it("has orbit controls", function(){
      var canvas = Omega.Test.Canvas();
      assert(canvas.cam_controls).isOfType(THREE.OrbitControls);
    });

    it("adds render pass to shader composer", function(){
      var canvas = Omega.Test.Canvas();
      assert(canvas.shader_composer.passes.length).equals(1);
      assert(canvas.shader_composer.passes[0]).isOfType(THREE.RenderPass);
    })

    it("adds a render/bloom/shader passes to composer", function(){
      var canvas = Omega.Test.Canvas();
      assert(canvas.composer.passes.length).equals(3);
      assert(canvas.composer.passes[0]).isOfType(THREE.RenderPass);
      assert(canvas.composer.passes[1]).isOfType(THREE.BloomPass);
      assert(canvas.composer.passes[2]).isOfType(THREE.ShaderPass);
      //assert(canvas.composer.passes[2]); // TODO verify ShaderPass pulls in ShaderComposer via AdditiveBlending
      assert(canvas.composer.passes[2].renderToScreen).isTrue();
    });

    it("sets camera controls dom element to renderer dom element", function(){
      var canvas = Omega.Test.Canvas();
      assert(canvas.cam_controls.domElement).equals(canvas.renderer.domElement);
    });

    it("sets camera controls position", function(){
      var canvas = Omega.Test.Canvas();
      assert(canvas.cam_controls.object.position.x).close(Omega.Config.cam.position[0], 0.01);
      assert(canvas.cam_controls.object.position.y).close(Omega.Config.cam.position[1], 0.01);
      assert(canvas.cam_controls.object.position.z).close(Omega.Config.cam.position[2], 0.01);
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
      canvas.reset_cam();
      assert(controls.object.position.x).close(Omega.Config.cam.position[0], 0.01);
      assert(controls.object.position.y).close(Omega.Config.cam.position[1], 0.01);
      assert(controls.object.position.z).close(Omega.Config.cam.position[2], 0.01);
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
    
    it("sets root entity", function(){
      var system = new Omega.SolarSystem({});
      canvas.set_scene_root(system);
      assert(canvas.root).equals(system);
    });

    it("adds children of root to scene", function(){
      var star   = new Omega.Star({id : 1, location : new Omega.Location()});
      var planet = new Omega.Planet({id : 2, location : new Omega.Location()});
      var system = new Omega.SolarSystem({children : [star, planet], location : new Omega.Location()});

      var spy = sinon.spy(canvas, 'add');
      canvas.set_scene_root(system);
      sinon.assert.calledWith(spy, sinon.match.instanceOf(Omega.Star));
      sinon.assert.calledWith(spy, sinon.match.instanceOf(Omega.Planet));
      assert(spy.getCall(0).args[0].id).equals(1);
      assert(spy.getCall(1).args[0].id).equals(2);
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
    after(function(){
      Omega.Test.Canvas().clear();
      if(canvas.reload.restore) canvas.reload.restore();
    });

    it("initializes entity graphics", function(){
      var star   = new Omega.Star({});
      var spy    = sinon.spy(star, 'init_gfx')
      var canvas = Omega.Test.Canvas();
      canvas.add(star);
      sinon.assert.calledWith(spy, canvas.page.config, sinon.match.func);
      // TODO verify callback animates scene
    });

    it("adds entity components to scene", function(){
      var mesh   = new THREE.Mesh();
      var star   = new Omega.Star({components: [mesh]});
      var canvas = Omega.Test.Canvas();
      canvas.add(star);
      assert(canvas.scene.getDescendants()).includes(mesh);
    });

    it("adds entity shader components to shader scene", function(){
      var mesh   = new THREE.Mesh();
      var star   = new Omega.Star({shader_components: [mesh]});
      var canvas = Omega.Test.Canvas();
      canvas.add(star);
      assert(canvas.shader_scene.getDescendants()).includes(mesh);
    });

    it("wires up loaded_mesh event handler", function(){
      var star   = new Omega.Star({});
      var canvas = Omega.Test.Canvas();
      assert(star).doesNotHandleEvent('loaded_mesh');
      canvas.add(star);
      assert(star).handlesEvent('loaded_mesh');
    });

//FIXME:
    //describe("on loaded mesh", function(){
    //  it("reloads entity in scene", function(){
    //    var mesh   = new THREE.Mesh();
    //    var ship   = new Omega.Ship({mesh : mesh, type : 'corvette'});
    //    var canvas = Omega.Test.Canvas();
    //    canvas.add(ship);
    //    var on_loaded = ship._listeners['loaded_mesh'][0];
    //    var reload = sinon.stub(canvas, 'reload');
    //    on_loaded({data : mesh});
    //    sinon.assert.calledWith(reload, ship);
    //  });
    //});

    it("adds entity id to local entities registry", function(){
      var star   = new Omega.Star({id : 42});
      var canvas = Omega.Test.Canvas();
      assert(canvas.entities).doesNotInclude(42);
      canvas.add(star);
      assert(canvas.entities).includes(42);
    });
  });

  describe("#remove", function(){
    after(function(){
      Omega.Test.Canvas().clear
    });

    it("removes entity components from scene", function(){
      var mesh   = new THREE.Mesh();
      var star   = new Omega.Star({components: [mesh]});
      var canvas = Omega.Test.Canvas();
      canvas.add(star);
      canvas.remove(star);
      assert(canvas.scene.getDescendants()).doesNotInclude(mesh);
    });

    it("removes entity shader components from shader scene", function(){
      var mesh   = new THREE.Mesh();
      var star   = new Omega.Star({shader_components: [mesh]});
      var canvas = Omega.Test.Canvas();
      canvas.add(star);
      canvas.remove(star);
      assert(canvas.shader_scene.getDescendants()).doesNotInclude(mesh);
    });

    it("removes loaded_mesh event handler", function(){
      var star   = new Omega.Star({});
      var canvas = Omega.Test.Canvas();
      canvas.add(star);
      assert(star).handlesEvent('loaded_mesh');
      canvas.remove(star);
      assert(star).doesNotHandleEvent('loaded_mesh');
    });

    it("removes entity id from local entities registry", function(){
      var star   = new Omega.Star({id : 42});
      var canvas = Omega.Test.Canvas();
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
    });

    it("removes entity from canvas", function(){
      var remove = sinon.spy(canvas, 'remove');
      canvas.reload(jg);
      sinon.assert.calledWith(remove, jg);
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

    it("clears all components from all scenes", function(){
      var mesh1  = new THREE.Mesh();
      var mesh2  = new THREE.Mesh();
      var star   = new Omega.Star({components        : [mesh1],
                                   shader_components : [mesh2]});
      var canvas = Omega.Test.Canvas();
      canvas.add(star);
      canvas.clear();
      assert(canvas.scene.getDescendants()).doesNotInclude(mesh1);
      assert(canvas.shader_scene.getDescendants()).doesNotInclude(mesh2);
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

pavlov.specify("Omega.UI.CanvasControlsList", function(){
describe("Omega.UI.CanvasControlsList", function(){
  var list;

  before(function(){
    list = new Omega.UI.CanvasControlsList({div_id: '#locations_list'});
    list.wire_up();
  })

  after(function(){
    Omega.Test.clear_events();
  })

  describe("mouse enter event", function(){
    it("shows child ul", function(){
      list.component().mouseenter();
      assert(list.list()).isVisible();
    });
  });

  describe("mouse leave event", function(){
    it("hides child ul", function(){
      list.component().mouseenter();
      list.component().mouseleave();
      assert(list.list()).isHidden();
    });
  });

  describe("#add", function(){
    it("adds new li to list", function(){
      var item = {};
      list.add(item)
      assert(list.list().children('li').length).equals(1);
    });

    it("sets li text to item text", function(){
      var item = {text: 'item1'}
      list.add(item)
      assert($(list.list().children('li')[0]).html()).equals('item1');
    });

    it("sets item id in li data", function(){
      var item = {id: 'item1'}
      list.add(item)
      assert($(list.list().children('li')[0]).data('id')).equals('item1');
    });

    it("sets item in li data", function(){
      var item = {data: {}}
      list.add(item)
      assert($(list.list().children('li')[0]).data('item')).equals(item['data']);
    });
  });
});});

pavlov.specify("Omega.UI.CanvasDialog", function(){
describe("Omega.UI.CanvasDialog", function(){
  var user_id  = 'user1';
  var node     = new Omega.Node();
  var session  = new Omega.Session({user_id: user_id});
  var page     = new Omega.Pages.Test({node: node, session: session});
  var canvas   = new Omega.UI.Canvas({page: page});

  // TODO factory pattern
  var mission1 = new Omega.Mission({title: 'mission1',
                       description: 'mission description1',
                       assigned_to_id : user_id,
                       assigned_time  : new Date().toString() });

  var mission2 = new Omega.Mission({id:    'missionb',
                                    title: 'mission2'});
  var mission3 = new Omega.Mission({id:    'missionc',
                                    title: 'mission3',
                                    assigned_to_id : user_id,
                                    victorious : true});
  var mission4 = new Omega.Mission({id:    'missiond',
                                    title: 'mission4',
                                    assigned_to_id : 'another',
                                    victorious : true});
  var mission5 = new Omega.Mission({id:    'missione',
                                    title: 'mission5',
                                    assigned_to_id : user_id,
                                    failed : true});
  var mission6 = new Omega.Mission({id:    'missionf',
                                    title: 'mission6',
                                    assigned_to_id : user_id,
                                    failed : true});
  var mission7 = new Omega.Mission({id:    'missiong',
                                    title: 'mission7'});

  var inactive_missions   = [mission2, mission3, mission4, mission5, mission6, mission7];
  var unassigned_missions = [mission2, mission7];
  var victorious_missions = [mission3];
  var failed_missions     = [mission5, mission6];
  var missions_responses  =
    {active   : [mission1],
     inactive : inactive_missions};

  before(function(){
    dialog  = new Omega.UI.CanvasDialog({canvas: canvas});
  });

  after(function(){
    Omega.UI.Dialog.remove();
  });

  it('has a reference to canvas the dialog is for', function(){
    var canvas = new Omega.UI.Canvas();
    var dialog = new Omega.UI.CanvasDialog({canvas: canvas});
    assert(dialog.canvas).equals(canvas);
  });

  describe("#show_missions_dialog", function(){
    it("hides dialog", function(){
      var spy = sinon.spy(dialog, 'hide');
      dialog.show_missions_dialog({});
      sinon.assert.called(spy);
    });

    describe("user has active mission", function(){
      it("shows assigned mission dialog", function(){
        var spy = sinon.spy(dialog, 'show_assigned_mission_dialog');
        dialog.show_missions_dialog(missions_responses['active']);
        sinon.assert.calledWith(spy, mission1);
      });

    describe("user does not have active mission", function(){
      it("shows mission list dialog", function(){
        var spy = sinon.spy(dialog, 'show_missions_list_dialog');
        dialog.show_missions_dialog(missions_responses['inactive']);
        sinon.assert.calledWith(spy, unassigned_missions, victorious_missions, failed_missions);
      });
    });

    it("shows dialog", function(){
      var spy = sinon.spy(dialog, 'show');
      dialog.show_missions_dialog({});
      sinon.assert.called(spy);
    });
  });

  describe("#show_assigned_mission_dialog", function(){
      it("shows mission metadata", function(){
        dialog.show_assigned_mission_dialog(mission1);
        assert(dialog.title).equals('Assigned Mission');
        assert(dialog.div_id).equals('#assigned_mission_dialog');
        assert($('#assigned_mission_title').html()).equals('<b>mission1</b>');
        assert($('#assigned_mission_description').html()).equals('mission description1');
        assert($('#assigned_mission_assigned_time').html()).equals('<b>Assigned</b>: ' + mission1.assigned_time);
        assert($('#assigned_mission_expires').html()).equals('<b>Expires</b>: ' + mission1.expires());
      });
    });
  });

  describe("#show_missions_list_dialog", function(){
    it("shows list of unassigned missions with assignment links", function(){
      dialog.show_missions_list_dialog(unassigned_missions, victorious_missions, failed_missions);
      assert(dialog.title).equals('Missions');
      assert(dialog.div_id).equals('#missions_dialog');
      assert($('#missions_list').html()).equals('mission2<span class="assign_mission">assign</span><br>mission7<span class="assign_mission">assign</span><br>'); // XXX unassigned_missions
    });
    
    it("associates mission with assign command event data", function(){
      dialog.show_missions_list_dialog(unassigned_missions, victorious_missions, failed_missions);
      var assign_cmds = $('.assign_mission');
      assert($(assign_cmds[0]).data('mission')).equals(mission2)
      assert($(assign_cmds[1]).data('mission')).equals(mission7)
    })

    it("should # of successful/failed user missions", function(){
      dialog.show_missions_list_dialog(unassigned_missions, victorious_missions, failed_missions);
      assert($('#completed_missions').html()).equals('(Victorious: 1 / Failed: 2)');
    });
  });

  describe("mission assignment command", function(){
    var mission;

    before(function(){
      dialog.show_missions_list_dialog(unassigned_missions, [], []);
      mission = unassigned_missions[0];
    });

    after(function(){
      if(mission.assign_to.restore) mission.assign_to.restore();
      Omega.Test.clear_events();
    })

    it("invokes missions.assign_to", function(){
      var spy = sinon.spy(mission, 'assign_to');
      $('.assign_mission')[0].click();
      sinon.assert.calledWith(spy, session.user_id, dialog.canvas.page.node, sinon.match.func);
    });

    it("invokes assign_mission_clicked", function(){
      var spy = sinon.spy(mission, 'assign_to');
      var element = $('.assign_mission')[0];
      $(element).data('mission', mission);
      element.click();
      assign_cb = spy.getCall(0).args[2];

      var response = {};
      spy = sinon.spy(dialog, '_assign_mission_clicked');
      assign_cb(response)

      sinon.assert.calledWith(spy, response);
    });

    describe("missions::assign response", function(){
      describe("error on mission assignment", function(){
        it("sets error", function(){
          dialog._assign_mission_clicked({error: {message: 'user has active mission'}})
          assert($('#mission_assignment_error').html()).equals('user has active mission');
        });

        it("shows dialog", function(){
          var spy = sinon.spy(dialog, 'show');
          dialog._assign_mission_clicked({error: {}});
          sinon.assert.called(spy);
        });
      });

      it("hides dialog", function(){
        var spy = sinon.spy(dialog, 'hide');
        dialog._assign_mission_clicked({});
        sinon.assert.called(spy);
      });
    });
  });
});});

pavlov.specify("Omega.UI.CanvasEntityContainer", function(){
describe("Omega.UI.CanvasEntityContainer", function(){
  var canvas, container;

  before(function(){
    canvas = Omega.Test.Canvas();
    container = new Omega.UI.CanvasEntityContainer({canvas: canvas});
  });

  after(function(){
    Omega.Test.clear_events();
  });

  it('has a reference to canvas the container is for', function(){
    assert(container.canvas).equals(canvas);
  });

  describe("#wire_up", function(){
    it("registers entity container close click event handler", function(){
      assert($(container.close_id)).doesNotHandle('click');
      container.wire_up();
      assert($(container.close_id)).handles('click');
    });

    it("hides entity container", function(){
      var hide = sinon.spy(container, 'hide');
      $(container.div_id).show();
      assert($(container.div_id)).isVisible();
      container.wire_up();
      assert($(container.div_id)).isHidden();
      sinon.assert.called(hide);
    });
  });

  describe("#close button clicked", function(){
    it("it hides entity container", function(){
      var hide = sinon.spy(container, 'hide');
      container.wire_up();
      $(container.close_id).click();
      sinon.assert.calledWith(hide);
    });
  });

  describe("#hide", function(){
    var ship;
    before(function(){
      ship = new Omega.Ship({location : new Omega.Location()});
      container.show(ship);
    });

    it("unselects entity", function(){
      var unselected = sinon.spy(ship, 'unselected');
      container.hide();
      sinon.assert.calledWith(unselected, canvas.page);
    });

    it("clears local entity", function(){
      container.hide();
      assert(container.entity).isNull();
    });

    it("clears container contents", function(){
      $(container.contents_id).html('foobar');
      container.hide();
      assert($(container.contents_id).html()).equals('');
    });

    it("hides dom element", function(){
      $(container.div_id).show();
      assert($(container.div_id)).isVisible();
      container.hide();
      assert($(container.div_id)).isHidden();
    });
  });

  describe("#show", function(){
    var ship;

    before(function(){
      ship = new Omega.Ship({location : new Omega.Location()});
    });

    it("hides entity container", function(){
      var hide = sinon.spy(container, 'hide');
      container.show({});
      sinon.assert.called(hide);
    })

    it("sets local entity", function(){
      container.show(ship);
      assert(container.entity).equals(ship);
    });

    it("retrieves entity details", function(){
      var retrieve_details = sinon.spy(ship, 'retrieve_details');
      container.show(ship);
      sinon.assert.calledWith(retrieve_details, canvas.page, sinon.match.func);
    });

    describe("entity_details callback", function(){
      it("appends details to entity container", function(){
        var retrieve_details = sinon.stub(ship, 'retrieve_details');
        container.show(ship);

        var append = sinon.spy(container, 'append');
        var details_cb = retrieve_details.getCall(0).args[1];
        details_cb('details');

        sinon.assert.calledWith(append, 'details');
        assert($(container.contents_id).html()).equals('details');
      });
    });

    it("invokes entity selected callback", function(){
      var selected = sinon.spy(ship, 'selected');
      container.show(ship);
      sinon.assert.calledWith(selected, canvas.page);
    });

    it("shows entity container", function(){
      assert($(container.div_id)).isHidden();
      container.show(ship);
      assert($(container.div_id)).isVisible();
    });
  });

  describe("#append", function(){
    it("appends text to entity container contents", function(){
      assert($(container.contents_id).html()).equals('');
      container.append('details');
      assert($(container.contents_id).html()).equals('details');
    });
  });

  describe("#refresh", function(){
    after(function(){
    });

    it("reshows scene with current entity", function(){
      var entity = {};
      container.show(entity);

      var show = sinon.spy(container, 'show');
      container.refresh();
      sinon.assert.calledWith(show, entity);
    });

    describe("local entity not set", function(){
      it("does nothing", function(){
        var show = sinon.spy(container, 'show');
        container.refresh();
        sinon.assert.notCalled(show);
      });
    });
  });
});});

pavlov.specify("Omega.UI.CanvasSkybox", function(){
describe("Omega.UI.CanvasSkybox", function(){
  var orig;

  before(function(){
    orig = Omega.UI.CanvasSkybox.gfx;
  });

  after(function(){
    Omega.UI.CanvasSkybox.gfx = orig;
  });
  
  it("has the id: canvas_skybox", function(){
    var skybox = new Omega.UI.CanvasSkybox();
    assert(skybox.id).equals('canvas_skybox');
  })

  describe("#load_gfx", function(){
    describe("graphics are initialized", function(){
      it("does nothing / just returns", function(){
        Omega.UI.CanvasSkybox.gfx = {};
        new Omega.UI.CanvasSkybox().load_gfx();
        assert(Omega.UI.CanvasSkybox.gfx.mesh).isUndefined();
      });
    });

    it("creates mesh for skybox", function(){
      var canvas = Omega.Test.Canvas();
      assert(canvas.skybox.mesh).isOfType(THREE.Mesh);
      assert(canvas.skybox.mesh.geometry).isOfType(THREE.CubeGeometry);
      assert(canvas.skybox.mesh.material).isOfType(THREE.ShaderMaterial);
    });
  });

  describe("#init_gfx", function(){
    it("loads skybox gfx", function(){
      var skybox = new Omega.UI.CanvasSkybox();
      var load_gfx = sinon.spy(skybox, 'load_gfx');
      skybox.init_gfx();
      sinon.assert.called(load_gfx);
    });

    it("adds Skybox mesh to scene components", function(){
      var skybox = new Omega.UI.CanvasSkybox();
      skybox.init_gfx();
      assert(skybox.components[0]).equals(skybox.mesh);
    });
  });

  describe("#set", function(){
    it("sets mesh material to new background", function(){
      var skybox = new Omega.UI.CanvasSkybox({canvas: Omega.Test.Canvas()});
      skybox.init_gfx();
      var oldB = skybox.mesh.material.uniforms["tCube"].value;
      skybox.set('galaxy1');
      var newB = skybox.mesh.material.uniforms["tCube"].value;
      assert(oldB).isNotEqualTo(newB); // XXX should validate actual new value
    });
  });
});}); // Omega.UI.CanvasSkybox

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
