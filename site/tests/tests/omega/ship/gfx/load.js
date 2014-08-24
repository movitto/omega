// Test mixin usage through ship
pavlov.specify("Omega.ShipGfxLoader", function(){
describe("Omega.ShipGfxLoader", function(){
  var ship;

  before(function(){
    ship = Omega.Gen.ship();
  });

  describe("#load_gfx", function(){
    describe("graphics are loaded", function(){
      it("does nothing / just returns", function(){
        sinon.stub(ship, 'gfx_loaded').returns(true);
        sinon.spy(ship, '_loaded_gfx');
        ship.load_gfx();
        sinon.assert.notCalled(ship._loaded_gfx);
      });
    });

    it("loads Ship mesh geometry", function(){
      var event_cb = function(){};
      var geometry = Omega.ShipMesh.geometry_for(ship.type);
      sinon.stub(ship, 'gfx_loaded').returns(false);
      sinon.stub(ship, '_load_async_resource');
      ship.load_gfx(event_cb);

      var id = 'ship.' + ship.type + '.mesh_geometry';
      sinon.assert.calledWith(ship._load_async_resource, id, geometry, event_cb);
    });

    it("loads Ship missile geometry", function(){
      var event_cb = function(){};
      var geometry = Omega.ShipMissile.geometry_for(ship.type);
      sinon.stub(ship, 'gfx_loaded').returns(false);
      sinon.stub(ship, '_load_async_resource');
      ship.load_gfx(event_cb);

      var id = 'ship.' + ship.type + '.missile_geometry';
      sinon.assert.calledWith(ship._load_async_resource, id, geometry, event_cb);
    });

    it("creates highlight effects for Ship", function(){
      var ship = Omega.Test.entities()['ship'];
      var highlight = ship._retrieve_resource('highlight');
      assert(highlight).isOfType(Omega.ShipHighlightEffects);
    });

    it("creates lamps for Ship", function(){
      var ship  = Omega.Test.entities()['ship'];
      var lamps = ship._retrieve_resource('lamps');
      assert(lamps).isOfType(Omega.ShipLamps);
    });

    it("creates trails for Ship", function(){
      var ship  = Omega.Test.entities()['ship'];
      var trails = ship._retrieve_resource('trails');
      assert(trails).isOfType(Omega.ShipTrails);
    });

    it("creates attack vector for Ship", function(){
      var ship  = Omega.Test.entities()['ship'];
      var av = ship._retrieve_resource('attack_vector');
      assert(av).isOfType(Omega.ShipAttackVector);
    });

    it("creates mining vector for Ship", function(){
      var ship  = Omega.Test.entities()['ship'];
      var mv = ship._retrieve_resource('mining_vector');
      assert(mv).isOfType(Omega.ShipMiningVector);
    });

    it("creates trajectory vectors for ship", function(){
      var ship  = Omega.Test.entities()['ship'];
      var t1 = ship._retrieve_resource('trajectory1');
      var t2 = ship._retrieve_resource('trajectory2');
      assert(t1).isOfType(Omega.ShipTrajectory);
      assert(t2).isOfType(Omega.ShipTrajectory);
    });

    it("creates progress bar for ship hp", function(){
      var ship  = Omega.Test.entities()['ship'];
      var hp = ship._retrieve_resource('hp_bar');
      assert(hp).isOfType(Omega.ShipHpBar);
    });

    it("creates visited route for ship", function(){
      var ship  = Omega.Test.entities()['ship'];
      var visited = ship._retrieve_resource('visited_route');
      assert(visited).isOfType(Omega.ShipVisitedRoute);
    });

    it("creates destruction effects for ship", function(){
      var ship  = Omega.Test.entities()['ship'];
      var destruction = ship._retrieve_resource('destruction');
      assert(destruction).isOfType(Omega.ShipDestructionEffect);
    });

    it("creates explosion effects for ship", function(){
      var ship  = Omega.Test.entities()['ship'];
      var explosions = ship._retrieve_resource('explosions');
      assert(explosions).isOfType(Omega.ShipExplosionEffect);
    });

    it("creates smoke effects for ship", function(){
      var ship  = Omega.Test.entities()['ship'];
      var smoke = ship._retrieve_resource('smoke');
      assert(smoke).isOfType(Omega.ShipSmokeEffect);
    });

    it("creates docking audio for ship", function(){
      var ship  = Omega.Test.entities()['ship'];
      var audio = ship._retrieve_resource('docking_audio');
      assert(audio).isOfType(Omega.ShipDockingAudioEffect);
    });

    it("creates mining audio for ship", function(){
      var ship  = Omega.Test.entities()['ship'];
      var audio = ship._retrieve_resource('mining_audio');
      assert(audio).isOfType(Omega.ShipMiningAudioEffect);
    });

    it("creates destruction audio for ship", function(){
      var ship  = Omega.Test.entities()['ship'];
      var audio = ship._retrieve_resource('destruction_audio');
      assert(audio).isOfType(Omega.ShipDestructionAudioEffect);
    });

    it("creates mining completed audio for ship", function(){
      var ship  = Omega.Test.entities()['ship'];
      var audio = ship._retrieve_resource('mining_completed_audio');
      assert(audio).isOfType(Omega.ShipMiningCompletedAudioEffect);
    });

    it("creates combat audio for ship", function(){
      var ship  = Omega.Test.entities()['ship'];
      var audio = ship._retrieve_resource('combat_audio');
      assert(audio).isOfType(Omega.ShipCombatAudioEffect);
    });

    it("creates movement audio for ship", function(){
      var ship  = Omega.Test.entities()['ship'];
      var audio = ship._retrieve_resource('movement_audio');
      assert(audio).isOfType(Omega.ShipMovementAudioEffect);
    });
  });
});});
