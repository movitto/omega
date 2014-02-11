pavlov.specify("Omega.SolarSystem", function(){
describe("Omega.SolarSystem", function(){
  it("sets background", function(){
    var sys = new Omega.SolarSystem({background : 1});
    assert(sys.bg).equals(1);
  });

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

  it("converts location", function(){
    var system = new Omega.SolarSystem({location : {json_class : 'Motel::Location', data : {x: 10, y: 20, z:30}}});
    assert(system.location).isOfType(Omega.Location);
    assert(system.location.x).equals(10);
    assert(system.location.y).equals(20);
    assert(system.location.z).equals(30);
  });

  describe("#toJSON", function(){
    it("returns system json data", function(){
      var sys  = {id        : 'sys1',
                  name      : 'sys1n',
                  parent_id : 'gal1',
                  location  : new Omega.Location({id : 'sys1l'}),
                  children  : [new Omega.Star({id : 'star1',
                                 location : new Omega.Location({id:'loc1'})})]};

      var osys = new Omega.SolarSystem(sys);
      var json = osys.toJSON();

      sys.json_class  = osys.json_class;
      sys.location    = sys.location.toJSON();
      sys.children[0] = sys.children[0].toJSON();
      assert(json).isSameAs(sys);
    });
  });

  describe("#asteroids", function(){
    it("returns asteroid children", function(){
      var ast1 = new Omega.Asteroid();
      var ast2 = new Omega.Asteroid();
      var planet1 = new Omega.Planet();
      var system = new Omega.SolarSystem({children : [ast1, ast2, planet1]})
      assert(system.asteroids()).isSameAs([ast1, ast2]);
    });
  });

  describe("#planets", function(){
    it("returns planet children", function(){
      var ast1 = new Omega.Asteroid();
      var planet1 = new Omega.Planet();
      var planet2 = new Omega.Planet();
      var system = new Omega.SolarSystem({children : [ast1, planet1, planet2]})
      assert(system.planets()).isSameAs([planet1, planet2]);
    });
  });

  describe("#jump_gates", function(){
    it("returns jump_gate children", function(){
      var star1 = new Omega.Star();
      var jg1 = new Omega.JumpGate();
      var jg2 = new Omega.JumpGate();
      var system = new Omega.SolarSystem({children : [star1, jg1, jg2]})
      assert(system.jump_gates()).isSameAs([jg1, jg2]);
    });
  });

  describe("#update_children_from", function(){
    it("sets child jump gate endpoints from entity list", function(){
      var jg1  = new Omega.JumpGate({endpoint_id : 'sys1'});
      var jg2  = new Omega.JumpGate({endpoint_id : 'sys2'});
      var sys1 = new Omega.SolarSystem({id : 'sys1'});
      var sys2 = new Omega.SolarSystem({id : 'sys2'});
      var sys3 = new Omega.SolarSystem({id : 'sys3', children: [jg1, jg2]});
      var entities = [sys1, sys2, sys3];
      sys3.update_children_from(entities);
      assert(jg1.endpoint).equals(sys1);
      assert(jg2.endpoint).equals(sys2);
    });
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
      assert(Omega.SolarSystem.gfx.mesh).isOfType(Omega.SolarSystemMesh);
      assert(Omega.SolarSystem.gfx.mesh.tmesh).isOfType(THREE.Mesh);
      assert(Omega.SolarSystem.gfx.mesh.tmesh.geometry).isOfType(THREE.SphereGeometry);
      assert(Omega.SolarSystem.gfx.mesh.tmesh.material).isOfType(THREE.MeshBasicMaterial);
    });

    it("creates plane for solar system", function(){
      Omega.Test.Canvas.Entities();
      assert(Omega.SolarSystem.gfx.plane).isOfType(Omega.SolarSystemPlane);
      assert(Omega.SolarSystem.gfx.plane.tmesh).isOfType(THREE.Mesh);
      assert(Omega.SolarSystem.gfx.plane.tmesh.geometry).isOfType(THREE.PlaneGeometry);
      assert(Omega.SolarSystem.gfx.plane.tmesh.material).isOfType(THREE.MeshBasicMaterial);
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
      assert(solar_system.mesh.tmesh.position.toArray()).isSameAs([50, 60, -75]);
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
      assert(solar_system.plane.tmesh.position.toArray()).isSameAs([50, 60, -75]);
    });

    it("creates text for solar system", function(){
      var solar_system = new Omega.SolarSystem();
      solar_system.init_gfx();
      assert(solar_system.text).isOfType(Omega.SolarSystemText);
      assert(solar_system.text.text).isOfType(THREE.Mesh);
      assert(solar_system.text.text.geometry).isOfType(THREE.TextGeometry);
      assert(solar_system.text.text.material).isOfType(THREE.MeshBasicMaterial);
    });

    it("sets text position", function(){
      var solar_system = new Omega.SolarSystem({location : new Omega.Location({x: 50, y: 60, z: -75})});
      solar_system.init_gfx();
      assert(solar_system.text.text.position.toArray()).isSameAs([50, 110, -75]);
    });
    
    it("adds mesh, plane, text to solar system scene components", function(){
      var solar_system = new Omega.SolarSystem();
      solar_system.init_gfx();
      assert(solar_system.components).isSameAs([solar_system.plane.tmesh,
                                                solar_system.text.text]);
    });

    it("invokes add_interconnect with queued interconnections", function(){
      var solar_system = new Omega.SolarSystem({location : new Omega.Location()});
      var endpoint = new Omega.SolarSystem({location : new Omega.Location()});
      solar_system._queued_interconns = [endpoint]
      var add_interconn = sinon.spy(solar_system, 'add_interconn');
      solar_system.init_gfx();
      sinon.assert.calledWith(add_interconn, endpoint);
    })
  });

  describe("#run_effects", function(){
    //it("updates interconnect particles") // NIY
  });

  describe("#add_interconn", function(){
    var system, endpoint;
    
    before(function(){
      Omega.Test.Canvas.Entities();
      system   = new Omega.SolarSystem({location : new Omega.Location({x:100,y:200,z:300}),
                                        components : [new THREE.Mesh()]});
      endpoint = new Omega.SolarSystem({location : new Omega.Location({x:-300,y:-200,z:-100})});
    });

    describe("system gfx components not initialized", function(){
      it("adds line to queued interconns", function(){
        system.components = [];
        system.add_interconn(endpoint);
        assert(system._queued_interconns).isSameAs([endpoint]);
        assert(system.components.length).equals(0);
      });
    });

    it("adds line to solar system scene components", function(){
      system.add_interconn(endpoint);
      var line = system.components[1];
      assert(line).isOfType(THREE.Line);
      assert(line.geometry.vertices[0].toArray()).isSameAs([100,200,300]);
      assert(line.geometry.vertices[1].toArray()).isSameAs([-300,-200,-100]);
      assert(line.material).isOfType(THREE.LineBasicMaterial);
    });

    it("adds particle system to solar system scene components and interconnects", function(){
      system.add_interconn(endpoint);
      var particles = system.components[2];
      assert(particles).isOfType(THREE.ParticleSystem);
      assert(particles.material).isOfType(THREE.ParticleBasicMaterial);
      assert(particles.geometry.vertices.length).equals(1);
      assert(particles.ticker).equals(0);
      assert(system.interconnections).isSameAs([particles]);
    });

    it("sets dx/dy/dz/ticks on particle system", function(){
      system.add_interconn(endpoint);
      var particles = system.components[2];
      var d = system.location.distance_from(endpoint.location);
      var dx = (endpoint.location.x - system.location.x) / d;
      var dy = (endpoint.location.y - system.location.y) / d;
      var dz = (endpoint.location.z - system.location.z) / d;

      assert(particles.dx).equals(dx);
      assert(particles.dy).equals(dy);
      assert(particles.dz).equals(dz);
      assert(particles.ticks).equals(d/50);
    });
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
