pavlov.specify("Omega.Ship", function(){
describe("Omega.Ship", function(){
  var ship;

  before(function(){
    ship = Omega.Gen.ship();
  });

  it("sets parent_id = to system_id", function(){
    var ship = new Omega.Ship({system_id : 'system1'});
    assert(ship.parent_id).equals('system1');
  });

  it("converts location", function(){
    var ship = new Omega.Ship({location : {json_class: 'Motel::Location', y : -42}});
    assert(ship.location).isOfType(Omega.Location);
    assert(ship.location.y).equals(-42);
  });

  //it("updates resources"); /// NIY test update_resources is invoked

  describe("#update", function(){
    var from;

    before(function(){
      from = Omega.Gen.ship();
    });

    it("updates ship hp", function(){
      ship.update(from);
      assert(ship.hp).equals(from.hp);
    });

    it("updates ship shield level", function(){
      ship.update(from);
      assert(ship.shield_level).equals(from.shield_level);
    });

    it("updates ship distance moved", function(){
      ship.update(from);
      assert(ship.distance_moved).equals(from.distance_moved);
    });

    it("updates ship docked_at_id", function(){
      ship.update(from);
      assert(ship.docked_at_id).equals(from.docked_at);
    });

    it("updates ship attacking_id", function(){
      ship.update(from);
      assert(ship.attacking_id).equals(from.attacking_id);
    });

    it("updates ship mining", function(){
      ship.update(from);
      assert(ship.mining).equals(from.mining);
    });

    it("updates ship resources", function(){
      ship.update(from);
      assert(ship.resources).equals(from.resources);
    });

    it("updates ship system_id/parent_id", function(){
      ship.update(from);
      assert(ship.system_id).equals(from.system_id);
      assert(ship.parent_id).equals(from.parent_id);
    });

    it("updates ship location", function(){
      sinon.spy(ship.location, 'update');
      ship.update(from);
      sinon.assert.calledWith(ship.location.update, from.location);
    });
  });

  describe("#clone", function(){
    it("returns cloned copy of ship", function(){
      var cloned = ship.clone();
      assert(cloned).isSameAs(ship);
    });
  });

  describe("#belongs_to_user", function(){
    it("returns bool indicating if ship belongs to user", function(){
      ship.user_id = 'user1';
      assert(ship.belongs_to_user('user1')).isTrue();
      assert(ship.belongs_to_user('user2')).isFalse();
    });
  });

  describe("#alive", function(){
    describe("ship hp > 0", function(){
      it("returns true", function(){
        var ship = new Omega.Ship({hp:42});
        assert(ship.alive()).isTrue();
      });
    });

    describe("ship hp == 0", function(){
      it("returns false", function(){
        var ship = new Omega.Ship({hp:0});
        assert(ship.alive()).isFalse();
      });
    });
  });

  describe("#hpp", function(){
    it("returns hp percentage", function(){
      ship.hp = 5;
      ship.max_hp = 10;
      assert(ship.hpp()).equals(0.5);
    });
  });

  describe("#is_mining", function(){
    describe("ship is mining", function(){
      it("returns true", function(){
        ship.mining = {};
        ship.mining_asteroid = {};
        assert(ship.is_mining()).isTrue();
      });
    });

    describe("ship is not mining", function(){
      it("returns false", function(){
        assert(ship.is_mining()).isFalse();
      });
    });
  });

  describe("update_system", function(){
    it("sets solar_system", function(){
      var sh = new Omega.Ship();
      var sys = new Omega.SolarSystem({id : 'sys1'});
      sh.update_system(sys);
      assert(sh.solar_system).equals(sys);
    });

    it("sets system_id", function(){
      var sh = new Omega.Ship();
      var sys = new Omega.SolarSystem({id : 'sys1'});
      sh.update_system(sys);
      assert(sh.system_id).equals(sys.id);
    });

    it("sets parent_id", function(){
      var sh = new Omega.Ship();
      var sys = new Omega.SolarSystem({id : 'sys1'});
      sh.update_system(sys);
      assert(sh.parent_id).equals(sys.id);
    });
  });

  describe("#in_system", function(){
    var sh, sys;
    before(function(){
      sh  = new Omega.Ship();
      sys = new Omega.SolarSystem({id : 'sys1'});
      sh.update_system(sys);
    });

    describe("ship is in system", function(){
      it("returns true", function(){
        assert(sh.in_system(sys.id)).isTrue();
      });
    });

    describe("ship is not in system", function(){
      it("returns false", function(){
        assert(sh.in_system('foobar')).isFalse();
      });
    });
  });

  describe("#_update_resources", function(){
    it("converts resources from json data", function(){
      var ship = new Omega.Ship({resources : [{data : {material_id : 'steel'}},
                                              {data : {material_id : 'plastic'}}]});
      assert(ship.resources.length).equals(2);
      assert(ship.resources[0].material_id).equals('steel');
      assert(ship.resources[1].material_id).equals('plastic');
    });
  });

  describe("#clicked_in", function(){
    var canvas;

    before(function(){
      canvas = new Omega.UI.Canvas({page : new Omega.Pages.Test()});
      sinon.stub(canvas.page.audio_controls, 'play');
      sinon.stub(canvas, 'follow_entity');
    });

    it("plays clicked audio effect", function(){
      var ship = new Omega.Ship();
      ship.clicked_in(canvas);
      sinon.assert.calledWith(canvas.page.audio_controls.play,
                              canvas.page.audio_controls.effects.click);
    });

    it("instructs canvas to follow ship entity", function(){
      var ship = new Omega.Ship();
      ship.clicked_in(canvas);
      sinon.assert.calledWith(canvas.follow_entity, ship);
    });
  });

  describe("#selected", function(){
    var ship, page;

    before(function(){
      ship = Omega.Gen.ship();
      ship.init_gfx();

      page = new Omega.Pages.Test();
      sinon.stub(page.audio_controls, 'play');
    });

    it("sets mesh material emissive", function(){
      ship.selected(page);
      assert(ship.mesh.tmesh.material.emissive.getHex()).equals(0xff0000);
    });

    describe("ship is mining", function(){
      it("plays ship mining audio", function(){
        sinon.stub(ship, 'is_mining').returns(true);
        ship.selected(page);
        sinon.assert.calledWith(page.audio_controls.play, ship.mining_audio);
      });
    });

    describe("ship is not stopped", function(){
      it("plays ship movement audio", function(){
        sinon.stub(ship, 'is_mining').returns(false);
        sinon.stub(ship.location, 'is_stopped').returns(false);
        ship.selected(page);
        sinon.assert.calledWith(page.audio_controls.play, ship.movement_audio);
      });
    })
  });

  describe("#unselected", function(){
    var ship, page;

    before(function(){
      ship = Omega.Gen.ship();
      ship.init_gfx();

      page = new Omega.Pages.Test();
      sinon.stub(page.audio_controls, 'stop');
    });

    it("stops ship mining and movement audio", function(){
      ship.unselected(page);
      sinon.assert.calledWith(page.audio_controls.stop,
                              [ship.mining_audio, ship.movement_audio]);
    });

    it("resets mesh material emissive", function(){
      ship.unselected(page);
      assert(ship.mesh.tmesh.material.emissive.getHex()).equals(0);
    })
  });

  describe("#get", function(){
    var node, get_cb, invoke_spy;

    before(function(){
      node = new Omega.Node();
      get_cb = sinon.spy();
      invoke_spy = sinon.stub(node, 'http_invoke');
    });

    it("invokes manufacutred::get_entity request", function(){
      Omega.Ship.get('ship1', node, get_cb);
      sinon.assert.calledWith(invoke_spy,
        'manufactured::get_entity',
        'with_id', 'ship1', sinon.match.func);
    });

    describe("manufactured::get_entity callback", function(){
      var invoke_cb;
      before(function(){
        Omega.Ship.get('ship1', node, get_cb);
        invoke_cb = invoke_spy.getCall(0).args[3];
      });

      it("invokes callback with ship", function(){
        invoke_cb({result : {id: '42'}});
        sinon.assert.calledWith(get_cb, sinon.match.ofType(Omega.Ship), null);
      });

      describe("error received", function(){
        it("invokes callback with error", function(){
          invoke_cb({error : {message : "err"}});
          sinon.assert.calledWith(get_cb, null, "err");
        });
      });
    });
  });

  describe("#owned_by", function(){
    var node, retrieval_cb, invoke_spy;

    before(function(){
      node = new Omega.Node();
      retrieval_cb = sinon.spy();
      invoke_spy = sinon.stub(node, 'http_invoke');
    });

    it("invokes manufactured::get_entities request", function(){
      Omega.Ship.owned_by('user1', node, retrieval_cb);
      sinon.assert.calledWith(invoke_spy, 'manufactured::get_entities',
        'of_type', 'Manufactured::Ship', 'owned_by', 'user1');
    });

    describe("manufactured::get_entity callback", function(){
      it("invokes callback", function(){
        Omega.Ship.owned_by('user1', node, retrieval_cb);
        invoke_spy.getCall(0).args[5]({});
        sinon.assert.called(retrieval_cb);
      });

      it("creates new ship instances", function(){
        Omega.Ship.owned_by('user1', node, retrieval_cb);
        invoke_spy.getCall(0).args[5]({result : [{id: 'sh1'},{id: 'sh2'}]});
        var ships = retrieval_cb.getCall(0).args[0];
        assert(ships.length).equals(2);
        assert(ships[0]).isOfType(Omega.Ship);
        assert(ships[0].id).equals('sh1');
        assert(ships[1]).isOfType(Omega.Ship);
        assert(ships[1].id).equals('sh2');
      });
    });
  });

  describe("#under", function(){
    var node, retrieval_cb, invoke_spy;

    before(function(){
      node         = new Omega.Node();
      retrieval_cb = sinon.spy();
      invoke_spy   = sinon.stub(node, 'http_invoke');
    });

    it("invokes manufactured::get_entities request", function(){
      Omega.Ship.under('system1', node, retrieval_cb);
      sinon.assert.calledWith(invoke_spy, 'manufactured::get_entities',
        'of_type', 'Manufactured::Ship', 'under', 'system1');
    });

    describe("manufactured::get_entities callback", function(){
      it("invokes callback", function(){
        Omega.Ship.under('system1', node, retrieval_cb);
        invoke_spy.getCall(0).args[5]({});
        sinon.assert.called(retrieval_cb);
      });

      it("converts results to ship instances", function(){
        Omega.Ship.under('system1', node, retrieval_cb);
        invoke_spy.getCall(0).args[5]({result : [{id : 'sh1'}]});
        var ships = retrieval_cb.getCall(0).args[0];
        assert(ships.length).equals(1);
        assert(ships[0]).isOfType(Omega.Ship);
        assert(ships[0].id).equals('sh1');
      });
    });
  });
});}); // Omega.Ship
