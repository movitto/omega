pavlov.specify("Omega.StarGfxInitializer", function(){
describe("Omega.StarGfxInitializer", function(){
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
});});
