pavlov.specify("Omega.UI.CanvasEntityGfx", function(){
describe("Omega.UI.CanvasEntityGfx", function(){
  var orig, entity;

  before(function(){
    orig = $.extend({}, Omega.UI.CanvasEntityGfx._tracker, true);
    entity = $.extend({}, Omega.UI.CanvasEntityGfx);
  });

  after(function(){
    Omega.UI.CanvasEntityGfx._tracker = orig;
  });

  describe("#scene_location", function(){
    it("returns entity location", function(){
      entity.location = new Omega.Location();
      assert(entity.scene_location()).equals(entity.location);
    });
  });

  describe("#position_tracker", function(){
    it("returns entity position tracker", function(){
      assert(entity.position_tracker()).isOfType(THREE.Object3D);
      assert(entity.position_tracker()).equals(entity.position_tracker());
    });
  });

  describe("#location_tracker", function(){
    it("returns entity location tracker", function(){
      assert(entity.location_tracker()).isOfType(THREE.Object3D);
      assert(entity.location_tracker()).equals(entity.location_tracker());
    });
  });

  describe("#_gfx_tracker", function(){
    it("returns singleton gfx tracker", function(){
      assert(entity._gfx_tracker()).equals(entity._gfx_tracker());
    });

    it("initializes loaded tracker for local json class to false", function(){
      entity.json_class = 'Foo';
      assert(entity._gfx_tracker()['loaded']['Foo']).isFalse();
    });

    it("initializes loaded tracker for local json class and specified type to false", function(){
      entity.json_class = 'Foo';
      entity.type = 'Bar';
      assert(entity._gfx_tracker()['loaded']['Foo']['Bar']).isFalse();
    });
  });

  describe("#gfx_loaded", function(){
    describe("entity graphics loaded", function(){
      it("returns true", function(){
        entity.json_class = 'Cosmos::Entities::Asteroid';
        sinon.stub(entity, '_gfx_tracker')
             .returns({'loaded':{'Cosmos::Entities::Asteroid' : true}});
        assert(entity.gfx_loaded()).isTrue();
      });
    });

    describe("typed entity graphics loaded", function(){
      it("returns true", function(){
        entity.type = 'corvette';
        entity.json_class = 'Manufactured::Ship';
        sinon.stub(entity, '_gfx_tracker')
             .returns({'loaded':{'Manufactured::Ship' : {'corvette' : true}}});
        assert(entity.gfx_loaded()).isTrue();
      });
    });

    describe("entity graphics not loaded", function(){
      it("returns false", function(){
        entity.json_class = 'Cosmos::Entities::Asteroid';
        sinon.stub(entity, '_gfx_tracker')
             .returns({'loaded':{'Cosmos::Entities::Asteroid' : false}});
        assert(entity.gfx_loaded()).isFalse();
      });
    });

    describe("typed entity graphics not loaded", function(){
      it("returns false", function(){
        entity.type = 'corvette';
        entity.json_class = 'Manufactured::Ship';
        sinon.stub(entity, '_gfx_tracker')
             .returns({'loaded' : {'Manufactured::Ship' : {'corvette' : false}}});
        assert(entity.gfx_loaded()).isFalse();
      });
    });
  });

  describe("#_loaded_gfx", function(){
    it("sets tracker for json class true", function(){
      entity.json_class = 'Cosmos::Entities::Asteroid';
      entity._loaded_gfx();
      assert(entity.gfx_loaded()).isTrue();
    });

    it("sets tracker to json class & type true", function(){
      entity.json_class = 'Manufactured::Ship';
      entity._loaded_gfx('corvette');
      assert(entity.gfx_loaded('corvette')).isTrue();
    });
  });

  describe("#gfx_initialized", function(){
    describe("entity graphics initialized", function(){
      it("returns true", function(){
        entity._gfx_initialized = true;
        assert(entity.gfx_initialized()).isTrue();
      });
    });

    describe("entity graphics not initialized", function(){
      it("returns false", function(){
        assert(entity.gfx_initialized()).isFalse();
      });
    });
  });

  describe("#gfx_initializing", function(){
    describe("entity graphics initialized", function(){
      it("returns false", function(){
        sinon.stub(entity, 'gfx_initialized').returns(true);
        assert(entity.gfx_initializing()).isFalse();
      });
    });
    describe("entity graphics not initializing", function(){
      it("returns false", function(){
        sinon.stub(entity, 'gfx_initialized').returns(false);
        assert(entity.gfx_initializing()).isFalse();
      });
    });
    describe("entity graphics not initialized and initializing", function(){
      it("returns true", function(){
        sinon.stub(entity, 'gfx_initialized').returns(false);
        entity._gfx_initializing = true;
        assert(entity.gfx_initializing()).isTrue();
      });
    });
  });
});}); // Omega.UI.CanvasEntityGfx
