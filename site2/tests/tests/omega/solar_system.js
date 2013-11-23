pavlov.specify("Omega.SolarSystem", function(){
describe("Omega.SolarSystem", function(){
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

    it("clones SolarSystem plane", function(){
      var solar_system = new Omega.SolarSystem();
      var mesh = new THREE.Mesh();
      sinon.stub(Omega.SolarSystem.gfx.plane, 'clone').returns(mesh);
      solar_system.init_gfx();
      assert(solar_system.plane).equals(mesh);
    });

    it("creates text for solar system", function(){
      var solar_system = new Omega.SolarSystem();
      solar_system.init_gfx();
      assert(solar_system.text).isOfType(THREE.Mesh);
      assert(solar_system.text.geometry).isOfType(THREE.TextGeometry);
      assert(solar_system.text.material).isOfType(THREE.MeshBasicMaterial);
    });
  });

  describe("#run_effects", function(){
  });

  describe("#add_jump_gate", function(){
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
