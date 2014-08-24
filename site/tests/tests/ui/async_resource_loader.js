pavlov.specify("Omega.UI.AsyncResourceLoader", function(){
describe("Omega.UI.AsyncResourceLoader", function(){
  var loader;
  var resource;

  before(function(){
    resource = {};
    loader = $.extend(true, {}, Omega.UI.AsyncResourceLoader)
    THREE.EventDispatcher.prototype.apply(loader);
  });

  it("has json loader", function(){
    assert(loader._json_loader()).isOfType(THREE.JSONLoader);
    assert(loader._json_loader()).equals(loader._json_loader());
  });

  describe("#load", function(){
    before(function(){
      sinon.stub(loader._json_loader(), 'load');
    });

    after(function(){
      loader._json_loader().load.restore();
    })

    it("loads json resource", function(){
      loader.load('rid', ['path', 'prefix']);
      sinon.assert.calledWith(loader._json_loader().load, 'path', sinon.match.func, 'prefix');
    });

    it("loads json resources", function(){
      loader.load('rid', [['path1', 'path2'], 'prefix']);
      sinon.assert.calledWith(loader._json_loader().load, 'path1', sinon.match.func, 'prefix');
      sinon.assert.calledWith(loader._json_loader().load, 'path2', sinon.match.func, 'prefix');
    });

    it("sets omega_id on resource", function(){
      loader.load('rid', ['path', 'prefix']);
      loader._json_loader().load.omega_callback()(resource);
      assert(resource.omega_id).equals('rid');
    });

    it("tracks resources", function(){
      loader.load('rid', ['path', 'prefix']);
      loader._json_loader().load.omega_callback()(resource);
      assert(loader._resources()['rid']).equals(resource);
    });

    it("invokes callback after resource retrieved", function(){
      var cb = sinon.spy();
      loader.load('rid', ['path', 'prefix'], cb);
      loader._json_loader().load.omega_callback()(resource);
      sinon.assert.calledWith(cb, resource);
    });

    it("invokes callback after multiple resources retrieved", function(){
      var resource2 = {};
      var cb = sinon.spy();
      loader.load('rid', [['path1', 'path2'], 'prefix'], cb);
      loader._json_loader().load.omega_callback()(resource);
      sinon.assert.notCalled(cb);
      loader._json_loader().load.omega_callback()(resource2);
      sinon.assert.calledWith(cb, [resource, resource2]);
    });
  });

  describe("#_handle_loaded", function(){
    it("listens for handle loaded event", function(){
      /// XXX class which loaded was derived from previously handled this
      //assert(loader).doesNotHandleEvent('loaded_resource');
      loader._handle_loaded();
      assert(loader).handlesEvent('loaded_resource');
    });

    it("only registers one loaded event handler", function(){
      loader._handle_loaded();
      loader._handle_loaded();
      assert(loader._listeners['loaded_resource'].length).equals(1);
    });
  });

  describe("#on_loaded loaded event handler", function(){
    it("invokes callbacks for event", function(){
      var cb = sinon.spy();
      loader._retrieval_callbacks = {'rid' : [cb]};

      resource.omega_id = 'rid';
      loader._on_loaded(resource);
      sinon.assert.calledWith(cb, resource)
    });
  });

  describe("#retrieve", function(){
    it("handles loaded event", function(){
      sinon.spy(loader, '_handle_loaded');
      loader.retrieve('rid');
      sinon.assert.called(loader._handle_loaded);
    });

    describe("resource exists locally", function(){
      before(function(){
        loader.__resources['rid'] = resource;
      });

      it("invokes callback with resource", function(){
        var cb = sinon.spy();
        loader.retrieve('rid', cb);
        sinon.assert.calledWith(cb, resource);
      });

      it("returns resource", function(){
        assert(loader.retrieve('rid')).equals(resource);
      });
    });

    describe("resource does not exist locally", function(){
      it("adds callback to resource loaded callbacks", function(){
        var cb = sinon.spy();
        loader.retrieve('rid', cb);
        assert(loader._retrieval_callbacks['rid']).isSameAs([cb]);
      });

      it("returns null", function(){
        assert(loader.retrieve('rid')).isNull();
      });
    });
  });
});});
