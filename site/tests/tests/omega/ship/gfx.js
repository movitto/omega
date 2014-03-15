// Test mixin usage through ship
pavlov.specify("Omega.ShipGfx", function(){
describe("Omega.ShipGfx", function(){
  var ship;

  before(function(){
    ship = Omega.Gen.ship();
  });

  describe("#load_gfx", function(){
    describe("graphics are initialized", function(){
      var orig_gfx;

      before(function(){
        orig_gfx = Omega.Ship.gfx;
        Omega.Ship.gfx = null;
        sinon.stub(ship, 'gfx_loaded').returns(true);
      });

      after(function(){
        Omega.Ship.gfx = orig_gfx;
      });

      it("does nothing / just returns", function(){
        ship.load_gfx();
        assert(Omega.Ship.gfx).isNull();
      });
    });

    it("creates mesh for Ship", function(){
      assert(Omega.Ship.gfx[ship.type].mesh).isOfType(Omega.ShipMesh);
    });

    it("creates highlight effects for Ship", function(){
      assert(Omega.Ship.gfx[ship.type].highlight).
        isOfType(Omega.ShipHighlightEffects);
    });

    it("creates lamps for Ship", function(){
      assert(Omega.Ship.gfx[ship.type].lamps).isOfType(Omega.ShipLamps);
    });

    it("creates trails for Ship", function(){
      assert(Omega.Ship.gfx[ship.type].trails).isOfType(Omega.ShipTrails);
    });

    it("creates attack vector for Ship", function(){
      var ship = Omega.Test.Canvas.Entities().ship;
      assert(Omega.Ship.gfx[ship.type].attack_vector).
        isOfType(Omega.ShipAttackVector);
    });

    it("creates mining vector for Ship", function(){
      var ship = Omega.Test.Canvas.Entities().ship;
      assert(Omega.Ship.gfx[ship.type].mining_vector).
        isOfType(Omega.ShipMiningVector);
    });

    it("creates trajectory vectors for ship", function(){
      var ship = Omega.Test.Canvas.Entities().ship;
      assert(Omega.Ship.gfx[ship.type].trajectory1).isOfType(Omega.ShipTrajectory);
      assert(Omega.Ship.gfx[ship.type].trajectory2).isOfType(Omega.ShipTrajectory);
    });

    //it("creates progress bar for ship hp", function(){ // NIY
    //  var ship = Omega.Test.Canvas.Entities().ship;
    //  assert(Omega.Ship.gfx[ship.type].hp_bar).isOfType(Omega.UI.Canvas.ProgressBar);
    //})
  });

  describe("#init_gfx", function(){
    var type = 'corvette';
    var ship;

    before(function(){
      /// preiinit using test page
      Omega.Test.Canvas.Entities();

      ship = new Omega.Ship({type: type,
        location : new Omega.Location({x: 100, y: -100, z: 200})});
    });

    after(function(){
      if(Omega.Ship.gfx[type].mesh.clone.restore)
        Omega.Ship.gfx[type].mesh.clone.restore();

      if(Omega.Ship.gfx[type].highlight.clone.restore)
        Omega.Ship.gfx[type].highlight.clone.restore();

      for(var l = 0; l < Omega.Ship.gfx[type].lamps.length; l++)
        if(Omega.Ship.gfx[type].lamps[l].clone.restore)
          Omega.Ship.gfx[type].lamps[l].clone.restore();

      if(Omega.Ship.gfx[type].lamps.clone.restore)
        Omega.Ship.gfx[type].lamps.clone.restore();

      if(Omega.Ship.gfx[type].trails.clone.restore)
        Omega.Ship.gfx[type].trails.clone.restore();

      if(Omega.Ship.gfx[type].attack_vector.clone.restore)
        Omega.Ship.gfx[type].attack_vector.clone.restore();

      if(Omega.Ship.gfx[type].mining_vector.clone.restore)
        Omega.Ship.gfx[type].mining_vector.clone.restore();

      if(Omega.Ship.gfx[type].trajectory1.clone.restore)
        Omega.Ship.gfx[type].trajectory1.clone.restore();

      if(Omega.Ship.gfx[type].trajectory2.clone.restore)
        Omega.Ship.gfx[type].trajectory2.clone.restore();

      if(Omega.Ship.gfx[type].hp_bar.clone.restore)
        Omega.Ship.gfx[type].hp_bar.clone.restore();

      if(Omega.Ship.prototype.retrieve_resource.restore)
        Omega.Ship.prototype.retrieve_resource.restore();
    });

    it("loads ship gfx", function(){
      sinon.spy(ship, 'load_gfx');
      ship.init_gfx(Omega.Config);
      sinon.assert.called(ship.load_gfx);
    });

    it("clones template mesh", function(){
      var mesh   = new Omega.ShipMesh({mesh: new THREE.Mesh()});
      var cloned = new Omega.ShipMesh({mesh: new THREE.Mesh()});

      sinon.stub(Omega.Ship.prototype, 'retrieve_resource');
      ship.init_gfx(Omega.Config);
      sinon.assert.calledWith(Omega.Ship.prototype.retrieve_resource,
                              'template_mesh_' + ship.type,
                              sinon.match.func);

      var clone = sinon.stub(mesh, 'clone').returns(cloned);
      Omega.Ship.prototype.retrieve_resource.omega_callback()(mesh);
      assert(ship.mesh).equals(cloned);
    });

    it("sets mesh base position/rotation", function(){
      ship.init_gfx(Omega.Config);
      var template_mesh = Omega.Ship.gfx[ship.type].mesh;
      assert(ship.mesh.base_position).equals(template_mesh.base_position);
      assert(ship.mesh.base_rotation).equals(template_mesh.base_rotation);
    });

    it("sets mesh omega_entity", function(){
      ship.init_gfx(Omega.Config);
      assert(ship.mesh.omega_entity).equals(ship);
    });

    it("updates_gfx in mesh cb", function(){
      sinon.stub(Omega.Ship.prototype, 'retrieve_resource');
      ship.init_gfx(Omega.Config, type);
      var mesh_cb = Omega.Ship.prototype.retrieve_resource.omega_callback();

      sinon.spy(ship, 'update_gfx');
      mesh_cb(Omega.Ship.gfx[ship.type].mesh);
      sinon.assert.called(ship.update_gfx);
    });

    it("adds mesh to components", function(){
      ship.init_gfx(Omega.Config);
      assert(ship.components).includes(ship.mesh.tmesh);
    });

    it("clones Ship highlight effects", function(){
      var mesh = new Omega.ShipHighlightEffects();
      sinon.stub(Omega.Ship.gfx[type].highlight, 'clone').returns(mesh);
      ship.init_gfx(Omega.Config);
      assert(ship.highlight).equals(mesh);
    });

    it("sets omega_entity on highlight effects", function(){
      ship.init_gfx(Omega.Config);
      assert(ship.highlight.omega_entity).equals(ship);
    });

    it("clones Ship lamps", function(){
      var lamps = new Omega.ShipLamps();
      sinon.stub(Omega.Ship.gfx[ship.type].lamps, 'clone').returns(lamps);
      ship.init_gfx(Omega.Config);
      assert(ship.lamps).equals(lamps);
    });

    /// it("initializes lamp graphics"); NIY

    it("clones Ship trails", function(){
      var trails = new Omega.ShipTrails();
      sinon.stub(Omega.Ship.gfx[ship.type].trails, 'clone').returns(trails);
      ship.init_gfx(Omega.Config);
      assert(ship.trails).equals(trails);
    });

    it("clones Ship attack vector", function(){
      var mesh = new Omega.ShipAttackVector();
      sinon.stub(Omega.Ship.gfx[type].attack_vector, 'clone').returns(mesh);
      ship.init_gfx(Omega.Config);
      assert(ship.attack_vector).equals(mesh);
    });

    it("clones Ship mining vector", function(){
      var mesh = new Omega.ShipMiningVector();
      sinon.stub(Omega.Ship.gfx[type].mining_vector, 'clone').returns(mesh);
      ship.init_gfx(Omega.Config);
      assert(ship.mining_vector).equals(mesh);
    });

    it("clones Ship trajectory vectors", function(){
      var line1 = Omega.Ship.gfx[type].trajectory1.clone();
      var line2 = Omega.Ship.gfx[type].trajectory1.clone();
      sinon.stub(Omega.Ship.gfx[type].trajectory1, 'clone').returns(line1);
      sinon.stub(Omega.Ship.gfx[type].trajectory2, 'clone').returns(line2);
      ship.init_gfx(Omega.Config);
      assert(ship.trajectory1).equals(line1);
      assert(ship.trajectory2).equals(line2);
    });

    describe("debug graphics are enabled", function(){
      it("adds trajectory graphics to mesh", function(){
        ship.debug_gfx = true;
        ship.init_gfx(Omega.Config);
        assert(ship.mesh.tmesh.getDescendants()).includes(ship.trajectory1.mesh);
        assert(ship.mesh.tmesh.getDescendants()).includes(ship.trajectory2.mesh);
      });
    });

    it("clones Ship hp progress bar", function(){
      var hp_bar = Omega.Ship.gfx[type].hp_bar.clone(); 
      sinon.stub(Omega.Ship.gfx[type].hp_bar, 'clone').returns(hp_bar);
      ship.init_gfx(Omega.Config);
      assert(ship.hp_bar).equals(hp_bar);
    });

    it("sets scene components to ship mesh, attack_vector, mining_vector, destruction, explosions, smoke", function(){
      ship.init_gfx(Omega.Config);
      assert(ship.components).includes(ship.mesh.tmesh);
      assert(ship.components).includes(ship.attack_vector.particles.mesh);
      assert(ship.components).includes(ship.mining_vector.particles.mesh);
      assert(ship.components).includes(ship.destruction.particles.mesh);
      assert(ship.components).includes(ship.explosions.particles.mesh);
      assert(ship.components).includes(ship.smoke.particles.mesh);
    });

    it("adds highlight, hp bar, lamps to mesh", function(){
      ship.init_gfx(Omega.Config);
      var descendants = ship.mesh.tmesh.getDescendants();
      assert(descendants).includes(ship.highlight.mesh);
      assert(descendants).includes(ship.hp_bar.bar.component1);
      assert(descendants).includes(ship.hp_bar.bar.component2);
      for(var l = 0; l < ship.lamps.olamps.length; l++)
        assert(descendants).includes(ship.lamps.olamps[l].component);
    });

    it("updates_gfx", function(){
      sinon.spy(ship, 'update_gfx');
      ship.init_gfx(Omega.Config);
      sinon.assert.called(ship.update_gfx);
    });
  });

  describe("#cp_gfx", function(){
    var orig, ship;
    before(function(){
      orig = {components        : 'components',
              shader_components : 'shader_components',
              mesh              : 'mesh',
              highlight         : 'highlight',
              lamps             : 'lamp',
              trails            : 'trails',
              attack_vector     : 'attack_vector',
              mining_vector     : 'mining_vector',
              trajectory1       : 'trajectory1',
              trajectory2       : 'trajectory2',
              hp_bar            : 'hp_bar' };
      ship = new Omega.Ship();
    });

    it("copies components from specified entity", function(){
      ship.cp_gfx(orig);
      assert(ship.components).equals(orig.components);
    });

    it("copies shader components from specified entity", function(){
      ship.cp_gfx(orig);
      assert(ship.shader_components).equals(orig.shader_components);
    });

    it("copies mesh from specified entity", function(){
      ship.cp_gfx(orig);
      assert(ship.mesh).equals(orig.mesh);
    });

    it("copies highlight from specified entity", function(){
      ship.cp_gfx(orig);
      assert(ship.highlight).equals(orig.highlight);
    });

    it("copies lamps from specified entity", function(){
      ship.cp_gfx(orig);
      assert(ship.lamps).equals(orig.lamps);
    });

    it("copies trails from specified entity", function(){
      ship.cp_gfx(orig);
      assert(ship.trails).equals(orig.trails);
    });

    it("copies attack_vector from specified entity", function(){
      ship.cp_gfx(orig);
      assert(ship.attack_vector).equals(orig.attack_vector);
    });

    it("copies mining_vector from specified entity", function(){
      ship.cp_gfx(orig);
      assert(ship.mining_vector).equals(orig.mining_vector);
    });

    it("copies trajectories from specified entity", function(){
      ship.cp_gfx(orig);
      assert(ship.trajectory1).equals(orig.trajectory1);
      assert(ship.trajectory2).equals(orig.trajectory2);
    });

    it("copies hp bar from specified entity", function(){
      ship.cp_gfx(orig);
      assert(ship.hp_bar).equals(orig.hp_bar);
    });
  });

  describe("#run_effects", function(){
    it("runs lamp effects", function(){
      var ship = new Omega.Ship({type : 'corvette', location :
                   new Omega.Location({movement_strategy : {}})});
      ship.init_gfx(Omega.Config);

      var spies = [];
      for(var l = 0; l < ship.lamps.olamps.length; l++)
        spies.push(sinon.spy(ship.lamps.olamps[l], 'run_effects'))

      ship.run_effects();

      for(var s = 0; s < spies.length; s++)
        sinon.assert.called(spies[s]);
    });

    /// it("runs trail effects"); // NIY
    /// it("moves ship according to movement strategy"); // NIY
    /// it("runs attack effects"); // NIY
    /// it("runs mining effects"); // NIY
  });

  describe("#update_gfx", function(){
    var ship;

    before(function(){
      ship = new Omega.Ship({type : 'corvette', location : new Omega.Location()});
      ship.init_gfx();
    });

    it("updates mesh", function(){
      var update = sinon.spy(ship.mesh, 'update');
      ship.update_gfx();
      sinon.assert.called(update);
    });

    it("updates hp bar", function(){
      var update = sinon.spy(ship.hp_bar, 'update');
      ship.update_gfx();
      sinon.assert.called(update);
    });

    it("updates command vectors", function(){
      var update_attack = sinon.spy(ship.attack_vector, 'update');
      var update_mining = sinon.spy(ship.mining_vector, 'update');
      ship.update_gfx();
      sinon.assert.called(update_attack);
      sinon.assert.called(update_mining);
    });
  });
});});
