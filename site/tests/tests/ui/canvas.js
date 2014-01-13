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

///TODO uncomment?
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

    it("adds a render/shader passes to composer", function(){
      var canvas = Omega.Test.Canvas();
      assert(canvas.composer.passes.length).equals(2);
      assert(canvas.composer.passes[0]).isOfType(THREE.RenderPass);
      assert(canvas.composer.passes[1]).isOfType(THREE.ShaderPass);
      //assert(canvas.composer.passes[1]); // TODO verify ShaderPass pulls in ShaderComposer via AdditiveBlending
      assert(canvas.composer.passes[1].renderToScreen).isTrue();
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
      sinon.assert.calledWith(spy, canvas.page.config, sinon.match.func);
      // TODO verify callback animates scene
    });

    it("adds entity components to scene", function(){
      var mesh   = new THREE.Mesh();
      var star   = new Omega.Star({components: [mesh]});
      canvas.add(star);
      assert(canvas.scene.getDescendants()).includes(mesh);
    });

    it("adds entity shader components to shader scene", function(){
      var mesh   = new THREE.Mesh();
      var star   = new Omega.Star({shader_components: [mesh]});
      canvas.add(star);
      assert(canvas.shader_scene.getDescendants()).includes(mesh);
    });

    it("wires up loaded_mesh event handler", function(){
      var star   = new Omega.Star({});
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

    it("adds entity to effects player", function(){
      var star   = new Omega.Star({});
      canvas.add(star);
      assert(canvas.page.effects_player.has(star.id)).isTrue();
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

    it("removes entity shader components from shader scene", function(){
      var mesh   = new THREE.Mesh();
      var star   = new Omega.Star({shader_components: [mesh]});
      canvas.add(star);
      canvas.remove(star);
      assert(canvas.shader_scene.getDescendants()).doesNotInclude(mesh);
    });

    it("removes loaded_mesh event handler", function(){
      var star   = new Omega.Star({});
      canvas.add(star);
      assert(star).handlesEvent('loaded_mesh');
      canvas.remove(star);
      assert(star).doesNotHandleEvent('loaded_mesh');
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
