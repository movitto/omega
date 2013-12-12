pavlov.specify("Omega.Galaxy", function(){
describe("Omega.Galaxy", function(){
  it("sets background");

  it("converts children", function(){
    var system = {json_class: 'Cosmos::Entities::SolarSystem', id: 'sys1'};
    var galaxy = new Omega.Galaxy({children: [system]});
    assert(galaxy.children.length).equals(1);
    assert(galaxy.children[0]).isOfType(Omega.SolarSystem);
    assert(galaxy.children[0].id).equals('sys1');
  });

  it("converts location");;

  describe("#systems", function(){
    it("returns system children");
  });

  describe("#set_children_from", function(){
    it("swaps child systems in from entity list");
    it("sets galaxy on systems swapped in");
  });

  describe("#load_gfx", function(){
    describe("graphics are initialized", function(){
      var orig;

      before(function(){
        orig = Omega.Galaxy.gfx;
      })

      after(function(){
        Omega.Galaxy.gfx = orig;
      });

      it("does nothing / just returns", function(){
        Omega.Galaxy.gfx = {particles : null};
        new Omega.Galaxy().load_gfx();
        assert(Omega.Galaxy.gfx.particles).isNull();
      });
    });

    it("creates particle system for galaxy", function(){
      Omega.Test.Canvas.Entities();

      assert(Omega.Galaxy.gfx.particles).isOfType(THREE.ParticleSystem);
      assert(Omega.Galaxy.gfx.particles.geometry).isOfType(THREE.Geometry);
      assert(Omega.Galaxy.gfx.particles.material).isOfType(THREE.ParticleBasicMaterial);
      /// TODO verify geometry generated according to density wave theory ?
    });
  });

  describe("#init_gfx", function(){
    before(function(){
      /// preiinit using test page
      Omega.Test.Canvas.Entities();
    });

    after(function(){
      if(Omega.Galaxy.gfx){
        if(Omega.Galaxy.gfx.particles.clone.restore) Omega.Galaxy.gfx.particles.clone.restore();
      }
    });

    it("loads galaxy gfx", function(){
      var galaxy    = new Omega.Galaxy();
      var load_gfx  = sinon.spy(galaxy, 'load_gfx');
      galaxy.init_gfx();
      sinon.assert.called(load_gfx);
    });

    it("clones Galaxy particles", function(){
      var galaxy = new Omega.Galaxy();
      var mesh = new THREE.Mesh();
      sinon.stub(Omega.Galaxy.gfx.particles, 'clone').returns(mesh);
      galaxy.init_gfx();
      assert(galaxy.particles).equals(mesh);
    });

    it("adds particle system to galaxy scene components", function(){
      var galaxy = new Omega.Galaxy();
      galaxy.init_gfx();
      assert(galaxy.components).isSameAs([galaxy.particles]);
    });
  });

  describe("#run_effects", function(){
    //it("updates particle system particles") // NIY
  });

  describe("#with_id", function(){
    var node, retrieval_cb, invoke_spy;

    before(function(){
      node = new Omega.Node();
      retrieval_cb = sinon.spy();
      invoke_spy = sinon.stub(node, 'http_invoke');
    });

    it("invokes cosmos::get_entity request", function(){
      Omega.Galaxy.with_id('galaxy1', node, retrieval_cb);
      sinon.assert.calledWith(invoke_spy, 'cosmos::get_entity', 'with_id', 'galaxy1');
    });

    describe("cosmos::get_entity callback", function(){
      it("invokes callback", function(){
        Omega.Galaxy.with_id('galaxy1', node, retrieval_cb);
        invoke_spy.getCall(0).args[3]({});
        sinon.assert.called(retrieval_cb);
      });

      it("creates new galaxy instance", function(){
        Omega.Galaxy.with_id('galaxy1', node, retrieval_cb);
        invoke_spy.getCall(0).args[3]({result : {id:'gal1'}});
        var galaxy = retrieval_cb.getCall(0).args[0];
        assert(galaxy).isOfType(Omega.Galaxy);
        assert(galaxy.id).equals('gal1');
      });
    });
  });
});}); // Omega.Galaxy
