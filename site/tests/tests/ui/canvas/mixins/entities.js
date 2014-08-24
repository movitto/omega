pavlov.specify("Omega.UI.Canvas", function(){
describe("Omega.UI.Canvas", function(){
  var canvas;

  before(function(){
    canvas = Omega.Test.canvas();
  });

  after(function(){
    canvas.clear();
  });

  describe("#descendants", function(){
    it("returns descendants in all scenes", function(){
      var mesh1 = new THREE.Mesh();
      var mesh2 = new THREE.Mesh();
      canvas.scene.add(mesh1);
      canvas.skyScene.add(mesh2);
      assert(canvas.descendants()).isSameAs([mesh1, mesh2]);
    });
  });

  describe("#set_scene_root", function(){
    var canvas;
    before(function(){
      canvas = new Omega.UI.Canvas();
    });

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
      canvas = new Omega.UI.Canvas();
      system = new Omega.SolarSystem({id : 42});
      canvas.set_scene_root(system);
    });

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

  describe("#add", function(){
    var star, planet, mesh;

    before(function(){
      mesh   = new THREE.Mesh();
      star   = new Omega.Star({id : 42, components: [mesh]});
      planet   = Omega.Gen.planet();

      /// stub out init_gfx
      sinon.stub(star, 'init_gfx');
      sinon.stub(planet, 'init_gfx');
    });

    it("initializes entity graphics", function(){
      canvas.add(star);
      sinon.assert.calledWith(star.init_gfx, sinon.match.func);
      // TODO verify _init_gfx callback
    });

    it("adds entity components to scene", function(){
      canvas.add(star);
      assert(canvas.scene.getDescendants()).includes(mesh);
    });

    it("adds entity components to specified scene", function(){
      var scene  = new THREE.Scene();
      canvas.add(star, scene);
      assert(scene.getDescendants()).includes(mesh);
    });

    it("adds entity to effects player", function(){
      canvas.add(planet);
      assert(canvas.page.effects_player.has(planet.id)).isTrue();
    });

    it("adds entity id to local entities registry", function(){
      assert(canvas.entities).doesNotInclude(42);
      canvas.add(star);
      assert(canvas.entities).includes(42);
    });
  });

  describe("#remove", function(){
    var star, mesh;

    before(function(){
      mesh   = new THREE.Mesh();
      star   = new Omega.Star({id : 42, components: [mesh]});
      sinon.stub(star, 'init_gfx'); /// stub out init gfx
    });

    it("removes entity components from scene", function(){
      canvas.add(star);
      canvas.remove(star);
      assert(canvas.scene.getDescendants()).doesNotInclude(mesh);
    });

    it("removes entity components from specified scene", function(){
      var scene  = new THREE.Scene();
      canvas.add(star, scene);
      canvas.remove(star, scene);
      assert(scene.getDescendants()).doesNotInclude(mesh);
    });

    it("removes entity from effects player", function(){
      canvas.add(star);
      canvas.remove(star);
      assert(canvas.page.effects_player.has(star.id)).isFalse();
    });

    it("removes entity id from local entities registry", function(){
      canvas.add(star);
      assert(canvas.entities).includes(42);
      canvas.remove(star);
      assert(canvas.entities).doesNotInclude(42);
    });
  });

  describe("#reload", function(){
    var jg, canvas;

    before(function(){
      jg = new Omega.JumpGate();
      canvas = new Omega.UI.Canvas({page : new Omega.Pages.Test()});
      sinon.stub(jg, 'init_gfx'); /// stub out init gfx
      canvas.add(jg);
      sinon.stub(canvas, 'remove');
      sinon.stub(canvas, 'add');
    });

    it("removes entity from canvas", function(){
      canvas.reload(jg);
      sinon.assert.calledWith(canvas.remove, jg);
    });

    it("removes entity from specified canvas scene", function(){
      var scene = new THREE.Scene();
      canvas.reload(jg, scene);
      sinon.assert.calledWith(canvas.remove, jg, scene);
    });

    it("invokes callback with entity", function(){
      var cb = sinon.spy();
      canvas.reload(jg, cb);
      sinon.assert.calledWith(cb, jg);
    });

    it("adds entity to canvas", function(){
      canvas.reload(jg);
      sinon.assert.calledWith(canvas.add, jg);
    });

    it("adds entity to specified canvas scene", function(){
      var scene = new THREE.Scene();
      canvas.reload(jg, scene);
      sinon.assert.calledWith(canvas.add, jg, scene);
    });

/// FIXME:
    //describe("entity was not in scene", function(){
    //  it("does not reload entity", function(){
    //    var add = sinon.spy(canvas, 'add');
    //    star = Omega.Test.entities().star;
    //    canvas.reload(star);
    //    sinon.assert.notCalled(add);
    //  })
    //});
  });

  describe("#clear", function(){
    it("clears root entity", function(){
      var system = new Omega.SolarSystem({});
      canvas.set_scene_root(system);
      canvas.clear();
      assert(canvas.root).isNull();
    });

    it("clears entities list", function(){
      canvas.entities = [42];
      canvas.clear();
      assert(canvas.entities).isSameAs([]);
    });

    it("clears all components from scene", function(){
      var mesh1  = new THREE.Mesh();
      var mesh2  = new THREE.Mesh();
      var star   = new Omega.Star({components : [mesh1]});

      canvas.add(star);
      canvas.clear();
      assert(canvas.scene.getDescendants()).doesNotInclude(mesh1);
    });
  });

  describe("#has", function(){
    var canvas;

    before(function(){
      canvas = new Omega.UI.Canvas();
      canvas.entities = [42];
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
