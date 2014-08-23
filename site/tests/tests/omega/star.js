/// TODO split out into multiple files along module boundries
pavlov.specify("Omega.Star", function(){
describe("Omega.Star", function(){
  it("parses type(color) into int", function(){
    var star = new Omega.Star({type: 'ABABAB'});
    assert(star.type_int).equals(0xABABAB);
  });

  describe("#toJSON", function(){
    it("returns planet json data", function(){
      var st  = {id          : 'st1',
                 name        : 'st1n',
                 parent_id   : 'sys1',
                 location    : new Omega.Location({id : 'st1l'}),
                 type        : 'ABABAB',
                 size        : 100};

      var ost  = new Omega.Star(st);
      var json = ost.toJSON();

      st.json_class  = ost.json_class;
      st.location    = st.location.toJSON();
      assert(json).isSameAs(st);
    });
  });

  //describe("#clicked_in", function(){
  //  it("resets canvas cam"); /// NIY
  //});

  describe("#load_gfx", function(){
    describe("graphics are initialized", function(){
      it("does nothing / just returns", function(){
        var star = new Omega.Star();
        sinon.stub(star, 'gfx_loaded').returns(true);
        sinon.spy(star, '_loaded_gfx');
        star.load_gfx();
        sinon.assert.notCalled(star._loaded_gfx);
      });
    });

    it("creates mesh for Star", function(){
      var star = Omega.Test.entities()['star'];
      var mesh = star._retrieve_resource('mesh');
      assert(mesh).isOfType(Omega.StarMesh);
      assert(mesh.tmesh.geometry).isOfType(THREE.SphereGeometry);
      assert(mesh.tmesh.material).isOfType(THREE.MeshBasicMaterial);
    });

    it("creates light for Star", function(){
      var star  = Omega.Test.entities()['star'];
      var light = star.light;
      assert(light).isOfType(THREE.PointLight);
    });
  });

  describe("#init_gfx", function(){
    var type, star, mesh, light;

    before(function(){
      type = 'FF7700';
      mesh  = new Omega.StarMesh({type : type});
      light = new Omega.StarLight();
      star  = new Omega.Star({type : type});
      star.load_gfx();
      sinon.stub(star._retrieve_resource('mesh'),      'clone').returns(mesh);
      sinon.stub(star._retrieve_resource('light'),     'clone').returns(light);
    });

    after(function(){
      star._retrieve_resource('mesh').clone.restore();
      star._retrieve_resource('light').clone.restore();
    });

    it("loads star gfx", function(){
      sinon.spy(star, 'load_gfx');
      star.init_gfx();
      sinon.assert.called(star.load_gfx);
    });

    it("clones Star mesh", function(){
      star.init_gfx();
      assert(star.mesh).equals(mesh);
      assert(star.mesh.omega_entity).equals(star);
    });

    it("clones Star light", function(){
      star.init_gfx();
      assert(star.light).equals(light);
      assert(star.light.position).equals(star.mesh.tmesh.position);
    });

    it("sets light type ", function(){
      star.init_gfx();
      assert(star.light.color.getHex()).equals(parseInt('0x' + type));
    });

    it("adds mesh, light, and glow to star scene components", function(){
      star.init_gfx();
      assert(star.components).isSameAs([star.glow.tglow, star.mesh.tmesh, star.light]);
    });
  });
});}); // Omega.Star
