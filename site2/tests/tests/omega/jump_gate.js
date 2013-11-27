pavlov.specify("Omega.JumpGate", function(){
describe("Omega.JumpGate", function(){
  var jg, page;

  before(function(){
    jg = new Omega.JumpGate({id          : 'jg1',
                             endpoint_id : 'system2',
                             location    : new Omega.Location({x:100,y:-200,z:50.5678})});
    page = new Omega.Pages.Test({canvas : Omega.Test.Canvas()});
  });

  after(function(){
    if(page.canvas.reload.restore) page.canvas.reload.restore();
  });

  describe("#retrieve_details", function(){
    var details_cb;

    before(function(){
      details_cb = sinon.spy();
    });

    it("invokes details cb with jg endpoint id, location, and trigger command", function(){
      var text = 'Jump Gate to system2<br/>'  +
                 '@ 100/-200/50.57<br/><br/>';

      jg.retrieve_details(page, details_cb);
      sinon.assert.called(details_cb);

      var details = details_cb.getCall(0).args[0];
      assert(details[0]).equals(text);
      assert(details[1][0].id).equals('trigger_jg_jg1');
      assert(details[1][0].className).equals('trigger_jg');
      assert(details[1].text()).equals('Trigger');
    });

    it("sets jump gate in trigger command data", function(){
      jg.retrieve_details(page, details_cb)
      $('#qunit-fixture').append(details_cb.getCall(0).args[0]);
      assert($('#trigger_jg_jg1').data('jump_gate')).equals(jg);
    });
  });

  describe("#selected", function(){
    it("reloads jg in scene", function(){
      var reload = sinon.spy(page.canvas, 'reload');
      jg.selected(page);
      sinon.assert.calledWith(reload, jg, sinon.match.func);
    });

    describe("reload callback", function(){
      it("adds selection sphere to jg scene components", function(){
        var reload = sinon.stub(page.canvas, 'reload');
        jg.selected(page);

        var during_reload = reload.getCall(0).args[1];
        assert(jg.components).doesNotInclude(jg.selection_sphere);
        during_reload();
        assert(jg.components).includes(jg.selection_sphere);
      });
    });
  });

  describe("#unselected", function(){
    it("reloads jg in scene", function(){
      var reload = sinon.spy(page.canvas, 'reload');
      jg.unselected(page);
      sinon.assert.calledWith(reload, jg, sinon.match.func);
    });

    describe("reload callback", function(){
      it("removes selection sphere to jg scene components", function(){
        jg.selected(page);
        assert(jg.components).includes(jg.selection_sphere);

        var reload = sinon.spy(page.canvas, 'reload');
        jg.unselected(page);

        var during_reload = reload.getCall(0).args[1];
        during_reload();
        assert(jg.components).doesNotInclude(jg.selection_sphere);
      });
    });
  });

  describe("#load_gfx", function(){
    describe("graphics are initialized", function(){
      var orig;

      before(function(){
        orig = {gfx: Omega.JumpGate.gfx,
                mesh: Omega.JumpGate.gfx ? Omega.JumpGate.gfx.mesh : null};
      })

      after(function(){
        Omega.JumpGate.gfx = orig.gfx;
        if(Omega.JumpGate.gfx) Omega.JumpGate.gfx.mesh = orig.mesh;
      });

      it("does nothing / just returns", function(){
        Omega.JumpGate.gfx = {};
        Omega.JumpGate.mesh = null;
        new Omega.JumpGate().load_gfx();
        assert(Omega.JumpGate.mesh).isNull();
      });
    });

    it("creates mesh for JumpGate", async(function(){
      var jg = Omega.Test.Canvas.Entities().jump_gate;
      jg.retrieve_resource('mesh', function(){
        assert(Omega.JumpGate.gfx.mesh).isOfType(THREE.Mesh);
        assert(Omega.JumpGate.gfx.mesh.material).isOfType(THREE.MeshLambertMaterial);
        assert(Omega.JumpGate.gfx.mesh.geometry).isOfType(THREE.Geometry);
        /// TODO assert material texture & geometry src path values ?
        start();
      });
    }));

    it("creates lamp for JumpGate", function(){
      Omega.Test.Canvas.Entities();
      assert(Omega.JumpGate.gfx.lamp).isOfType(THREE.Mesh);
      assert(Omega.JumpGate.gfx.lamp.material).isOfType(THREE.MeshBasicMaterial);
      assert(Omega.JumpGate.gfx.lamp.geometry).isOfType(THREE.SphereGeometry);
    });

    it("creates particle system for JumpGate", function(){
      Omega.Test.Canvas.Entities();
      assert(Omega.JumpGate.gfx.particles).isOfType(THREE.ParticleSystem);
      assert(Omega.JumpGate.gfx.particles.material).isOfType(THREE.ParticleBasicMaterial);
      assert(Omega.JumpGate.gfx.particles.geometry).isOfType(THREE.Geometry);
    });

    it("creates selection sphere for JumpGate", function(){
      Omega.Test.Canvas.Entities();
      assert(Omega.JumpGate.gfx.selection_sphere).isOfType(THREE.Mesh);
      assert(Omega.JumpGate.gfx.selection_sphere.material).isOfType(THREE.MeshBasicMaterial);
      assert(Omega.JumpGate.gfx.selection_sphere.geometry).isOfType(THREE.SphereGeometry);
    });
  });

  describe("#init_gfx", function(){
    before(function(){
      /// preiinit using test page
      Omega.Test.Canvas.Entities();
    });

    after(function(){
      if(Omega.JumpGate.gfx){
        if(Omega.JumpGate.gfx.mesh && Omega.JumpGate.gfx.mesh.clone.restore) Omega.JumpGate.gfx.mesh.clone.restore();
        if(Omega.JumpGate.gfx.lamp.clone.restore) Omega.JumpGate.gfx.lamp.clone.restore();
        if(Omega.JumpGate.gfx.particles.clone.restore) Omega.JumpGate.gfx.particles.clone.restore();
        if(Omega.JumpGate.gfx.selection_sphere.clone.restore) Omega.JumpGate.gfx.selection_sphere.clone.restore();
      }
    });

    it("loads jump gate gfx", function(){
      var jg        = new Omega.JumpGate();
      var load_gfx  = sinon.spy(jg, 'load_gfx');
      jg.init_gfx();
      sinon.assert.called(load_gfx);
    });

    it("clones JumpGate mesh", async(function(){
      var mesh = new THREE.Mesh();
      /// need to wait till template mesh is loaded b4 wiring up stub
      Omega.JumpGate.prototype.
        retrieve_resource('template_mesh', function(){
          sinon.stub(Omega.JumpGate.gfx.mesh, 'clone').returns(mesh);
        });

      var jg = new Omega.JumpGate();
      jg.init_gfx();
      jg.retrieve_resource('mesh', function(){
        assert(jg.mesh).equals(mesh);
        start();
      });
    }));

    it("sets mesh position", async(function(){
      var jg = new Omega.JumpGate({location : new Omega.Location({x: 100, y: -100, z: 200})});
      jg.init_gfx();
      jg.retrieve_resource('mesh', function(){
        assert(jg.mesh.position.x).equals(100);
        assert(jg.mesh.position.y).equals(-100);
        assert(jg.mesh.position.z).equals(200);
        start();
      });
    }));

    it("sets mesh.omega_entity", async(function(){
      var jg = new Omega.JumpGate({});
      jg.init_gfx();
      jg.retrieve_resource('mesh', function(){
        assert(jg.mesh.omega_entity).equals(jg);
        start();
      });
    }));

    it("clones JumpGate lamp", function(){
      var mesh = new THREE.Mesh();
      sinon.stub(Omega.JumpGate.gfx.lamp, 'clone').returns(mesh);
      var jg = new Omega.JumpGate({});
      jg.init_gfx();
      assert(jg.lamp).equals(mesh);
    });

    it("sets lamp position", function(){
      var jg = new Omega.JumpGate({location : new Omega.Location({x: 100, y: -100, z: 200})});
      jg.init_gfx();
      assert(jg.lamp.position.toArray()).isSameAs([100, -100, 200])
    });

    it("clones JumpGate particles", function(){
      var mesh = new THREE.Mesh();
      sinon.stub(Omega.JumpGate.gfx.particles, 'clone').returns(mesh);
      var jg = new Omega.JumpGate({});
      jg.init_gfx();
      assert(jg.particles).equals(mesh);
    });

    it("sets particles position", function(){
      var jg = new Omega.JumpGate({location : new Omega.Location({x: 100, y: -100, z: 200})});
      jg.init_gfx();
      assert(jg.particles.position.toArray()).isSameAs([70, -125, 275]);
    });

    it("clones JumpGate selection sphere", function(){
      var mesh = new THREE.Mesh();
      sinon.stub(Omega.JumpGate.gfx.selection_sphere, 'clone').returns(mesh);
      var jg = new Omega.JumpGate({});
      jg.init_gfx();
      assert(jg.selection_sphere).equals(mesh);
    });

    it("sets selection sphere position", function(){
      var jg = new Omega.JumpGate({location : new Omega.Location({x: 100, y: -100, z: 200})});
      jg.init_gfx();
      assert(jg.selection_sphere.position.toArray()).isSameAs([80, -100, 200]);
    });

    /// it("sets selection sphere radius") NIY

    it("adds mesh, lamp, and particles to jump gate scene components", function(){
      var jg = new Omega.JumpGate({});
      jg.init_gfx();
      assert(jg.components).isSameAs([jg.mesh, jg.lamp, jg.particles]);
    });
  });

  describe("#run_effects", function(){
    it("runs lamp effects", function(){
      Omega.Test.Canvas.Entities();
      var jg = new Omega.JumpGate({});
      jg.init_gfx();
      var run_effects = sinon.spy(jg.lamp, 'run_effects');
      jg.run_effects();
      sinon.assert.called(run_effects);
    });

    //it("updates particles") // NIY
  });

});}); // Omega.JumpGate
