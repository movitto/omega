/// FIXME internal state getting messed up in this module
pavlov.specify("Omega.UI.CanvasEntityGfx", function(){
describe("Omega.UI.CanvasEntityGfx", function(){
  var orig_loaded, orig_resource, entity;

  before(function(){
    orig_loaded   = $.extend(true, {}, Omega.UI.CanvasEntityGfx.__loaded_tracker);
    orig_resource = Omega.UI.CanvasEntityGfx.__resource_tracker;
    Omega.UI.CanvasEntityGfx.__resource_tracker = {};

    entity = $.extend({}, Omega.UI.CanvasEntityGfx);
  });

  after(function(){
    Omega.UI.CanvasEntityGfx.__loaded_tracker   = orig_loaded;
    Omega.UI.CanvasEntityGfx.__resource_tracker = orig_resource;
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

  describe("_has_type", function(){
    describe("entity has type", function(){
      it("returns true", function(){
        entity.type = 'foo';
        assert(entity._has_type()).isTrue();
      });
    });

    describe("entity does not have type", function(){
      it("returns false", function(){
        assert(entity._has_type()).isFalse();
      });
    });
  });

  describe("_no_type", function(){
    describe("entity has type", function(){
      it("returns false", function(){
        entity.type = 'foo';
        assert(entity._no_type()).isFalse();
      });
    });

    describe("entity does not have type", function(){
      it("returns true", function(){
        assert(entity._no_type()).isTrue();
      });
    });
  });

  describe("#_loaded_tracker", function(){
    it("returns singleton gfx loaded tracker", function(){
      assert(entity._loaded_tracker()).equals(entity._loaded_tracker());
    });

    it("initializes loaded tracker for local json class to false", function(){
      entity.json_class = 'Foo';
      assert(entity._loaded_tracker()['Foo']).isFalse();
    });

    it("initializes loaded tracker for local json class and specified type to false", function(){
      entity.json_class = 'Foo';
      entity.type = 'Bar';
      assert(entity._loaded_tracker()['Foo']['Bar']).isFalse();
    });
  });

  describe("#_resource_tracker", function(){
    it("returns singleton gfx resource tracker", function(){
      assert(entity._resource_tracker()).equals(entity._resource_tracker());
    });

    it("initializes resource tracker for local json class to false", function(){
      entity.json_class = 'Foo';
      assert(entity._resource_tracker()['Foo']).isSameAs({});
    });

    it("initializes resource tracker for local json class and specified type to false", function(){
      entity.json_class = 'Foo';
      entity.type = 'Bar';
      assert(entity._resource_tracker()['Foo']['Bar']).isSameAs({});
    });
  });

  describe("#gfx_loaded", function(){
    describe("entity graphics loaded", function(){
      it("returns true", function(){
        entity.json_class = 'Cosmos::Entities::Asteroid';
        sinon.stub(entity, '_loaded_tracker').returns({'Cosmos::Entities::Asteroid' : true});
        assert(entity.gfx_loaded()).isTrue();
      });
    });

    describe("typed entity graphics loaded", function(){
      it("returns true", function(){
        entity.type = 'corvette';
        entity.json_class = 'Manufactured::Ship';
        sinon.stub(entity, '_loaded_tracker')
             .returns({'Manufactured::Ship' : {'corvette' : true}});
        assert(entity.gfx_loaded()).isTrue();
      });
    });

    describe("entity graphics not loaded", function(){
      it("returns false", function(){
        entity.json_class = 'Cosmos::Entities::Asteroid';
        sinon.stub(entity, '_loaded_tracker')
             .returns({'Cosmos::Entities::Asteroid' : false});
        assert(entity.gfx_loaded()).isFalse();
      });
    });

    describe("typed entity graphics not loaded", function(){
      it("returns false", function(){
        entity.type = 'corvette';
        entity.json_class = 'Manufactured::Ship';
        sinon.stub(entity, '_loaded_tracker')
             .returns({'Manufactured::Ship' : {'corvette' : false}});
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
      entity.type = 'corvette'
      entity._loaded_gfx();
      assert(entity.gfx_loaded()).isTrue();
    });
  });

  describe("#_store_resource", function(){
    it("stores entity class resource", function(){
      var mesh = {};
      entity.json_class = 'Foo';
      entity._store_resource('mesh', mesh);
      assert(entity._resource_tracker()['Foo']['mesh']).equals(mesh);
    })

    it("stores typed entity class resource", function(){
      var mesh = {};
      entity.json_class = 'Foo';
      entity.type = 'Bar'
      entity._store_resource('mesh', mesh);
      assert(entity._resource_tracker()['Foo']['Bar']['mesh']).equals(mesh);
    })
  });

  describe("#_retrieve_resource", function(){
    it("retrieves stored entity class resource", function(){
      var mesh = {};
      entity.json_class = 'Foo';
      entity._store_resource('mesh', mesh);
      assert(entity._retrieve_resource('mesh')).equals(mesh);
    });

    it("retrieves retrieved entity class resource", function(){
      var mesh = {};
      entity.json_class = 'Foo';
      entity.type = 'Bar'
      entity._store_resource('mesh', mesh);
      assert(entity._retrieve_resource('mesh')).equals(mesh);
    });
  });

  describe("#_load_async_resource", function(){
    before(function(){
      sinon.stub(Omega.UI.AsyncResourceLoader, 'load');
    });

    after(function(){
      Omega.UI.AsyncResourceLoader.load.restore();
    });

    it("uses async resource loaded to load resource", function(){
      var cb = function(){};
      var resource = {};
      entity._load_async_resource('rid', resource, cb);
      sinon.assert.calledWith(Omega.UI.AsyncResourceLoader.load, 'rid', resource, cb)
    });
  });

  describe("#_retrieve_async_resource", function(){
    before(function(){
      sinon.stub(Omega.UI.AsyncResourceLoader, 'retrieve');
    });

    after(function(){
      Omega.UI.AsyncResourceLoader.retrieve.restore();
    });

    it("uses async resource loaded to retrieve resource", function(){
      var cb = function(){};
      entity._retrieve_async_resource('rid', cb);
      sinon.assert.calledWith(Omega.UI.AsyncResourceLoader.retrieve, 'rid', cb)
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
