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
      page = $.extend({canvas : Omega.Test.Canvas(),
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
      sinon.stub(page, '_scale_system');
      sinon.stub(page, '_unscale_system');
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

      it("scales system", function(){
        page.scene_change(change)
        sinon.assert.calledWith(page._scale_system, change.root);
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

      it("unscales system", function(){
        page.scene_change(change)
        sinon.assert.calledWith(page._unscale_system, change.old_root);
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

  describe("#_scale_system", function(){
    var page, system;

    before(function(){
      page = $.extend({}, Omega.Pages.HasRegistry,
                          Omega.Pages.SceneTracker);
      page.init_registry();
      system = Omega.Gen.solar_system();
    });

    it("scales system children", function(){
      system.children = [Omega.Gen.star()];
      sinon.stub(page, '_scale_entity');
      page._scale_system(system);
      sinon.assert.calledWith(page._scale_entity, system.children[0]);
    });

    it("scales manu entities", function(){
      var entities = [Omega.Gen.ship()];
      sinon.stub(page, 'manu_entities').returns(entities);
      sinon.stub(page, '_scale_entity');
      page._scale_system(system);
      sinon.assert.calledWith(page._scale_entity, entities[0]);
    });
  });

  describe("#_scale_entity", function(){
    var entity, page;

    before(function(){
      entity = Omega.Gen.ship();
      page = $.extend({}, Omega.Pages.HasRegistry, Omega.Pages.SceneTracker);
      page.init_registry();
    });

    it("scales entity scene location", function(){
      var sl = entity.scene_location;
      page._scale_entity(entity);
      assert(entity._scene_location).equals(sl);
      entity.location.set(100, 100, 200);
      assert(entity.scene_location().coordinates()).
        isSameAs([100/Omega.Config.scale_system,
                  100/Omega.Config.scale_system,
                  200/Omega.Config.scale_system]);
    });

    it("scales entity orbit", function(){
      entity.orbit = [];
      entity.orbit_line = new Omega.OrbitLine({orbit : entity.orbit});
      page._scale_entity(entity);
      assert(entity.orbit_line.line.scale.x).equals(1/Omega.Config.scale_system);
      assert(entity.orbit_line.line.scale.y).equals(1/Omega.Config.scale_system);
      assert(entity.orbit_line.line.scale.z).equals(1/Omega.Config.scale_system);
    });

    it("updates entity graphics", function(){
      sinon.stub(entity, 'gfx_initialized').returns(true);
      sinon.stub(entity, 'update_gfx');
      page._scale_entity(entity);
      sinon.assert.called(entity.update_gfx);
    });
  });

  describe("#_unscale_system", function(){
    var system, page;

    before(function(){
      page = $.extend({}, Omega.Pages.HasRegistry, Omega.Pages.SceneTracker);
      system = Omega.Gen.solar_system();
    });

    it("unscales system children", function(){
      system.children = [Omega.Gen.star()];
      sinon.stub(page, "_unscale_entity");
      page._unscale_system(system);
      sinon.assert.calledWith(page._unscale_entity, system.children[0]);
    });
  });

  describe("#_unscale_entity", function(){
    var entity, page;

    before(function(){
      entity = Omega.Gen.ship();
      page = $.extend({}, Omega.Pages.HasRegistry, Omega.Pages.SceneTracker);
    });

    it("unscales entity scene location", function(){
      page._scale_entity(entity);

      var sl = entity._scene_location;
      page._unscale_entity(entity);
      assert(entity._scene_location).isNull();
      assert(entity.scene_location).equals(sl);
    });

    it("unscales entity orbit", function(){
      entity.orbit = [];
      entity.orbit_line = new Omega.OrbitLine({orbit : entity.orbit});
      page._scale_entity(entity);
      page._unscale_entity(entity);
      assert(entity.orbit_line.line.scale.x).equals(1);
      assert(entity.orbit_line.line.scale.y).equals(1);
      assert(entity.orbit_line.line.scale.z).equals(1);
    });
  });

});});
