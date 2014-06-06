pavlov.specify("Omega.SolarSystemInterconns", function(){
describe("Omega.SolarSystemInterconns", function(){
  var interconns;
  before(function(){
    interconns = new Omega.SolarSystemInterconns();
  });

  describe("#init_gfx", function(){
    it("initializes a SPE particle group instance", function(){
      interconns.init_gfx(Omega.Config);
      assert(interconns.particles.mesh).isOfType(THREE.ParticleSystem);
    });
  });

  describe("#_queue", function(){
    it("initializes queue", function(){
      assert(interconns._queued).isUndefined();
      interconns._queue('interconn');
      assert(interconns._queued).isNotNull();
    })

    it("adds interconn to queue", function(){
      interconns._queued = ['interconn1'];
      interconns._queue('interconn2');
      assert(interconns._queued).isSameAs(['interconn1', 'interconn2']);
    });
  });

  describe("#unqueue", function(){
    it("adds each queued interconn", function(){
      sinon.stub(interconns, 'add');
      interconns._queued = ['interconn1', 'interconn2'];
      interconns.unqueue();
      sinon.assert.calledWith(interconns.add, 'interconn1');
      sinon.assert.calledWith(interconns.add, 'interconn2');
    });

    it("resets queued list", function(){
      interconns._queued = [];
      interconns.unqueue();
      assert(interconns._queued).equals(null);
    });
  });

  describe("#add", function(){
    before(function(){
      interconns.omega_entity = new Omega.SolarSystem();
    });

    describe("omega_entity's gfx are not initialized", function(){
      before(function(){
        sinon.stub(interconns.omega_entity, 'gfx_initialized').returns(false);
      });

      it("queues endpoint", function(){
        sinon.stub(interconns, '_queue');
        interconns.add('interconn1');
        sinon.assert.calledWith(interconns._queue, 'interconn1');
      });

      it("does not add endpoint", function(){
        interconns.add('interconn1');
        assert(interconns.endpoints.length).equals(0);
      });
    });

    describe("omega_entity's gfx are initialized", function(){
      var endpoint;

      before(function(){
        sinon.stub(interconns.omega_entity, 'gfx_initialized').returns(true);
        interconns.omega_entity.components = [];

        interconns.init_gfx(Omega.Config);
        endpoint = new Omega.SolarSystem();

        interconns.omega_entity.location = new Omega.Location();
        endpoint.location = new Omega.Location();
      });

      it("stores endpoint locally", function(){
        interconns.add(endpoint)
        assert(interconns.endpoints.length).equals(1);
        assert(interconns.endpoints[0]).equals(endpoint);
      });

      it("adds emitter to particle group", function(){
        assert(interconns.particles.emitters.length).equals(0);
        interconns.add(endpoint)
        assert(interconns.particles.emitters.length).equals(1);
      });

      //it("sets particle velocity on emitter"); // NIY

      it("adds new line component to omega_entity galaxy position tracker", function(){
        var line = new THREE.Line();
        sinon.stub(interconns, '_line').returns(line);
        interconns.add(endpoint)
        assert(interconns.omega_entity.position_tracker().children.length).equals(1)
        assert(interconns.omega_entity.position_tracker().children[0]).equals(line);
      });
    });
  });
});});
