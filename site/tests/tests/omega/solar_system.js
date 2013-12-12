pavlov.specify("Omega.SolarSystem", function(){
describe("Omega.SolarSystem", function(){
  it("sets background"):

  it("converts children", function(){
    var star   = {json_class: 'Cosmos::Entities::Star',   id: 'star1'};
    var planet = {json_class: 'Cosmos::Entities::Planet', id: 'planet1'};
    var system = new Omega.SolarSystem({children: [star, planet]});
    assert(system.children.length).equals(2);
    assert(system.children[0]).isOfType(Omega.Star);
    assert(system.children[0].id).equals('star1');
    assert(system.children[1]).isOfType(Omega.Planet);
    assert(system.children[1].id).equals('planet1');
  });

  it("converts location");

  describe("#asteroids", function(){
    it("returns asteroid children");
  });

  describe("#planets", function(){
    it("returns planet children");
  });

  describe("#jump_gates", function(){
    it("returns jump_gate children");
  });

  describe("#update_children_from", function(){
    it("sets child jump gate endpoints from entity list");
  });

  describe("#clicked_in", function(){
    it("sets canvas scene root", function(){
      var canvas = new Omega.UI.Canvas();
      var set_scene_root = sinon.stub(canvas, 'set_scene_root');

      var system = new Omega.SolarSystem();
      system.clicked_in(canvas);
      sinon.assert.calledWith(set_scene_root, system);
    });
  });

  describe("#load_gfx", function(){
    describe("graphics are initialized", function(){
      var orig;

      before(function(){
        orig = Omega.SolarSystem.gfx;
      })

      after(function(){
        Omega.SolarSystem.gfx = orig;
      });

      it("does nothing / just returns", function(){
        Omega.SolarSystem.gfx = {mesh : null};
        new Omega.SolarSystem().load_gfx();
        assert(Omega.SolarSystem.gfx.mesh).isNull();
      });
    });

    it("creates mesh for solar system", function(){
      Omega.Test.Canvas.Entities();
      assert(Omega.SolarSystem.gfx.mesh).isOfType(THREE.Mesh);
      assert(Omega.SolarSystem.gfx.mesh.geometry).isOfType(THREE.SphereGeometry);
      assert(Omega.SolarSystem.gfx.mesh.material).isOfType(THREE.MeshBasicMaterial);
    });

    it("creates plane for solar system", function(){
      Omega.Test.Canvas.Entities();
      assert(Omega.SolarSystem.gfx.plane).isOfType(THREE.Mesh);
      assert(Omega.SolarSystem.gfx.plane.geometry).isOfType(THREE.PlaneGeometry);
      assert(Omega.SolarSystem.gfx.plane.material).isOfType(THREE.MeshBasicMaterial);
    });
  });

  describe("#init_gfx", function(){
    before(function(){
      /// preiinit using test page
      Omega.Test.Canvas.Entities();
    });

    after(function(){
      if(Omega.SolarSystem.gfx){
        if(Omega.SolarSystem.gfx.mesh.clone.restore) Omega.SolarSystem.gfx.mesh.clone.restore();
        if(Omega.SolarSystem.gfx.plane.clone.restore) Omega.SolarSystem.gfx.plane.clone.restore();
      }
    });

    it("loads galaxy gfx", function(){
      var solar_system = new Omega.SolarSystem();
      var load_gfx  = sinon.spy(solar_system, 'load_gfx');
      solar_system.init_gfx();
      sinon.assert.called(load_gfx);
    });

    it("clones SolarSystem mesh", function(){
      var solar_system = new Omega.SolarSystem();
      var mesh = new THREE.Mesh();
      sinon.stub(Omega.SolarSystem.gfx.mesh, 'clone').returns(mesh);
      solar_system.init_gfx();
      assert(solar_system.mesh).equals(mesh);
    });
    
    it("sets omege_entity on mesh", function(){
      var solar_system = new Omega.SolarSystem();
      solar_system.init_gfx();
      assert(solar_system.mesh.omega_entity).equals(solar_system);
    });

    it("sets mesh position", function(){
      var solar_system = new Omega.SolarSystem({location : new Omega.Location({x: 50, y: 60, z: -75})});
      solar_system.init_gfx();
      assert(solar_system.mesh.position.toArray()).isSameAs([50, 60, -75]);
    });

    it("clones SolarSystem plane", function(){
      var solar_system = new Omega.SolarSystem();
      var mesh = new THREE.Mesh();
      sinon.stub(Omega.SolarSystem.gfx.plane, 'clone').returns(mesh);
      solar_system.init_gfx();
      assert(solar_system.plane).equals(mesh);
    });

    it("sets plane position", function(){
      var solar_system = new Omega.SolarSystem({location : new Omega.Location({x: 50, y: 60, z: -75})});
      solar_system.init_gfx();
      assert(solar_system.plane.position.toArray()).isSameAs([50, 60, -75]);
    });

    it("creates text for solar system", function(){
      var solar_system = new Omega.SolarSystem();
      solar_system.init_gfx();
      assert(solar_system.text).isOfType(THREE.Mesh);
      assert(solar_system.text.geometry).isOfType(THREE.TextGeometry);
      assert(solar_system.text.material).isOfType(THREE.MeshBasicMaterial);
    });

    it("sets text position", function(){
      var solar_system = new Omega.SolarSystem({location : new Omega.Location({x: 50, y: 60, z: -75})});
      solar_system.init_gfx();
      assert(solar_system.text.position.toArray()).isSameAs([50, 60, -25]);
    });
    
    it("adds mesh, plane, text to solar system scene components", function(){
      var solar_system = new Omega.SolarSystem();
      solar_system.init_gfx();
      assert(solar_system.components).isSameAs([solar_system.mesh, solar_system.plane, solar_system.text]);
    });
  });

  describe("#run_effects", function(){
    //it("updates interconnect particles") // NIY
  });

  describe("#add_interconn", function(){
    var system, endpoint;
    
    before(function(){
      Omega.Test.Canvas.Entities();
      system   = new Omega.SolarSystem({location : new Omega.Location({x:100,y:200,z:300})});
      endpoint = new Omega.SolarSystem({location : new Omega.Location({x:-300,y:-200,z:-100})});
    });

    it("adds line to solar system scene components", function(){
      system.add_interconn(endpoint);
      var line = system.components[0];
      assert(line).isOfType(THREE.Line);
      assert(line.geometry.vertices[0].toArray()).isSameAs([100,200,300]);
      assert(line.geometry.vertices[1].toArray()).isSameAs([-300,-200,-100]);
      assert(line.material).isOfType(THREE.LineBasicMaterial);
    });

    it("adds particle system to solar system scene components and interconnects", function(){
      system.add_interconn(endpoint);
      var particles = system.components[1];
      assert(particles).isOfType(THREE.ParticleSystem);
      assert(particles.material).isOfType(THREE.ParticleBasicMaterial);
      assert(particles.geometry.vertices.length).equals(1);
      assert(particles.ticker).equals(0);
      assert(system.interconnections).isSameAs([particles]);
    });

    it("sets dx/dy/dz/ticks on particle system");
  });

  describe("#with_id", function(){
    var node, retrieval_cb, invoke_spy;

    before(function(){
      node = new Omega.Node();
      retrieval_cb = sinon.spy();
      invoke_spy = sinon.stub(node, 'http_invoke');
    });

    it("invokes cosmos::get_entity request", function(){
      Omega.SolarSystem.with_id('system1', node, retrieval_cb);
      sinon.assert.calledWith(invoke_spy, 'cosmos::get_entity', 'with_id', 'system1');
    });

    describe("cosmos::get_entity callback", function(){
      it("invokes callback", function(){
        Omega.SolarSystem.with_id('system1', node, retrieval_cb);
        invoke_spy.getCall(0).args[3]({});
        sinon.assert.called(retrieval_cb);
      });

      it("creates new system instance", function(){
        Omega.SolarSystem.with_id('system1', node, retrieval_cb);
        invoke_spy.getCall(0).args[3]({result : {id:'sys1'}});
        var system = retrieval_cb.getCall(0).args[0];
        assert(system).isOfType(Omega.SolarSystem);
        assert(system.id).equals('sys1');
      });
    });
  });
});}); // Omega.SolarSystem
