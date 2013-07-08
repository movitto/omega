// TODO test specific entity ui components / operations

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
                         solar_systems : [sys1, sys2]});
  })

  after(function(){
    reenable_three_js();
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

    st1 = { id : 'star1' };
    pl1 = { id : 'planet1' };
    pl2 = { id : 'planet2' };
    jg1 = { id : 'jump_gate1' };
    ast1 = { id : 'asteroid1' };
    sys = new SolarSystem({id : 'sys1',
                           location : { id : 42 },
                           stars : [st1],
                           planets : [pl1, pl2],
                           jump_gates: [jg1],
                           asteroids : [ast1]});
  })

  after(function(){
    reenable_three_js();
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

  //describe("#add_jump_gate", function(){
  //  it("adds THREE line component to entity"); // NIY
  //});

  //it("adds THREE clickable sphere component to entity"); // NIY
  //it("adds THREE plane component to entity"); // NIY
  //it("adds THREE text label component to entity"); // NIY

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

  after(function(){
    reenable_three_js();
  })

  it("converts location", function(){
    assert(st.location).isTypeOf(Location)
  })

  //it("adds THREE clickable sphere component to entity"); // NIY
});}); // Star

pavlov.specify("Planet", function(){
describe("Planet", function(){
  var pl; var mn;

  before(function(){
    disable_three_js();
    m = { id : 'mn1' }
    pl = new Planet({location : { id : 42 }, moons : [m]})
  })

  after(function(){
    reenable_three_js();
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

    //it("updates THREE sphere position") // NIY

    //it("updates moons' THREE sphere positions", function(){ // NIY
    //  var nmn = { id : 'mn1'}
    //  pl.update({moons : [nmn]})
    //  sinon.assert.calledWith(spy, nmn);
    //});
  });

  //it("adds THREE clickable sphere component to entity"); // NIY
  //it("adds THREE line component to entity for orbit"); // NIY
  //it("adds THREE spheres component to entity for moons"); // NIY
});}); // Planet

pavlov.specify("Asteroid", function(){
describe("Asteroid", function(){
  var ast;

  before(function(){
    disable_three_js();
    ast = new Asteroid({location : { id : 42 }})
  })

  after(function(){
    reenable_three_js();
  })

  it("converts location", function(){
    assert(ast.location).isTypeOf(Location)
  })

  //it("adds THREE clickable mesh component to entity"); // NIY
});}); // Asteroid

pavlov.specify("JumpGate", function(){
describe("JumpGate", function(){
  var jg;

  before(function(){
    disable_three_js();
    jg = new JumpGate({location : { id : 42 }})
  })

  after(function(){
    reenable_three_js();
  })

  it("converts location", function(){
    assert(jg.location).isTypeOf(Location)
  })

  //it("adds THREE clickable mesh component to entity"); // NIY
  //it("adds THREE sphere component to entity (selection sphere)"); // NIY

  //describe("clicked jump gate", function(){
  //  it("sets selected true"); // NIY
  //  it("removes old jump gate command callbacks"); // NIY
  //  it("creates jump gate commands callback"); // NIY
  //  describe("command trigger jump gate", function(){
  //    it("invokes trigger jump gate command"); // NIY
  //  });
  //  it("sets clickable component to THREE selection sphere"); // NIY
  //  it("reloads jump gate in scene"); // NIY
  //})

  //describe("unselect jump gate", function(){
  //  it("sets selected to false"); // NIY
  //  it("reloads jump gate in scene"); // NIY
  //  it("sets clickable component to THREE mesh"); // NIY
  //});
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
    reenable_three_js();
    if(Entities().node().web_request.restore) Entities().node().web_request.restore();
  })

  it("converts location", function(){
    assert(sh.location).isTypeOf(Location)
  });

  //describe("#update", function(){
  //  it("updates attributes"); // NIY
  //  it("updates location"); // NIY
  //  it("updates THREE mesh location"); // NIY
  //  describe("ship attacking", function(){
  //    it("sets THREE attack line position"); // NIY
  //    it("adds THREE attack line component to entity"); // NIY
  //  });
  //  describe("ship attacking", function(){
  //    it("sets THREE mining line position"); // NIY
  //    it("adds THREE mining line component to entity"); // NIY
  //  });
  //  it("reloads entity in schene"); // NIY
  //})

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

  //describe("ship clicked in scene", function(){
  //  it("removes ship ui command callbacks"); // NIY
  //  it("handles ship ui command callbacks"); // NIY
  //  describe("on ship ui command", function(){
  //    it("raises event on ship"); // NIY
  //  });
  //  // TODO test specific commands
  //  it("sets selected true"); // NIY
  //  it("reloads entity in scene"); // NIY
  //});

  //describe("ship unselected", function(){
  //  it("sets selected to false"); // NIY
  //  it("reloads entity in scene"); // NIY
  //});

  //it("adds THREE clickable mesh component to entity"); // NIY
  //it("create THREE line component (for attack line)"); // NIY
  //it("create THREE line component (for mining line)"); // NIY

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
    reenable_three_js();
    if(Entities().node().web_request.restore) Entities().node().web_request.restore();
  })

  it("converts location", function(){
    assert(st.location).isTypeOf(Location)
  });

  //it("adds THREE clickable mesh component to entity"); // NIY

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

  //describe("station clicked in scene", function(){
  //  it("removes station ui command callbacks"); // NIY
  //  it("handles station ui command callbacks"); // NIY
  //  describe("on station ui command", function(){
  //    it("raises event on station"); // NIY
  //  });
  //  // TODO test specific commands
  //  it("sets selected true"); // NIY
  //  it("reloads entity in scene"); // NIY
  //});

  //describe("station unselected", function(){
  //  it("sets selected to false"); // NIY
  //  it("reloads entity in scene"); // NIY
  //});

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
