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
    var loc = {json_class : 'Motel::Location', data : {x: 10, y: 20, z:30}};
    var system = new Omega.SolarSystem({location : loc});
    assert(system.location).isOfType(Omega.Location);
    assert(system.location.x).equals(10);
    assert(system.location.y).equals(20);
    assert(system.location.z).equals(30);
  });

  describe("#child", function(){
    it("returns solar system child w/ the specified id", function(){
      var system = new Omega.SolarSystem();
      var planet1 = Omega.Gen.planet();
      var planet2 = Omega.Gen.planet();
      system.children = [planet1, planet2];
      assert(system.child(planet1.id)).equals(planet1);
    });
  });

  describe("#refresh", function(){
    var node, system, retrieved;
    before(function(){
      node = new Omega.Node();
      system = Omega.Gen.solar_system();
      retrieved = Omega.Gen.solar_system();

      sinon.stub(Omega.SolarSystem, 'with_id');
    });

    after(function(){
      Omega.SolarSystem.with_id.restore();
    });

    it("retrieves system from server", function(){
      system.refresh(node);
      sinon.assert.calledWith(Omega.SolarSystem.with_id,
        system.id, node, {children: true}, sinon.match.func);
    });

    it("updates system with result", function(){
      sinon.stub(system, 'update')
      system.refresh(node);
      Omega.SolarSystem.with_id.omega_callback()(retrieved);
      sinon.assert.calledWith(system.update, retrieved);
    });

    it("invokes callback with system", function(){
      var cb = sinon.spy();
      system.refresh(node, cb);
      Omega.SolarSystem.with_id.omega_callback()(retrieved);
      sinon.assert.called(cb);
    });

    it("dispatches refreshed event", function(){
      var cb = sinon.spy();
      system.addEventListener('refreshed', cb);
      system.refresh(node);
      Omega.SolarSystem.with_id.omega_callback()(retrieved, cb);
      sinon.assert.called(cb);
    });
  });

  describe("#update", function(){
    var system,  star,  planet,
        nsystem, nstar, nast;

    before(function(){
      system  = Omega.Gen.solar_system();
      star    = Omega.Gen.star();
      planet  = Omega.Gen.planet();
      system.children = [star, planet, 'ast1'];

      nsystem = Omega.Gen.solar_system();
      nstar   = Omega.Gen.star();
      nplanet = Omega.Gen.planet({id : planet.id});
      nast    = Omega.Gen.asteroid({id : 'ast1'});

      nsystem.children = [nstar, nplanet, nast];
    });

    it("adds missing children to system", function(){
      system.update(nsystem);
      assert(system.children).includes(nstar);
    });

    it("updates system children ids", function(){
      system.update(nsystem);
      assert(system.children).includes(nast);
      assert(system.children).doesNotInclude('ast1');
    });

    it("updates existing children", function(){
      sinon.spy(planet, 'update');
      system.update(nsystem);
      sinon.assert.calledWith(planet.update, nplanet);
    });
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

  describe("#title", function(){
    describe("name is set", function(){
      it("returns name", function(){
        var system = new Omega.SolarSystem({name : 'system1'});
        assert(system.title()).equals('system1');
      });
    });

    describe("name is not set", function(){
      it("returns id", function(){
        var system = new Omega.SolarSystem({id : 'system1'});
        assert(system.title()).equals('system1');
      });
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

  describe("#has_interconn_to", function(){
    describe("system has gate to specified endpoint", function(){
      it("returns true", function(){
        var system = Omega.Gen.solar_system();
        var target = Omega.Gen.solar_system({id : 'endpoint'});
        system.interconns.endpoints = [target];
        assert(system.has_interconn_to('endpoint')).isTrue();
      });
    });

    describe("system does not have gate to specified endpoint", function(){
      it("returns false", function(){
        var system = Omega.Gen.solar_system();
        assert(system.has_interconn_to('endpoint')).isFalse();
      });
    });
  });

  describe("#add_interconn_to", function(){
    it("adds interconnection to endpoint", function(){
      var system   = Omega.Gen.solar_system();
      var endpoint = Omega.Gen.solar_system();

      sinon.stub(system.interconns, 'add');
      system.add_interconn_to(endpoint);
      sinon.assert.calledWith(system.interconns.add, endpoint);
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
      canvas = new Omega.UI.Canvas({page : new Omega.Pages.Test()});
    });

    it("refreshes the system", function(){
      sinon.stub(system, 'refresh');
      system.clicked_in(canvas);
      sinon.assert.calledWith(system.refresh,
          canvas.page.node, sinon.match.func);
    });

    describe("solar system not selected", function(){
      it("refreshes entity details", function(){
        sinon.stub(system, 'refresh');
        sinon.stub(canvas.entity_container, 'is_selected').returns(false);

        sinon.stub(system, 'refresh_details');
        system.clicked_in(canvas);
        system.refresh.omega_callback()();
        sinon.assert.calledWith(system.refresh_details);
      });
    });

    describe("solar system selected", function(){
      it("sets canvas scene root", function(){
        sinon.stub(system, 'refresh');
        sinon.stub(canvas.entity_container, 'is_selected').returns(true);

        sinon.stub(canvas, 'set_scene_root');
        system.clicked_in(canvas);
        system.refresh.omega_callback()();
        sinon.assert.calledWith(canvas.set_scene_root, system);
      });
    });
  });

  describe("on_hover", function(){
    var canvas, system;

    before(function(){
      system = Omega.Gen.solar_system();
      system.init_gfx();

      canvas = new Omega.UI.Canvas();
      sinon.stub(canvas, 'reload');
    });

    it("reloads system in scene", function(){
      system.on_hover(canvas);
      sinon.assert.calledWith(canvas.reload);
    });

    it("adds hover sphere to system scene components", function(){
      system.on_hover(canvas);
      canvas.reload.omega_callback()();
      assert(system._has_hover_sphere()).isTrue();
    });
  });

  describe("on_unhover", function(){
    var canvas, system;

    before(function(){
      system = Omega.Gen.solar_system();
      system.init_gfx();
      system._add_hover_sphere();

      canvas = new Omega.UI.Canvas();
      sinon.stub(canvas, 'reload');
    });

    it("reloads system in scene", function(){
      system.on_unhover(canvas);
      sinon.assert.calledWith(canvas.reload);
    });

    it("removes hover sphere from system scene compoents", function(){
      system.on_unhover(canvas);
      canvas.reload.omega_callback()();
      assert(system._has_hover_sphere()).isFalse();
    });
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
