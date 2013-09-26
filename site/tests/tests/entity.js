pavlov.specify("Entity", function(){
describe("Entity", function(){
  before(function(){
  });

  describe("#update", function(){
    it("copies all attributes from specified object", function(){
      var e1 = new Entity({id : 42})
      var e2 = new Entity({id : 43})
      e1.update(e2)
      assert(e1.id).equals(43)
    })
  });

  it("initializes attributes from args", function(){
    var e = new Entity({id : 42})
    assert(e.id).equals(42);
  })

  describe("toJSON", function(){
    it("returns entity in json format", function(){
      var e = new Entity({json_class : 'Foobar', id : 42})
      assert(e.toJSON()).isSameAs({json_class:"Foobar",data:{id:42}})
    })
  })

});}); // Entities

pavlov.specify("User", function(){
describe("User", function(){
  describe("#is_anon", function(){
    describe("user is configured anon user", function(){
      it("returns true", function(){
        var u = new User({id : $omega_config['anon_user']})
        assert(u.is_anon()).isTrue();
      });
    });
    describe("user is not configured anon user", function(){
      it("returns false", function(){
        var u = new User({id : $omega_config['anon_user'] + 'foobar'})
        assert(u.is_anon()).isFalse();
      });
    });
  });

  describe("anon_user", function(){
    it("is a user instance generated configured anon user", function(){
      assert(User.anon_user.id).equals($omega_config.anon_user)
      assert(User.anon_user.password).equals($omega_config.anon_pass)
    });
  })
});}); // User

pavlov.specify("Location", function(){
describe("Location", function(){
  describe("#distance_from", function(){
    it("returns distance from location to specified coordiante", function(){
      var l = new Location({x:0,y:0,z:0});
      assert(l.distance_from(10,0,0)).equals(10)
      assert(l.distance_from(0,10,0)).equals(10)
      assert(l.distance_from(0,0,10)).equals(10)
    });
  })

  describe("#is_within", function(){
    describe("location is within distance of other location", function(){
      it("returns true", function(){
        var l1 = new Location({x:0,y:0,z:0})
        var l2 = new Location({x:0,y:0,z:1})
        assert(l1.is_within(10, l2)).isTrue();
      });
    })

    describe("location is not within distance of other location", function(){
      it("returns false", function(){
        var l1 = new Location({x:0,y:0,z:0})
        var l2 = new Location({x:0,y:0,z:100})
        assert(l1.is_within(10, l2)).isFalse();
      });
    })
  })
});}); // Location

pavlov.specify("Galaxy", function(){
describe("Galaxy", function(){
  var galaxy; var sys1; var sys2;

  before(function(){
    disable_three_js();
    Entities().node(new TestNode());

    sys1 = { id : 'sys1'}
    sys2 = { id : 'sys2'}
    galaxy = new Galaxy({location : { id : 42 },
                         children : [sys1, sys2]});
  })

  after(function(){
    if(Entities().node().web_request.restore) Entities().node().web_request.restore();
  })

  describe("#update", function(){
    it("updates attributes", function(){
      var spy = sinon.spy(galaxy, 'old_update');
      galaxy.update({id : 'gal2'});
      sinon.assert.calledWith(spy, {id: 'gal2'})
    });

    it("updates location", function(){
      var spy = sinon.spy(galaxy.location, 'update');
      var l = {id : 'loc1'}
      galaxy.update({location : l})
      sinon.assert.calledWith(spy, l)
    });

    it("updates solar systems", function(){
      var nsys1 = { id : 'sys1'}
      var nsys2 = { id : 'sys2'}
      var spy1 = sinon.spy(galaxy.solar_systems[0], 'update')
      var spy2 = sinon.spy(galaxy.solar_systems[1], 'update')
      galaxy.update({solar_systems : [nsys1, nsys2]})
      sinon.assert.calledWith(spy1, nsys1);
      sinon.assert.calledWith(spy2, nsys2);
    });
  })

  it("converts location", function(){
    assert(galaxy.location).isTypeOf(Location)
  })

  it("converts solar system children", function(){
    assert(galaxy.solar_systems[0]).isTypeOf(SolarSystem);
    assert(galaxy.solar_systems[1]).isTypeOf(SolarSystem);
  })

  describe("#children", function(){
    it("returns child solar systems", function(){
      var c = galaxy.children()
      assert(c[0]).isTypeOf(SolarSystem);
      assert(c[0].id).equals(sys1.id)
      assert(c[1]).isTypeOf(SolarSystem);
      assert(c[1].id).equals(sys2.id)
    })
  })

  describe("#with_id", function(){
    it('invokes cosmos::get_entity', function(){
      var spy = sinon.spy(Entities().node(), 'web_request')
      Galaxy.with_id('gal1')
      sinon.assert.calledWith(spy, 'cosmos::get_entity', 'with_id', 'gal1')
    });

    describe("succesfull get_entity response", function(){
      var cb; var res;
      var handler;

      before(function(){
        var spy = sinon.spy(Entities().node(), 'web_request')
        handler = sinon.spy();
        Galaxy.with_id('gal1', handler)
        cb = spy.getCall(0).args[3];
        res = {result : {id : 'gal1'}}
      })

      it("invokes callback with new galaxy", function(){
        cb.apply(null, [res]);
        sinon.assert.calledWith(handler,
                                sinon.match.instanceOf(Galaxy).and(
                                sinon.match.has('id', 'gal1')))
      });
    })
  })
});}); // Galaxy

pavlov.specify("SolarSystem", function(){
describe("SolarSystem", function(){
  var sys;
  var st1; var pl1; var p2; var ast1; var jg1;

  before(function(){
    disable_three_js();
    Entities().node(new TestNode());

    st1  = { json_class : 'Cosmos::Entities::Star', id : 'star1' };
    pl1  = { json_class : 'Cosmos::Entities::Planet', id : 'planet1' };
    pl2  = { json_class : 'Cosmos::Entities::Planet', id : 'planet2' };
    jg1  = { json_class : 'Cosmos::Entities::JumpGate', id : 'jump_gate1' };
    ast1 = { json_class : 'Cosmos::Entities::Asteroid', id : 'asteroid1' };
    sys  = new SolarSystem({id : 'sys1',
                            location : { id : 42 },
                            children : [st1, pl1, pl2, jg1, ast1]});
  })

  after(function(){
    if(Entities().node().web_request.restore) Entities().node().web_request.restore();
  })

  describe("#star", function(){
    it("returns first star", function(){
      assert(sys.star().id).equals(st1.id)
    });
  })


  describe("#update", function(){
    it("updates attributes", function(){
      var spy = sinon.spy(sys, 'old_update');
      sys.update({id : 'sys2'});
      sinon.assert.calledWith(spy, {id: 'sys2'})
    });

    it("updates location", function(){
      var spy = sinon.spy(sys.location, 'update');
      var l = {id : 'loc1'}
      sys.update({location : l})
      sinon.assert.calledWith(spy, l)
    });

    it("updates stars", function(){
      var nst = { id : 'st1'}
      var spy = sinon.spy(sys.stars[0], 'update')
      sys.update({stars : [nst]})
      sinon.assert.calledWith(spy, nst);
    });

    it("updates planets", function(){
      var npl1 = { id : 'pl1'};
      var npl2 = { id : 'pl2'};
      var spy1 = sinon.spy(sys.planets[0], 'update')
      var spy2 = sinon.spy(sys.planets[1], 'update')
      sys.update({planets : [npl1, npl2]})
      sinon.assert.calledWith(spy1, npl1);
      sinon.assert.calledWith(spy2, npl2);
    });

    it("updates asteroids", function(){
      var nast = { id : 'ast1'}
      var spy = sinon.spy(sys.asteroids[0], 'update')
      sys.update({asteroids : [nast]})
      sinon.assert.calledWith(spy, nast);
    });

    it("updates jump gates", function(){
      var njg = { id : 'jg1'}
      var spy = sinon.spy(sys.jump_gates[0], 'update')
      sys.update({jump_gates : [njg]})
      sinon.assert.calledWith(spy, njg);
    });
  })

  it("converts location", function(){
    assert(sys.location).isTypeOf(Location)
  })

  it("converts child stars", function(){
    assert(sys.stars[0]).isTypeOf(Star);
  });

  it("converts child planets", function(){
    assert(sys.planets[0]).isTypeOf(Planet);
    assert(sys.planets[1]).isTypeOf(Planet);
  });

  it("converts child asteroids", function(){
    assert(sys.asteroids[0]).isTypeOf(Asteroid);
  });

  it("converts child jump gates", function(){
    assert(sys.jump_gates[0]).isTypeOf(JumpGate);
  });

  describe("#children", function(){
    it("returns child star, planets, asteroids, jump gates, and manu entities", function(){
      var c = sys.children()
      var ids = [];
      for(var ch in c) ids.push(c[ch].id)
      assert(ids).includes(st1.id);
      assert(ids).includes(pl1.id);
      assert(ids).includes(pl2.id);
      assert(ids).includes(ast1.id);
      assert(ids).includes(jg1.id);
    })
  })

  describe("#with_id", function(){
    it('invokes cosmos::get_entity', function(){
      var spy = sinon.spy(Entities().node(), 'web_request')
      SolarSystem.with_id('sys1')
      sinon.assert.calledWith(spy, 'cosmos::get_entity', 'with_id', 'sys1')
    });

    describe("succesfull get_entity response", function(){
      var cb; var res;
      var handler;

      before(function(){
        var spy = sinon.spy(Entities().node(), 'web_request')
        handler = sinon.spy();
        SolarSystem.with_id('sys1', handler)
        cb  = spy.getCall(0).args[3];
        res = {result : {id : 'sys1'}}
      })

      it("invokes callback with new solar system", function(){
        cb.apply(null, [res]);
        sinon.assert.calledWith(handler,
                                sinon.match.instanceOf(SolarSystem).and(
                                sinon.match.has('id', 'sys1')))
      });
    })
  })

  describe("#entities_under", function(){
    it('invokes manufactured::get_entities', function(){
      var spy = sinon.spy(Entities().node(), 'web_request')
      SolarSystem.entities_under('sys1')
      sinon.assert.calledWith(spy, 'manufactured::get_entities', 'under', 'sys1')
    })

    describe("succesfull get_entities response", function(){
      var cb; var res;
      var handler;

      before(function(){
        var spy = sinon.spy(Entities().node(), 'web_request')
        handler = sinon.spy();
        SolarSystem.entities_under('sys1', handler)
        cb  = spy.getCall(0).args[3];
        res = {result : [{json_class : 'Manufactured::Ship', id : 'sh1'},
                         {json_class : 'Manufactured::Station', id : 'st1' }]}
      })

      it("invokes callback with ships / stations", function(){
        cb.apply(null, [res]);
        sinon.assert.calledWith(handler, sinon.match.array)
        r = handler.getCall(0).args[0]
        assert(r[0]).isTypeOf(Ship);
        assert(r[0].id).equals('sh1')
        assert(r[1]).isTypeOf(Station);
        assert(r[1].id).equals('st1')
      });
    });
  })
});}); // SolarSystem

pavlov.specify("Star", function(){
describe("Star", function(){
  var st;

  before(function(){
    disable_three_js();
    st = new Star({location : { id : 42 }})
  })

  it("converts location", function(){
    assert(st.location).isTypeOf(Location)
  })
});}); // Star

pavlov.specify("Planet", function(){
describe("Planet", function(){
  var pl; var mn;

  before(function(){
    disable_three_js();
    m = { id : 'mn1' }
    pl = new Planet({
          location : {
            id : 42,
            movement_strategy : {
              e : 0, p : 10, speed: 1.57,
              dmajx: 1, dmajy : 0, dmajz : 0,
              dminx: 0, dminy : 0, dminz : 1}},
          moons : [m]})
  })

  it("converts location", function(){
    assert(pl.location).isTypeOf(Location)
  });

  describe("#update", function(){
    it("updates attributes", function(){
      var spy = sinon.spy(pl, 'old_update')
      pl.update({ id : 'pl2'});
      sinon.assert.calledWith(spy, {id : 'pl2'});
    });

    it("updates location", function(){
      var spy = sinon.spy(pl.location, 'update');
      var l = {id : 'loc1'}
      pl.update({location : l})
      sinon.assert.calledWith(spy, l)
    });

    it("reloads entity in scene", function(){
      pl.current_scene = new Scene();
      var spy = sinon.spy(pl.current_scene, 'reload_entity')
      pl.update();
      sinon.assert.calledWith(spy, pl);
    });
  });

  describe("#refresh", function(){
    it("invokes update method with self", function(){
      var spy = sinon.spy(pl, 'update');
      pl.refresh();
      sinon.assert.calledWith(spy, pl);
    });
  })

  it("sets planet orbit properties", function(){
    assert(pl.a).equals(10);
    assert(pl.b).equals(10);
    assert(pl.le).equals(0);
    assert(pl.cx).equals(0);
    assert(pl.cy).equals(0);
    assert(pl.cz).equals(0);
    assert(roundTo(pl.rot_axis_angle, 2)).equals(1.57);
    assert(pl.rot_axis).isSameAs([1,0,0]);
  });

  describe("added to scene", function(){
    it("sets current scene", function(){
      var scene = new Scene();
      pl.added_to(scene)
      assert(pl.current_scene).equals(scene);
    });
  });

  describe("removed from scene", function(){
    it("sets current scene to null", function(){
      var scene = new Scene();
      pl.added_to(scene)
      pl.removed_from(scene);
      assert(pl.current_scene).equals(null);
    });
  });

  describe("#planet_movement_cycle", function(){
    var pl1, pl2;

    before(function(){
      disable_three_js();
      pl1 = new Planet({location : { movement_strategy : {} }});
      pl2 = new Planet({location : { movement_strategy : {} }});
    })

    after(function(){
      if(Entities().select.restore) Entities().select.restore();
    })

    it("retrieves planets", function(){ // TODO only in current scene
      var spy = sinon.spy(Entities(), 'select');
      _planet_movement_cycle();
      sinon.assert.calledWith(spy,
        sinon.match.func_domain(false, {json_class : 'Cosmos::Entities::Star'}).and(
        sinon.match.func_domain(true,  {json_class : 'Cosmos::Entities::Planet'})));
    });

    it("moves planets", function(){
      sinon.stub(Entities(), 'select').returns([pl1])
      pl1.last_moved = new Date() - 1000;
      pl1.location.x = pl1.location.y = 0 ; pl1.location.z = 10;
      pl1.cx = pl1.cy = pl1.cz = 0
      pl1.rot_axis_angle = 0;
      pl1.rot_axis = [1, 0, 0]
      pl1.a = 10 ; pl1.b = 10
      pl1.location.movement_strategy.speed = -1.57

      _planet_movement_cycle();
      assert(roundTo(pl1.location.x,2)).equals(10);
      assert(roundTo(pl1.location.y,2)).equals(0.01);
      assert(pl1.location.z).equals(0);
    });

    it("refreshes planets", function(){
      var spy1 = sinon.spy(pl1, 'refresh')
      var spy2 = sinon.spy(pl2, 'refresh')
      sinon.stub(Entities(), 'select').returns([pl1, pl2])
      pl1.last_moved = pl2.last_moved = new Date();
      _planet_movement_cycle();
      sinon.assert.called(spy1);
      sinon.assert.called(spy2);
    });

    it("sets last movement on planet", function(){
      sinon.stub(Entities(), 'select').returns([pl1, pl2])
      _planet_movement_cycle();
      assert(pl1.last_moved).isNotNull();
      // TODO verify date
    });
  })
});}); // Planet

pavlov.specify("Asteroid", function(){
describe("Asteroid", function(){
  var ast;

  before(function(){
    disable_three_js();
    ast = new Asteroid({location : { id : 42 }})
  })

  it("converts location", function(){
    assert(ast.location).isTypeOf(Location)
  })
});}); // Asteroid

pavlov.specify("JumpGate", function(){
describe("JumpGate", function(){
  var jg;

  before(function(){
    disable_three_js();
    jg = new JumpGate({location : { id : 42 }})
  })

  it("converts location", function(){
    assert(jg.location).isTypeOf(Location)
  })

  describe("added to scene", function(){
    it("sets current scene", function(){
      var scene = new Scene();
      jg.added_to(scene)
      assert(jg.current_scene).equals(scene);
    });
  });

  describe("removed from scene", function(){
    it("sets current scene to null", function(){
      var scene = new Scene();
      jg.added_to(scene)
      jg.removed_from(scene);
      assert(jg.current_scene).equals(null);
    });
  });

  describe("clicked jump gate", function(){
    var trigger_cmd = '#cmd_trigger_jg';

    before(function(){
      $(document).die();
    })

    after(function(){
      $(document).die();
    })

    it("sets selected true", function(){
      var scene = new Scene();
      jg.clicked_in(scene);
      assert(jg.selected).equals(true);
    });

    it("refreshes jump gate command callback", function(){
      var cb = function(){};
      $(trigger_cmd).live('click', cb);

      var scene = new Scene();
      jg.clicked_in(scene);
      var events = $.data(document, 'events')['click'];
      assert(events.length).equals(1);
      assert(events[0].selector).equals(trigger_cmd);
      assert(events[0]).isNotEqualTo(cb);
    });

    describe("command trigger jump gate", function(){
      after(function(){
        if(Commands.trigger_jump_gate.restore)
          Commands.trigger_jump_gate.restore();
      })

      it("invokes trigger jump gate command", function(){
        var scene = new Scene();
        jg.clicked_in(scene);

        var spy = sinon.spy(Commands, 'trigger_jump_gate');

        var cb = $.data(document, 'events')['click'][0];
        cb.handler.apply(null, []);
        sinon.assert.called(spy);
      });
    });

    it("reloads jump gate in scene", function(){
      var scene = new Scene();
      var spy = sinon.spy(scene, 'reload_entity')
      jg.clicked_in(scene);
      sinon.assert.calledWith(spy, jg);
    });
  })

  describe("unselect jump gate", function(){
    it("sets selected to false", function(){
      var scene = new Scene();
      jg.selected = true
      jg.unselected_in(scene);
      assert(jg.selected).equals(false);
    });

    it("reloads jump gate in scene", function(){
      var scene = new Scene();
      var spy = sinon.spy(scene, 'reload_entity');
      jg.unselected_in(scene);
      sinon.assert.calledWith(spy, jg);
    });
  });
});}); // JumpGate

pavlov.specify("Ship", function(){
describe("Ship", function(){
  var sh;

  before(function(){
    disable_three_js();
    Entities().node(new TestNode());

    sh = new Ship({location : { id : 42 }});
  })

  after(function(){
    if(Entities().node().web_request.restore) Entities().node().web_request.restore();
  })

  it("converts location", function(){
    assert(sh.location).isTypeOf(Location)
  });

  describe("#resolve_mining_target", function(){
    it("retrieves mining target from local registry", function(){
      var ast1 = new Asteroid({id : 'ast1'});
      var ast2 = new Asteroid({id : 'ast2'});
      var sys  = new SolarSystem({children : [ast1, ast2]});

      Entities().set('system1', sys);
      var mt = _ship_resolve_mining_target('system1', {entity_id : 'ast1'});
      assert(mt).isSameAs(ast1);
    });
  })

  //describe("#resolve_attack_target", function(){
    //it("resolves attack target from local registry") // NIY (also in code)
  //})

  //describe("#resolve_defense_target", function(){
    //it("resolves defense target from local registry") // NIY (also in code)
  //})

  describe("#update", function(){
    it("updates attributes", function(){
      var spy = sinon.spy(sh, 'old_update')
      sh.update({ id : 'sh2'});
      sinon.assert.calledWith(spy, {id : 'sh2'});
    });

    it("updates location", function(){
      var spy = sinon.spy(sh.location, 'update');
      var l = {id : 'loc1'}
      sh.update({location : l})
      sinon.assert.calledWith(spy, l)
    });

    it("updates location movement strategy", function(){
      var l = {id : 'loc1', movement_strategy : 'ms'}
      sh.update({location : l})
      assert(sh.location.movement_strategy).equals('ms')
    });

    it("reloads entity in scene", function(){
      sh.current_scene = new Scene();
      var spy = sinon.spy(sh.current_scene, 'reload_entity')
      sh.update();
      sinon.assert.calledWith(spy, sh);
      // TODO ensure scene components marked to to be removed actually are
    });
  })

  describe("#refresh", function(){
    it("invokes update method with self", function(){
      var spy = sinon.spy(sh, 'update');
      sh.refresh();
      sinon.assert.calledWith(spy, sh);
    });
  })

  describe("#belongs_to_user", function(){
    describe("user_id is same as specified user's", function(){
      it("returns true", function(){
        sh.user_id = 'test';
        assert(sh.belongs_to_user('test')).isTrue();
      })
    })
    describe("user_id is not same as specified user's", function(){
      it("returns false", function(){
        sh.user_id = 'foobar';
        assert(sh.belongs_to_user('test')).isFalse();
      })
    })
  });

  describe("#belongs_to_current_user", function(){
    after(function(){
      Session.current_session = null;
    })

    describe("current session is null", function(){
      it("returns false", function(){
        Session.current_session = null;
        assert(sh.belongs_to_current_user()).isFalse();
      });
    });

    describe("user_id is same as current user's", function(){
      it("returns true", function(){
        sh.user_id = 'test';
        Session.current_session = { user_id : 'test' }
        assert(sh.belongs_to_current_user()).isTrue();
      })
    })
    describe("user_id is not same as current user's", function(){
      it("returns false", function(){
        sh.user_id = 'test';
        Session.current_session = { user_id : 'foobar' }
        assert(sh.belongs_to_current_user()).isFalse();
      })
    })
  });

  describe("ship clicked in scene", function(){
    var cmds = ['#cmd_move_select', '#cmd_attack_select', '#cmd_dock_select',
                '#cmd_mine_select', '#cmd_move', '.cmd_attack', '.cmd_dock',
                '#cmd_undock', '#cmd_transfer', '.cmd_mine'];

    before(function(){
      $(document).die();
    })

    after(function(){
      $(document).die();
    })

    it("refreshes ship ui command callbacks", function(){
      var cb = function(){};
      $(cmds).live('click', cb);

      var scene = new Scene();
      sh.clicked_in(scene);

      var events = $.data(document, 'events')['click'];
      assert(events.length).equals(7); //XXX some are grouped

      var selectors = [];
      for(var i = 0; i < events.length; i++){
        var sselectors = events[i].selector.split(',');
        for(var j = 0; j < sselectors.length; j++)
          selectors.push(sselectors[j]);
        assert(events[i].handler).isNotEqualTo(cb);
      }

      for(var i = 0; i < cmds.length; i++){
        assert(selectors).includes(cmds[i])
      }
    });

    describe("cmd_move_select", function(){
      it("raises event", function(){
        var scene = new Scene();
        sh.clicked_in(scene);

        var mcb  = sinon.spy();
        sh.on('cmd_move_select',   mcb);

        $('#qunit-fixture').append('<div id="cmd_move_select"></div>');
        $('#cmd_move_select').trigger('click')

        // TODO verify dialog contents
        sinon.assert.calledWith(mcb,  sh, sh, 'Move Ship',     sinon.match.string);
      });
    });

    describe("cmd_attack_select", function(){
      it("raises event", function(){
        var scene = new Scene();
        sh.clicked_in(scene);

        var acb  = sinon.spy();
        sh.on('cmd_attack_select', acb);

        $('#qunit-fixture').append('<div id="cmd_attack_select"></div>');
        $('#cmd_attack_select').trigger('click')
        sinon.assert.calledWith(acb,  sh, sh, 'Launch Attack', sinon.match.string);
      });
    });

    describe("cmd_dock_select", function(){
      it("raises event", function(){
        var scene = new Scene();
        sh.clicked_in(scene);

        var dcb  = sinon.spy();
        sh.on('cmd_dock_select',   dcb);

        $('#qunit-fixture').append('<div id="cmd_dock_select"></div>');
        $('#cmd_dock_select').trigger('click')
        sinon.assert.calledWith(dcb,  sh, sh, 'Dock Ship',     sinon.match.string);
      });
    });

    describe("cmd_mine_select", function(){
      it("raises event", function(){
        var scene = new Scene();
        sh.clicked_in(scene);

        var micb = sinon.spy();
        sh.on('cmd_mine_select',   micb);

        $('#qunit-fixture').append('<div id="cmd_mine_select"></div>');
        $('#cmd_mine_select').trigger('click')
        sinon.assert.calledWith(micb, sh, sh, 'Start Mining',  sinon.match.string);
      });
    });

    describe("cmd_move", function(){
      after(function(){
        Commands.move_ship.restore();
      })

      it("moves ship", function(){
        var scene = new Scene();
        sh.clicked_in(scene);

        Commands.move_ship = sinon.spy(Commands, 'move_ship');
        $('#qunit-fixture').append('<div id="cmd_move"></div>');
        $('#qunit-fixture').append('<input id="dest_x" type="text" value="100"></input>');
        $('#qunit-fixture').append('<input id="dest_y" type="text" value="200"></input>');
        $('#qunit-fixture').append('<input id="dest_z" type="text" value="300"></input>')
        $('#cmd_move').trigger('click')
        sinon.assert.calledWith(Commands.move_ship, sh, "100", "200", "300", sinon.match.func)
      });

      it("raises cmd_move event", function(){
        var scene = new Scene();
        sh.clicked_in(scene);

        Commands.move_ship = sinon.spy(Commands, 'move_ship');
        $('#qunit-fixture').append('<div id="cmd_move">');
        $('#cmd_move').trigger('click')
        var cb = Commands.move_ship.getCall(0).args[4];

        var spy = sinon.spy();
        sh.on('cmd_move', spy)
        cb.apply(null);
        sinon.assert.calledWith(spy, sh, sh)
      })
    });

    describe("cmd_attack", function(){
      after(function(){
        Commands.launch_attack.restore();
      })

      it("launches attack", function(){
        var scene = new Scene();
        sh.clicked_in(scene);

        Commands.launch_attack = sinon.spy(Commands, 'launch_attack');
        $('#qunit-fixture').append('<div id="cmd_attack_foobar" class="cmd_attack"></div>');
        var target = {};
        Entities().set('foobar', target)

        $('#cmd_attack_foobar').trigger('click')
        sinon.assert.calledWith(Commands.launch_attack, sh, target, sinon.match.func);
      });

      it("raises cmd_attack event", function(){
        var scene = new Scene();
        sh.clicked_in(scene);

        Commands.launch_attack = sinon.spy(Commands, 'launch_attack');
        $('#qunit-fixture').append('<div id="cmd_attack_foobar" class="cmd_attack"></div>');
        var target = {};
        Entities().set('foobar', target)
        $('#cmd_attack_foobar').trigger('click')
        var cb = Commands.launch_attack.getCall(0).args[2];

        var spy = sinon.spy();
        sh.on('cmd_attack', spy)
        cb.apply(null);
        sinon.assert.calledWith(spy, sh, sh, target)
      })
    });

    describe("cmd_dock", function(){
      var station;

      before(function(){
        var scene = new Scene();
        sh.clicked_in(scene);

        Commands.dock_ship = sinon.spy(Commands, 'dock_ship');
        $('#qunit-fixture').append('<div id="cmd_dock_foobar" class="cmd_dock"></div>');
        $('#qunit-fixture').append('<div id="cmd_dock_select"></div>');
        $('#qunit-fixture').append('<div id="cmd_undock" style="display: none"></div>');
        $('#qunit-fixture').append('<div id="cmd_transfer" style="display: none"></div>');
        station = {};
        Entities().set('foobar', station)
      })

      after(function(){
        Commands.dock_ship.restore();
      })

      it("docks ship", function(){
        $('#cmd_dock_foobar').trigger('click')
        sinon.assert.calledWith(Commands.dock_ship, sh, station, sinon.match.func);
      });

      it("hides dock selection dialog", function(){
        $('#cmd_dock_foobar').trigger('click')
        ok(!$('#cmd_dock_select').is(':visible'));
      })

      it("shows undock cmd", function(){
        $('#cmd_dock_foobar').trigger('click')
        ok($('#cmd_undock').is(':visible'));
      })

      it("shows transfer cmd", function(){
        $('#cmd_dock_foobar').trigger('click')
        ok($('#cmd_transfer').is(':visible'));
      })

      it("updates ship", function(){
        $('#cmd_dock_foobar').trigger('click')
        var cb = Commands.dock_ship.getCall(0).args[2];
        var spy = sinon.spy(sh, 'update');
        var res = {};
        cb.apply(null, [{result : res}]);
        sinon.assert.calledWith(spy, res);
      });

      it("raises cmd_dock event", function(){
        $('#cmd_dock_foobar').trigger('click')
        var cb = Commands.dock_ship.getCall(0).args[2];
        var spy = sinon.spy();
        sh.on('cmd_dock', spy)
        var res = {};
        cb.apply(null, [{result : res}]);
        sinon.assert.calledWith(spy, sh, sh, res)
      })
    });

    describe("cmd_undock", function(){
      var station;

      before(function(){
        var scene = new Scene();
        sh.clicked_in(scene);

        Commands.undock_ship = sinon.spy(Commands, 'undock_ship');
        $('#qunit-fixture').append('<div id="cmd_dock_select" style="display: none"></div>');
        $('#qunit-fixture').append('<div id="cmd_undock"></div>');
        $('#qunit-fixture').append('<div id="cmd_transfer"></div>');
      })

      after(function(){
        Commands.undock_ship.restore();
      })

      it("undocks ship", function(){
        $('#cmd_undock').trigger('click')
        sinon.assert.calledWith(Commands.undock_ship, sh, sinon.match.func);
      });

      it("shows dock selection cmd", function(){
        $('#cmd_undock').trigger('click')
        ok($('#cmd_dock_select').is(':visible'));
      })

      it("hides undock cmd", function(){
        $('#cmd_undock').trigger('click')
        ok(!$('#cmd_undock').is(':visible'));
      })

      it("shows transfer cmd", function(){
        $('#cmd_undock').trigger('click')
        ok(!$('#cmd_transfer').is(':visible'));
      })

      it("updates ship", function(){
        $('#cmd_undock').trigger('click')
        var cb = Commands.undock_ship.getCall(0).args[1];
        var spy = sinon.spy(sh, 'update');
        var res = {};
        cb.apply(null, [{result : res}]);
        sinon.assert.calledWith(spy, res);
      })

      it("raises cmd_undock event", function(){
        $('#cmd_undock').trigger('click')
        var cb = Commands.undock_ship.getCall(0).args[1];
        var spy = sinon.spy();
        sh.on('cmd_undock', spy)
        var res = {};
        cb.apply(null, [{result : res}]);
        sinon.assert.calledWith(spy, sh, sh);
      });
    });

    describe("cmd_transfer", function(){
      before(function(){
        var scene = new Scene();
        sh.clicked_in(scene);
        sh.docked_at = {id : 'foobar'}
        sh.resources = [];

        Commands.transfer_resources = sinon.spy(Commands, 'transfer_resources');
        $('#qunit-fixture').append('<div id="cmd_transfer"></div>');
      })

      after(function(){
        Commands.transfer_resources.restore();
      })

      it("transfers resources", function(){
        $('#cmd_transfer').trigger('click')
        sinon.assert.calledWith(Commands.transfer_resources,
                                sh, 'foobar', sinon.match.func);
      })

      it("raises cmd_transfer event", function(){
        $('#cmd_transfer').trigger('click')
        var cb = Commands.transfer_resources.getCall(0).args[2];
        var spy = sinon.spy();
        sh.on('cmd_transfer', spy)
        var res = [{}, {}]
        cb.apply(null, [{result : res}]);
        sinon.assert.calledWith(spy, sh, res[0], res[1]);
      });
    });

    describe("cmd_mine", function(){
      before(function(){
        var scene = new Scene();
        sh.clicked_in(scene);

        Commands.start_mining = sinon.spy(Commands, 'start_mining');
        $('#qunit-fixture').append('<div id="cmd_mine_foobar" class="cmd_mine"></div>');
      })

      after(function(){
        Commands.start_mining.restore();
      })

      it("starts mining", function(){
        $('#cmd_mine_foobar').trigger('click')
        sinon.assert.calledWith(Commands.start_mining,
                                sh, 'foobar', sinon.match.func);
      })

      it("raises cmd_mine event", function(){
        $('#cmd_mine_foobar').trigger('click')
        var cb = Commands.start_mining.getCall(0).args[2];
        var spy = sinon.spy();
        sh.on('cmd_mine', spy)
        cb.apply(null, []);
        sinon.assert.calledWith(spy, sh, sh, 'foobar');
      });
    });

    it("sets selected true", function(){
        var scene = new Scene();
        sh.clicked_in(scene);
        assert(sh.selected).equals(true);
    });

    it("refreshes entity", function(){
      var spy1 = sinon.spy(sh, 'refresh')
      var scene = new Scene();
      sh.clicked_in(scene);
      sinon.assert.called(spy1);
    });

    it("reloads entity in scene", function(){
      sh.current_scene = new Scene();
      var spy = sinon.spy(sh.current_scene, 'reload_entity')
      sh.update();
      sinon.assert.calledWith(spy, sh);
    });
  });

  describe("ship unselected", function(){
    it("sets selected to false", function(){
      var scene = new Scene();
      sh.selected = true
      sh.unselected_in(scene);
      assert(sh.selected).equals(false);
    });

    it("refreshes entity", function(){
      var spy1 = sinon.spy(sh, 'refresh')
      var scene = new Scene();
      sh.current_scene = scene;
      sh.unselected_in(scene);
      sinon.assert.called(spy1);
    });

    it("reloads entity in scene", function(){
      sh.current_scene = new Scene();
      var spy = sinon.spy(sh.current_scene, 'reload_entity')
      sh.update();
      sinon.assert.calledWith(spy, sh);
    });
  });

  describe("#with_id", function(){
    it("invokes manufactured::get_entity", function(){
      var spy = sinon.spy(Entities().node(), 'web_request')
      Ship.with_id('sh1')
      sinon.assert.calledWith(spy, 'manufactured::get_entity', 'with_id', 'sh1')
    })

    describe("successful get_entity response", function(){
      var cb; var res;
      var handler;

      before(function(){
        var spy = sinon.spy(Entities().node(), 'web_request')
        handler = sinon.spy();
        Ship.with_id('sh1', handler)
        cb  = spy.getCall(0).args[3];
        res = {result : {json_class : 'Manufactured::Ship', id : 'sh1'}}
      })

      it("invokes callback with new ship", function(){
        cb.apply(null, [res]);
        sinon.assert.calledWith(handler,
                                sinon.match.instanceOf(Ship).and(
                                sinon.match.has('id', 'sh1')))
      })
    })
  })

  describe("#owned_by", function(){
    it("invokes manufactured::get_entities", function(){
      var spy = sinon.spy(Entities().node(), 'web_request')
      Ship.owned_by('user1')
      sinon.assert.calledWith(spy, 'manufactured::get_entities',
                                   'of_type', 'Manufactured::Ship',
                                   'owned_by', 'user1')
    })

    describe("successful get_entities response", function(){
      var cb; var res;
      var handler;

      before(function(){
        var spy = sinon.spy(Entities().node(), 'web_request')
        handler = sinon.spy();
        Ship.owned_by('user', handler)
        cb  = spy.getCall(0).args[5];
        res = {result : [{json_class : 'Manufactured::Ship', id : 'sh1'}]}
      })

      it("invokes callback with ships", function(){
        cb.apply(null, [res]);
        sinon.assert.calledWith(handler, sinon.match.array)
        r = handler.getCall(0).args[0]
        assert(r.length).equals(1)
        assert(r[0]).isTypeOf(Ship);
        assert(r[0].id).equals('sh1')
      })
    })
  })

  describe("#ship_movement_cycle", function(){
    var sh1, sh2;

    before(function(){
      disable_three_js();
      sh1 = new Ship({location : { movement_strategy : {} }});
      sh2 = new Ship({location : { movement_strategy : {} }});
    })

    after(function(){
      if(Entities().select.restore) Entities().select.restore();
    })

    it("retrieves ship", function(){ // TODO only in current scene
      var spy = sinon.spy(Entities(), 'select');
      _ship_movement_cycle();
      sinon.assert.calledWith(spy,
        sinon.match.func_domain(false, {json_class : 'Manufactured::Station'}).and(
        sinon.match.func_domain(true,  {json_class : 'Manufactured::Ship'})));
    });

    it("moves ships", function(){
      sh1.last_moved = new Date() - 1000;
      sh1.location.movement_strategy =
        {json_class : 'Motel::MovementStrategies::Linear',
         speed      : 10,
         dx : 1, dy : 0, dz : 0}
      sh1.location.x = sh1.location.y = sh1.location.z = 0;
      sinon.stub(Entities(), 'select').returns([sh1])
      _ship_movement_cycle();
      assert(sh1.location.x).equals(10);
      assert(sh1.location.y).equals(0);
      assert(sh1.location.z).equals(0);
    });

    it("rotates ships", function(){
      sh2.last_moved = new Date() - 1000;
      sh2.location.orientation_x = 1;
      sh2.location.orientation_y = 0;
      sh2.location.orientation_z = 0;
      sh2.location.movement_strategy =
        {json_class : 'Motel::MovementStrategies::Rotate',
         speed      : 1.57,
         rot_x : 0, rot_y : 0, rot_z : 1, rot_theta : 1.57};

      sinon.stub(Entities(), 'select').returns([sh2])
      _ship_movement_cycle();
      assert(roundTo(sh2.location.orientation_x,2)).equals(0);
      assert(roundTo(sh2.location.orientation_y,2)).equals(1);
      assert(sh2.location.orientation_z).equals(0);
    });

    it("sets last movement on ship", function(){
      sh1.location.movement_strategy.json_class = 'Motel::MovementStrategies::Linear';
      sh2.location.movement_strategy.json_class = 'Motel::MovementStrategies::Rotate';
      sinon.stub(Entities(), 'select').returns([sh1, sh1])
      _ship_movement_cycle();
      assert(sh1.last_moved).isNotNull();
      assert(sh2.last_moved).isNotNull();
      // TODO verify date
    })
  })
});}); // Ship

pavlov.specify("Station", function(){
describe("Station", function(){
  var st;

  before(function(){
    disable_three_js();
    Entities().node(new TestNode());

    st = new Station({location : { id : 42 }});
  })

  after(function(){
    if(Entities().node().web_request.restore) Entities().node().web_request.restore();
  })

  it("converts location", function(){
    assert(st.location).isTypeOf(Location)
  });

  describe("#belongs_to_user", function(){
    describe("user_id is same as specified user's", function(){
      it("returns true", function(){
        st.user_id = 'test';
        assert(st.belongs_to_user('test')).isTrue();
      })
    })
    describe("user_id is not same as specified user's", function(){
      it("returns false", function(){
        st.user_id = 'foobar';
        assert(st.belongs_to_user('test')).isFalse();
      })
    })
  });

  describe("#belongs_to_current_user", function(){
    after(function(){
      Session.current_session = null;
    })

    describe("user_id is same as current user's", function(){
      it("returns true", function(){
        st.user_id = 'test';
        Session.current_session = { user_id : 'test' }
        assert(st.belongs_to_current_user()).isTrue();
      })
    })
    describe("user_id is not same as current user's", function(){
      it("returns false", function(){
        st.user_id = 'test';
        Session.current_session = { user_id : 'foobar' }
        assert(st.belongs_to_current_user()).isFalse();
      })
    })
  });

  describe("station clicked in scene", function(){
    var construct_cmd = '#cmd_construct';

    before(function(){
      $(document).die();
    })

    after(function(){
      $(document).die();
    })

    it("refreshes station ui command callbacks", function(){
      var cb = function(){};
      $(construct_cmd).live('click', cb);

      var scene = new Scene();
      st.clicked_in(scene);
      var events = $.data(document, 'events')['click'];
      assert(events.length).equals(1);
      assert(events[0].selector).equals(construct_cmd);
      assert(events[0]).isNotEqualTo(cb);
    });

    describe("cmd_construct", function(){
      before(function(){
        var scene = new Scene();
        st.clicked_in(scene);

        Commands.construct_entity = sinon.spy(Commands, 'construct_entity');
        $('#qunit-fixture').append('<div id="cmd_construct"></div>');
      })

      after(function(){
        Commands.construct_entity.restore();
      })

      it("starts construction", function(){
        $('#cmd_construct').trigger('click')
        sinon.assert.calledWith(Commands.construct_entity,
                                st, sinon.match.func);
      })

      it("raises cmd_mine event", function(){
        $('#cmd_construct').trigger('click')
        var cb = Commands.construct_entity.getCall(0).args[1];
        var spy = sinon.spy();
        st.on('cmd_construct', spy)
        var nsh = {};
        cb.apply(null, [{result: [{},nsh]}]);
        sinon.assert.calledWith(spy, st); // TODO verify also called w/ new ship
      });
    });

    it("sets selected true", function(){
      var scene = new Scene();
      st.clicked_in(scene);
      assert(st.selected).equals(true);
    });

    it("reloads entity in scene", function(){
      var scene = new Scene();
      var spy = sinon.spy(scene, 'reload_entity')
      st.clicked_in(scene);
      sinon.assert.calledWith(spy, st);
    });
  });

  describe("station unselected", function(){
    it("sets selected to false", function(){
      var scene = new Scene();
      st.selected = true
      st.unselected_in(scene);
      assert(st.selected).equals(false);
    });

    it("reloads entity in scene", function(){
      var scene = new Scene();
      var spy = sinon.spy(scene, 'reload_entity');
      st.unselected_in(scene);
      sinon.assert.calledWith(spy, st);
    });
  });

  describe("#owned_by", function(){
    it("invokes manufactured::get_entities", function(){
      var spy = sinon.spy(Entities().node(), 'web_request')
      Station.owned_by('user1')
      sinon.assert.calledWith(spy, 'manufactured::get_entities',
                                   'of_type', 'Manufactured::Station',
                                   'owned_by', 'user1')
    })

    describe("successful get_entities response", function(){
      var cb; var res;
      var handler;

      before(function(){
        var spy = sinon.spy(Entities().node(), 'web_request')
        handler = sinon.spy();
        Station.owned_by('user', handler)
        cb  = spy.getCall(0).args[5];
        res = {result : [{json_class : 'Manufactured::Station', id : 'st1'}]}
      })

      it("invokes callback with stations", function(){
        cb.apply(null, [res]);
        sinon.assert.calledWith(handler, sinon.match.array)
        r = handler.getCall(0).args[0]
        assert(r.length).equals(1)
        assert(r[0]).isTypeOf(Station);
        assert(r[0].id).equals('st1')
      })
    })
  })
});}); // Station

pavlov.specify("Mission", function(){
describe("Mission", function(){
  before(function(){
    Entities().node(new TestNode());
  })

  after(function(){
    if(Entities().node().web_request.restore) Entities().node().web_request.restore();
  })

  describe("#expires", function(){
    it("returns Date which mission expires at", function(){
      var m = new Mission({timeout : 30,
                           assigned_time :  "2013-07-03 01:58:08"})
      assert(m.expires().toString()).equals(new Date(Date.parse("2013/07/03 01:58:38")).toString());
    })
  })

  describe("#expired", function(){
    describe("mission expired", function(){
      it("returns true", function(){
        var m = new Mission({timeout : 30,
                             assigned_time :  "1900-07-03 01:58:08"});
        assert(m.expired()).isTrue();
      })
    });
    describe("mission not expired", function(){
      it("returns false", function(){
        var m = new Mission();
        assert(m.expired()).isFalse();
      })
    });
  })

  describe("#assigned_to_user", function(){
    describe("assigned_to_id is same as specified user's", function(){
      it("returns true", function(){
        var m = new Mission({assigned_to_id : 'test'})
        assert(m.assigned_to_user('test')).isTrue();
      })
    })
    describe("assigned_to_id is not same as specified user's", function(){
      it("returns false", function(){
        var m = new Mission({assigned_to_id : 'test'})
        assert(m.assigned_to_user('foobar')).isFalse();
      })
    })
  });

  describe("#assigned_to_current_user", function(){
    after(function(){
      Session.current_session = null;
    })

    describe("assigned_to_id is same as current user's", function(){
      it("returns true", function(){
        Session.current_session = { user_id : 'test' }
        var m = new Mission({assigned_to_id : 'test'})
        assert(m.assigned_to_current_user()).isTrue();
      })
    })
    describe("assigned_to_id is not same as current user's", function(){
      it("returns false", function(){
        Session.current_session = { user_id : 'test' }
        var m = new Mission({assigned_to_id : 'foobar'})
        assert(m.assigned_to_current_user()).isFalse();
      })
    })
  });

  describe("#all", function(){
    it("invokes missions::get_missions", function(){
      var spy = sinon.spy(Entities().node(), 'web_request')
      Mission.all(function(){})
      sinon.assert.calledWith(spy, 'missions::get_missions')
    })

    describe("successful mission retrieval", function(){
      var cb; var res;
      var handler;

      before(function(){
        var spy = sinon.spy(Entities().node(), 'web_request')
        handler = sinon.spy();
        Mission.all(handler)
        cb  = spy.getCall(0).args[1];
        res = {result : [{json_class : 'Missions::Mission', id : 'ms1'},
                         {json_class : 'Missions::Mission', id : 'ms2' }]}
      })

      it("invokes callback with missions", function(){
        cb.apply(null, [res]);
        sinon.assert.calledWith(handler, sinon.match.array)
        r = handler.getCall(0).args[0]
        assert(r[0]).isTypeOf(Mission);
        assert(r[0].id).equals('ms1')
        assert(r[1]).isTypeOf(Mission);
        assert(r[1].id).equals('ms2')
      })
    })

  })
});}); // Mission

pavlov.specify("Statistic", function(){
describe("Statistic", function(){
  before(function(){
    Entities().node(new TestNode());
  });

  after(function(){
    if(Entities().node().web_request.restore) Entities().node().web_request.restore();
  });

  describe("#with_id", function(){
    it("invokes stats::get", function(){
      var spy = sinon.spy(Entities().node(), 'web_request')
      Statistic.with_id('stat1', 42, function() {})
      sinon.assert.calledWith(spy, 'stats::get', 'stat1', 42)
    })

    describe("successful get response", function(){
      var cb; var res;
      var handler;

      before(function(){
        var spy = sinon.spy(Entities().node(), 'web_request')
        handler = sinon.spy();
        Statistic.with_id('stat1', 42, handler)
        cb  = spy.getCall(0).args[3];
        res = {result : {json_class : 'Stats::StatResult', id : 'stat1'}}
      })

      it("invokes callback with stat", function(){
        cb.apply(null, [res]);
        sinon.assert.calledWith(handler,
                                sinon.match.instanceOf(Statistic).and(
                                sinon.match.has('id', 'stat1')))
      })
    })
  })
});}); // Statistic
