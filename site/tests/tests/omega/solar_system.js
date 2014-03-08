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
    var system, canvas;

    before(function(){
      system = new Omega.SolarSystem();
      canvas = new Omega.UI.Canvas();
      canvas.page = Omega.Test.Page();
    });

    it("refreshes the system", function(){
      sinon.stub(system, 'refresh');
      system.clicked_in(canvas);
      sinon.assert.calledWith(system.refresh,
          canvas.page.node, sinon.match.func);
    });

    it("sets canvas scene root", function(){
      sinon.stub(system, 'refresh');
      sinon.stub(canvas, 'set_scene_root');
      system.clicked_in(canvas);
      system.refresh.omega_callback()();
      sinon.assert.calledWith(canvas.set_scene_root, system);
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
    });

    it("creates plane for solar system", function(){
      Omega.Test.Canvas.Entities();
      assert(Omega.SolarSystem.gfx.plane).isOfType(Omega.SolarSystemPlane);
    });
  });

  describe("#init_gfx", function(){
    var system, config;

    before(function(){
      /// preiinit using test page
      Omega.Test.Canvas.Entities();

      system          = new Omega.SolarSystem();
      system.location = new Omega.Location({x: 50, y:60, z:-75});
      config          = Omega.Config;
    });

    after(function(){
      if(Omega.SolarSystem.gfx){
        if(Omega.SolarSystem.gfx.mesh.clone.restore)
          Omega.SolarSystem.gfx.mesh.clone.restore();

        if(Omega.SolarSystem.gfx.plane.clone.restore)
          Omega.SolarSystem.gfx.plane.clone.restore();
      }
    });

    it("loads system gfx", function(){
      sinon.spy(system, 'load_gfx');
      system.init_gfx(config);
      sinon.assert.called(system.load_gfx);
    });

    it("clones SolarSystem mesh", function(){
      var mesh = new Omega.SolarSystemMesh();
      sinon.stub(Omega.SolarSystem.gfx.mesh, 'clone').returns(mesh);
      system.init_gfx(config);
      assert(system.mesh).equals(mesh);
    });
    
    it("sets omege_entity on mesh", function(){
      system.init_gfx(config);
      assert(system.mesh.omega_entity).equals(system);
    });

    it("sets mesh position", function(){
      system.init_gfx(config);
      assert(system.mesh.tmesh.position.toArray()).isSameAs([50, 60, -75]);
    });

    it("clones SolarSystem plane", function(){
      var plane = new Omega.SolarSystemPlane({config: config});
      sinon.stub(Omega.SolarSystem.gfx.plane, 'clone').returns(plane);
      system.init_gfx(config);
      assert(system.plane).equals(plane);
    });

    it("sets plane position", function(){
      system.init_gfx(config);
      assert(system.plane.tmesh.position.toArray()).isSameAs([50, 60, -75]);
    });

    it("creates text for solar system", function(){
      system.init_gfx(config);
      assert(system.text).isOfType(Omega.SolarSystemText);
    });

    it("sets text position", function(){
      system.init_gfx(config);
      assert(system.text.text.position.toArray()).isSameAs([50, 110, -75]);
    });
    
    it("adds plane, text, particles to solar system scene components", function(){
      system.init_gfx(config);
      assert(system.components).isSameAs([system.plane.tmesh,
                                          system.text.text,
                                          system.interconns.particles.mesh]);
    });

    it("unqueues interconnections", function(){
      sinon.stub(system.interconns, 'unqueue');
      system.init_gfx(config);
      sinon.assert.calledWith(system.interconns.unqueue);
    })
  });

  describe("#run_effects", function(){
    //it("updates interconnect particles") // NIY
  });

  describe("#with_id", function(){
    var node, retrieval_cb;

    before(function(){
      node = new Omega.Node();
      retrieval_cb = sinon.spy();
      sinon.stub(node, 'http_invoke');
    });

    it("invokes cosmos::get_entity request", function(){
      Omega.SolarSystem.with_id('system1', node, retrieval_cb);
      sinon.assert.calledWith(node.http_invoke,
        'cosmos::get_entity', 'with_id', 'system1', 'children', false);
    });

    it("passes children arg onto cosmos::get_entity", function(){
      Omega.SolarSystem.with_id('system1', node, {children : true},
                                retrieval_cb);
      sinon.assert.calledWith(node.http_invoke,
        'cosmos::get_entity', 'with_id', 'system1',
        'children', true, sinon.match.func);
    });

    describe("cosmos::get_entity callback", function(){
      it("invokes callback", function(){
        Omega.SolarSystem.with_id('system1', node, retrieval_cb);
        node.http_invoke.omega_callback()({});
        sinon.assert.called(retrieval_cb);
      });

      it("creates new system instance", function(){
        Omega.SolarSystem.with_id('system1', node, retrieval_cb);
        node.http_invoke.omega_callback()({result : {id:'sys1'}});
        var system = retrieval_cb.getCall(0).args[0];
        assert(system).isOfType(Omega.SolarSystem);
        assert(system.id).equals('sys1');
      });
    });
  });
});}); // Omega.SolarSystem
