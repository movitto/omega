pavlov.specify("Omega.UI.EffectsPlayer", function(){
describe("Omega.UI.EffectsPlayer", function(){
  var player;

  before(function(){
    player = new Omega.UI.EffectsPlayer({page : new Omega.Pages.Test()});
  });

  after(function(){
    Omega.UI.Dialog.remove();
  })

  it("initializes entities", function(){
    assert(player.entities).isSameAs([]);
  });

  describe("#add", function(){
    it("adds entity to entities list", function(){
      var ship = new Omega.Ship();
      player.add(ship)
      assert(player.entities).includes(ship);
    });
  })

  describe("#remove", function(){
    it("removes entity specified by id from list", function(){
      var ship = new Omega.Ship({id : 'sh1'});
      player.add(ship)
      player.remove(ship.id)
      assert(player.entities).doesNotInclude(ship);
    });
  });

  describe("#clear", function(){
    it("clears entity list", function(){
      var ship = new Omega.Ship({id : 'sh1'});
      player.add(ship)
      player.clear();
      assert(player.entities).isSameAs([]);
    });
  });

  describe("#has", function(){
    describe("entity specified by id is in list", function(){
      it("returns true", function(){
        var ship = new Omega.Ship({id : 'sh1'});
        player.add(ship)
        assert(player.has('sh1')).isTrue();
      });
    });

    describe("entity specified by id is not in list", function(){
      it("returns false", function(){
        assert(player.has('sh1')).isFalse();
      });
    });
  });

  describe('#wire_up', function(){
    //it('wires up document blur/focus/visibility change events'); // NIY

    //describe("on window blur", function(){
      //it("stops effects times") /// NIY
    //});

    //describe("om window focus", function(){
      //it("starts effects timer"); /// NIY
    //});

    describe("on document hidden", function(){
      //it("stops effects timer"); /// NIY
    });

    //describe("on document shown", function(){
    //  describe("effects timer previously playing", function(){
    //    it("starts effects timer"); /// NIY
    //  });
    //  describe("effects timer not previously playing", function(){
    //    it("does nothing / just returns"); /// NIY
    //  });
    //});
  });

  describe("#start", function(){
    var timer, create;

    before(function(){
      timer = {play : sinon.spy()};
      player.effects_timer = timer;

      create = sinon.stub(player, '_create_timer');
    });

    it('creates effects timer', function(){
      player.start();
      sinon.assert.called(create);
    });

    it('plays effects timer', function(){
      player.start();
      sinon.assert.called(timer.play);
    });

    it('sets playing true', function(){
      player.start();
      assert(player.playing).isTrue();
    });
  });

  describe("effect loop interation", function(){
    var canvas, animate;

    before(function(){
      canvas = new Omega.UI.Canvas();
      animate = sinon.stub(canvas, 'animate');

      player.page.canvas = canvas;
    })

    it("invokes #run_effects on all local entities", function(){
      var ship = new Omega.Ship();
      var run_effects = sinon.stub(ship, 'run_effects');
      player.add(ship);
      player._run_effects();
      sinon.assert.called(run_effects);
    });

    it("animates canvas", function(){
      player._run_effects();
      sinon.assert.called(animate);
    });
  });
});});
