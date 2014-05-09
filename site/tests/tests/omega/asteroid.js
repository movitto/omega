pavlov.specify("Omega.Asteroid", function(){
describe("Omega.Asteroid", function(){
  it("converts location", function(){
    var ast = new Omega.Asteroid({location : {json_class : 'Motel::Location', data : {x: 10, y: 20, z:30}}});
    assert(ast.location).isOfType(Omega.Location);
    assert(ast.location.x).equals(10);
    assert(ast.location.y).equals(20);
    assert(ast.location.z).equals(30);
  });

  describe("#toJSON", function(){
    it("returns asteroid json data", function(){
      var ast  = {id        : 'ast1',
                  name      : 'ast1n',
                  location  : new Omega.Location({id : 'ast1l'}),
                  parent_id : 'system1',
                  color     : '0A0A0A',
                  size      : 100}
      var oast = new Omega.Asteroid(ast);
      var json = oast.toJSON();

      ast.json_class = oast.json_class;
      ast.location = ast.location.toJSON();
      assert(json).isSameAs(ast);
    });
  });

  describe("#retrieve_details", function(){
    var ast, page, details_cb;

    before(function(){
      ast = new Omega.Asteroid({id       : 'ast1i',
                                name     : 'ast1',
                                location : new Omega.Location({x:100,y:-200,z:50.5678})});
      page = new Omega.Pages.Test({node : new Omega.Node()});
      details_cb = sinon.spy();
    });

    after(function(){
      if(page.node.http_invoke.restore) page.node.http_invoke.restore();
    });

    it("invokes details cb with asteroid name / location", function(){
      var expected = 'Asteroid: ast1<br/>@ 1.00e+2/-2.00e+2/5.06e+1<br/>';
      ast.retrieve_details(page, details_cb)
      sinon.assert.calledWith(details_cb, expected);
    });

    it("invokes cosmos::get_resources request with page node", function(){
      var http_invoke = sinon.spy(page.node, 'http_invoke');
      ast.retrieve_details(page, details_cb);
      sinon.assert.calledWith(http_invoke,
        'cosmos::get_resources', 'ast1i', sinon.match.func);
    });

    describe("on resources retrieval", function(){
      it("invokes resources_retrieved", function(){
        var http_invoke = sinon.spy(page.node, 'http_invoke');
        ast.retrieve_details(page, details_cb);

        var retrieve_cb = http_invoke.getCall(0).args[2];
        var resources_retrieved = sinon.spy(ast, '_resources_retrieved');
        var response = {result: []};
        retrieve_cb(response);

        sinon.assert.calledWith(resources_retrieved, response, details_cb);
      });
    });
  });

  describe("#_resources_retrieved", function(){
    var ast, details_cb;

    before(function(){
      ast = new Omega.Asteroid({});
      details_cb = sinon.spy();
    });

    describe("error on retrieval", function(){
      it("invokes details cb with error", function(){
        var response = {error : {message : 'resources_error'}};
        ast._resources_retrieved(response, details_cb);

        var expected = 'Could not load resources: resources_error';
        sinon.assert.calledWith(details_cb, expected);
      });
    });

    describe("successful retrieval", function(){
      it("invokes details cb with resources retrieved", function(){
        var res1 = {id : 'res1', quantity: 50, material_id: 'gold'};
        var res2 = {id : 'res2', quantity: 10, material_id: 'ruby'};
        var resources = [res1, res2];
        var response  = {result: resources};
        var expected  = 'Resource: res1<br/>' +
                        '50 of gold<br/>'     +
                        'Resource: res2<br/>' +
                        '10 of ruby<br/>'     ;

        ast._resources_retrieved(response, details_cb);
        sinon.assert.calledWith(details_cb, expected);
      });
    });
  });

  describe("#load_gfx", function(){
    describe("graphics are initialized", function(){
      var orig;

      before(function(){
        orig = {gfx: Omega.Asteroid.gfx,
                mesh: Omega.Asteroid.gfx ? Omega.Asteroid.gfx.mesh : null};
      })

      after(function(){
        Omega.Asteroid.gfx = orig.gfx;
        if(Omega.Asteroid.gfx) Omega.Asteroid.gfx.mesh = orig.mesh;
      });

      it("does nothing / just returns", function(){
        Omega.Asteroid.gfx = {};
        Omega.Asteroid.mesh = null;
        new Omega.Asteroid().load_gfx();
        assert(Omega.Asteroid.mesh).isNull();
      });
    });

    it("creates mesh for Asteroid", function(){
      var asteroid = Omega.Test.Canvas.Entities().asteroid;
      var num = Omega.Config.resources.asteroid.geometry.length;
      assert(Omega.Asteroid.gfx.meshes.length).equals(num)
      for(var a = 0; a < num; a++){
        assert(Omega.Asteroid.gfx.meshes[a]).isOfType(Omega.AsteroidMesh);
        assert(Omega.Asteroid.gfx.meshes[a].tmesh).isOfType(THREE.Mesh);
        assert(Omega.Asteroid.gfx.meshes[a].tmesh.material).isOfType(THREE.MeshLambertMaterial);
        assert(Omega.Asteroid.gfx.meshes[a].tmesh.geometry).isOfType(THREE.Geometry);
      }
      /// TODO assert material texture & geometry src path values ?
    });
  });

  describe("#init_gfx", function(){
    before(function(){
      /// preiinit using test page
      Omega.Test.Canvas.Entities();
    });

    after(function(){
      if(Omega.AsteroidMesh.load.restore) Omega.AsteroidMesh.load.restore();
    });

    it("loads asteroid gfx", function(){
      var ast      = Omega.Gen.asteroid();
      var load_gfx = sinon.spy(ast, 'load_gfx');
      ast.init_gfx(Omega.Config);
      sinon.assert.called(load_gfx);
    });

    it("clones Asteroid mesh", function(){
      sinon.stub(Omega.AsteroidMesh, 'load');
      var ast = Omega.Gen.asteroid();
      ast.init_gfx(Omega.Config);
      sinon.assert.called(Omega.AsteroidMesh.load);

      var mesh = new THREE.Mesh;
      Omega.AsteroidMesh.load.omega_callback()(mesh)
      assert(ast.mesh).equals(mesh);
    });

    it("sets position tracker position", function(){
      var loc = new Omega.Location({x: 100, y: -100, z: 200});
      var ast = new Omega.Asteroid({location : loc});
      ast.init_gfx(Omega.Config);
      assert(ast.position_tracker().position.x).equals(100);
      assert(ast.position_tracker().position.y).equals(-100);
      assert(ast.position_tracker().position.z).equals(200);
    });

    it("sets mesh.omega_entity", function(){
      var ast = Omega.Gen.asteroid();
      ast.init_gfx(Omega.Config);
      assert(ast.mesh.omega_entity).equals(ast);
    });

    it("adds position tracker to asteroid scene components", function(){
      var ast = Omega.Gen.asteroid();
      ast.init_gfx(Omega.Config);
      assert(ast.components).isSameAs([ast.position_tracker()]);
    });
  });

});}); // Omega.Asteroid
