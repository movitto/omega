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
      var expected = 'Asteroid: ast1<br/>@ 100/-200/50.57<br/>';
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
      assert(Omega.Asteroid.gfx.mesh).isOfType(THREE.Mesh);
      assert(Omega.Asteroid.gfx.mesh.material).isOfType(THREE.MeshLambertMaterial);
      assert(Omega.Asteroid.gfx.mesh.geometry).isOfType(THREE.Geometry);
      /// TODO assert material texture & geometry src path values ?
    });
  });

  describe("#init_gfx", function(){
    before(function(){
      /// preiinit using test page
      Omega.Test.Canvas.Entities();
    });

    after(function(){
      if(Omega.Asteroid.gfx){
        if(Omega.Asteroid.gfx.mesh && Omega.Asteroid.gfx.mesh.clone.restore) Omega.Asteroid.gfx.mesh.clone.restore();
      }
    });

    it("loads asteroid gfx", function(){
      var ast        = new Omega.Asteroid();
      var load_gfx  = sinon.spy(ast, 'load_gfx');
      ast.init_gfx();
      sinon.assert.called(load_gfx);
    });

    it("clones Asteroid mesh", function(){
      var mesh = new THREE.Mesh();
      /// need to wait till template mesh is loaded b4 wiring up stub
      Omega.Asteroid.prototype.
        retrieve_resource('template_mesh', function(){
          sinon.stub(Omega.Asteroid.gfx.mesh, 'clone').returns(mesh);
        });

      var ast = new Omega.Asteroid();
      ast.init_gfx();
      assert(ast.mesh).equals(mesh);
    });

    it("sets mesh position", function(){
      var ast = new Omega.Asteroid({location : new Omega.Location({x: 100, y: -100, z: 200})});
      ast.init_gfx();
      assert(ast.mesh.position.x).equals(100);
      assert(ast.mesh.position.y).equals(-100);
      assert(ast.mesh.position.z).equals(200);
    });

    it("sets mesh.omega_entity", function(){
      var ast = new Omega.Asteroid({});
      ast.init_gfx();
      assert(ast.mesh.omega_entity).equals(ast);
    });

    it("adds mesh to asteroid scene components", function(){
      var ast = new Omega.Asteroid();
      ast.init_gfx();
      assert(ast.components).isSameAs([ast.mesh]);
    });
  });

});}); // Omega.Asteroid
