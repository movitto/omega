pavlov.specify("Omega.JumpGate", function(){
describe("Omega.JumpGate", function(){
  var jg, page;

  before(function(){
    jg = new Omega.JumpGate({id          : 'jg1',
                             endpoint_id : 'system2',
                             trigger_distance : 50,
                             location    : new Omega.Location({x:100,y:-200,z:50.5678})});
    page = new Omega.Pages.Test({canvas : Omega.Test.Canvas()});
  });

  after(function(){
    if(page.canvas.reload.restore) page.canvas.reload.restore();
  });

  it("converts location");

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
      assert(details[1][0].className).equals('trigger_jg details_command');
      assert(details[1].text()).equals('trigger');
    });

    it("sets jump gate in trigger command data", function(){
      jg.retrieve_details(page, details_cb)
      $('#qunit-fixture').append(details_cb.getCall(0).args[0]);
      assert($('#trigger_jg_jg1').data('jump_gate')).equals(jg);
    });

    it("handles trigger command click event", function(){
      jg.retrieve_details(page, details_cb);
      var trigger_jg = details_cb.getCall(0).args[0][1];
      assert(trigger_jg).handles('click');
    });

    describe("trigger command clicked", function(){
      it("invokes jg.trigger", function(){
        jg.retrieve_details(page, details_cb);
        $('#qunit-fixture').append(details_cb.getCall(0).args[0]);

        var trigger = sinon.stub(jg, '_trigger');
        $('#trigger_jg_jg1').click();
        sinon.assert.calledWith(trigger, page);
      });
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
      it("removes selection sphere from jg scene components", function(){
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

  describe("#trigger", function(){
    var ship1, ship2, ship3, ship4, station1;

    before(function(){
      ship1 = new Omega.Ship({user_id : 'user1',
                    location: new Omega.Location({x:100,y:-200,z:50})});
      ship2 = new Omega.Ship({user_id : 'user1',
                    location: new Omega.Location({x:105,y:-200,z:50})});
      ship3 = new Omega.Ship({user_id : 'user1',
                    location: new Omega.Location({x:1500,y:700,z:-1000})});
      ship4 = new Omega.Ship({user_id : 'user2',
                    location: new Omega.Location({x:10,y:20,z:30})});
      station1 = new Omega.Ship({user_id : 'station'});

      jg.endpoint = new Omega.SolarSystem({id : 'system2',
                          location : new Omega.Location({id : 'system2_loc'})})

      page.entities = [ship1, ship2, ship3, ship4, station1];
      page.node     = new Omega.Node();
      page.session  = new Omega.Session({user_id : 'user1'});
    });

    it("invokes manufactured::move_entity on all user owned ships in vicinity of gate", function(){
      var http_invoke = sinon.spy(page.node, 'http_invoke');
      jg._trigger(page);
      sinon.assert.calledWith(http_invoke, 'manufactured::move_entity', ship1.id, ship1.location, sinon.match.func);
      sinon.assert.calledWith(http_invoke, 'manufactured::move_entity', ship2.id, ship2.location, sinon.match.func);
      sinon.assert.neverCalledWith(http_invoke, 'manufactured::move_entity', ship3);
      sinon.assert.neverCalledWith(http_invoke, 'manufactured::move_entity', ship4);
      sinon.assert.neverCalledWith(http_invoke, 'manufactured::move_entity', station1);
    });

    describe("on manufactured::move_entity response", function(){
      var handler, error_response, success_response;

      before(function(){
        var spy = sinon.stub(page.node, 'http_invoke');
        jg._trigger(page);
        handler = spy.getCall(0).args[3];

        error_response = {error : {message : "jg_error"}};
        success_response = {result : null};
      });

      after(function(){
        Omega.UI.Dialog.remove();
      });

      describe("error during commend", function(){
        it("sets command dialog title", function(){
          handler(error_response);
          assert(jg.dialog().title).equals('Jump Gate Trigger Error');
        });

        it("shows command dialog", function(){
          var show = sinon.spy(jg.dialog(), 'show_error_dialog');
          handler(error_response);
          sinon.assert.called(show);
          assert(jg.dialog().component()).isVisible();
        });

        it("appends error to command dialog", function(){
          var append_error = sinon.spy(jg.dialog(), 'append_error');
          handler(error_response);
          sinon.assert.calledWith(append_error, 'jg_error');
          assert($('#command_error').html()).equals('jg_error');
        });
      })

      describe("successful command response", function(){
        after(function(){
          if(page.canvas.remove.restore) page.canvas.remove.restore();
        });

        it("sets new system on registry ship", function(){
          handler(success_response);
          assert(ship1.system_id).equals('system2');
        });

        it("removes ship from canvas scene", function(){
          var spy = sinon.spy(page.canvas, 'remove');
          handler(success_response);
          sinon.assert.calledWith(spy, ship1);
        });
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

    it("creates selection sphere material for JumpGate", function(){
      Omega.Test.Canvas.Entities();
      assert(Omega.JumpGate.gfx.selection_sphere_material).isOfType(THREE.MeshBasicMaterial);
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
      var offset = Omega.Config.resources.jump_gate.offset;
      var jg = new Omega.JumpGate({location : new Omega.Location({x: 100, y: -100, z: 200})});
      jg.init_gfx();
      jg.retrieve_resource('mesh', function(){
        assert(jg.mesh.position.x).equals(100  + offset[0]);
        assert(jg.mesh.position.y).equals(-100 + offset[1]);
        assert(jg.mesh.position.z).equals(200  + offset[2]);
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

    it("adds mesh to components");

    it("clones JumpGate lamp", function(){
      var mesh = new THREE.Mesh();
      sinon.stub(Omega.JumpGate.gfx.lamp, 'clone').returns(mesh);
      var jg = new Omega.JumpGate({});
      jg.init_gfx();
      assert(jg.lamp).equals(mesh);
    });

    it("sets lamp position", function(){
      var offset = Omega.JumpGate.prototype.gfx_props;
      var jg = new Omega.JumpGate({location : new Omega.Location({x: 100, y: -100, z: 200})});
      jg.init_gfx();
      assert(jg.lamp.position.toArray()).isSameAs([100  + offset.lamp_x,
                                                   -100 + offset.lamp_y,
                                                   200  + offset.lamp_z])
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

    it("creates a selection sphere for jg", function(){
      var jg = new Omega.JumpGate({});
      jg.init_gfx();
      assert(jg.selection_sphere).isOfType(THREE.Mesh);
      assert(jg.selection_sphere.geometry).isOfType(THREE.SphereGeometry);
      assert(jg.selection_sphere.material).equals(Omega.JumpGate.gfx.selection_sphere_material);
    });

    it("sets selection sphere position", function(){
      var jg = new Omega.JumpGate({location : new Omega.Location({x: 100, y: -100, z: 200})});
      jg.init_gfx();
      assert(jg.selection_sphere.position.toArray()).isSameAs([80, -100, 200]);
    });

    /// it("sets selection sphere radius") NIY

    it("adds lamp, and particles to jump gate scene components", function(){
      var jg = new Omega.JumpGate({});
      jg.init_gfx();
      assert(jg.components).isSameAs([jg.lamp, jg.particles]);
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
