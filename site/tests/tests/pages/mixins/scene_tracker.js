pavlov.specify("Omega.Pages.SceneTracker", function(){
describe("Omega.Pages.SceneTracker", function(){
  describe("#handle_scene_changes", function(){
    var page;

    before(function(){
      page = $.extend({canvas : new Omega.UI.Canvas()}, Omega.Pages.SceneTracker);
    });

    it("wires up canvas scene change", function(){
      assert(page.canvas._listeners).isUndefined();
      page.handle_scene_changes();
      assert(page.canvas._listeners['set_scene_root'].length).equals(1);
    });

    describe("on canvas scene change", function(){
      it("invokes page.scene_change", function(){
        page.handle_scene_changes();
        var scene_changed_cb = page.canvas._listeners['set_scene_root'][0];
        var scene_change = sinon.stub(page, 'scene_change');
        scene_changed_cb({data: 'change'});
        sinon.assert.calledWith(scene_change, 'change')
      });
    })
  });

  describe("#scene_change", function(){
    //// TODO update
    var page, system, old_system, change, entity_map;
    var orig_page;

    before(function(){
      page = $.extend({canvas : new Omega.UI.Canvas(),
                       audio_controls : new Omega.UI.AudioControls()},
                       Omega.Pages.SceneTracker, Omega.Pages.HasRegistry);
      page.process_entities = sinon.stub(); /// stub'd out entity processor
      orig_page = page.canvas.page;
      page.canvas.page = page;

      system     = Omega.Gen.solar_system();
      old_system = Omega.Gen.solar_system();
      change     = {root: system, old_root: old_system}
      entity_map = {};

      sinon.stub(page, 'entity_map').returns(entity_map);
      sinon.stub(page, 'track_system_events');
      sinon.stub(page, 'stop_tracking_system_events');
      sinon.stub(page, 'stop_tracking_scene_entities');
      sinon.stub(page, 'sync_scene_entities');
      sinon.stub(page, 'sync_scene_planets');
      sinon.stub(page.audio_controls, 'play');

      sinon.stub(page.canvas, 'remove');
      sinon.stub(page.canvas, 'add');
      sinon.stub(page.canvas.skybox, 'set');
    });

    after(function(){
      page.canvas.page = orig_page;
      page.canvas.remove.restore();
      page.canvas.add.restore();
      page.canvas.skybox.set.restore();
    });

    describe("changing scene to system", function(){
      it("starts tracking system events", function(){
        page.scene_change(change);
        sinon.assert.calledWith(page.track_system_events, change.root);
      });

      it("processes sync'd scene entities", function(){
        var retrieved = {};
        page.scene_change(change)
        page.sync_scene_entities.omega_callback()(retrieved);
        sinon.assert.calledWith(page.process_entities, retrieved);
      });

      it("syncs scene planets", function(){
        page.scene_change(change);
        sinon.assert.calledWith(page.sync_scene_planets, change.root);
      });

      it("syncs scene entities", function(){
        page.scene_change(change)
        sinon.assert.calledWith(page.sync_scene_entities,
                                change.root, entity_map);
      });

      it("sets scene skybox background", function(){
        page.scene_change(change);
        sinon.assert.calledWith(page.canvas.skybox.set, change.root.bg);
      });

      it("adds skybox to scene", function(){
        page.scene_change(change);
        sinon.assert.calledWith(page.canvas.add, page.canvas.skybox);
      });
    })

    describe("changing scene from system", function(){
      it("stops tracking old system events", function(){
        page.scene_change(change);
        sinon.assert.calledWith(page.stop_tracking_system_events);
      });

      it("stops tracking old scene entities", function(){
        page.scene_change(change)
        sinon.assert.calledWith(page.stop_tracking_scene_entities, entity_map);
      });
    });

    describe("changing scene from galaxy", function(){
      it("removes galaxy from scene entities", function(){
        change.old_root = new Omega.Galaxy();
        page.scene_change(change);
        sinon.assert.calledWith(page.canvas.remove, change.old_root);
      });
    });

    describe("changing scene to galaxy", function(){
      it("adds galaxy to scene entities", function(){
        change.root = new Omega.Galaxy();
        page.scene_change(change);
        sinon.assert.calledWith(page.canvas.add, change.root);
      });
    });

    describe("no existing old scene root", function(){
      it("starts playing background audio", function(){
        change.old_root = null;
        page.scene_change(change);
        sinon.assert.calledWith(page.audio_controls.play,
                                page.audio_controls.effects.background);
      });
    });

    it("adds star dust to scene", function(){
      page.scene_change(change);
      sinon.assert.calledWith(page.canvas.add, page.canvas.star_dust);
    });
  });

  describe("#_scale_entity", function(){
    var entity, page;

    before(function(){
      entity = Omega.Gen.ship();
      page = $.extend({}, Omega.Pages.HasRegistry, Omega.Pages.SceneTracker, Omega.Pages.TracksCam);
      page.init_registry();
      page.scene_scale = 10;
    });

    it("scales entity scene location", function(){
      var sl = entity.scene_location();
      page._scale_entity(entity);
      assert(entity._scene_location()).equals(sl);
      entity.location.set(100, 100, 200);
      assert(entity.scene_location().coordinates()).
        isSameAs([10, 10, 20]);
    });

    it("scales entity orbit", function(){
      entity.orbit = [];
      entity.orbit_line = new Omega.OrbitLine({orbit : entity.orbit});
      page._scale_entity(entity);
      assert(entity.orbit_line.line.scale.x).equals(0.1)
      assert(entity.orbit_line.line.scale.y).equals(0.1);
      assert(entity.orbit_line.line.scale.z).equals(0.1);
    });

    it("updates entity graphics", function(){
      sinon.stub(entity, 'gfx_initialized').returns(true);
      sinon.stub(entity, 'update_gfx');
      page._scale_entity(entity);
      sinon.assert.called(entity.update_gfx);
    });
  });
});});
