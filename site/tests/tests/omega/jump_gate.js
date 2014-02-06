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

  it("converts location", function(){
    var jump_gate = new Omega.JumpGate({location : {json_class : 'Motel::Location', data : {x: 10, y: 20, z:30}}});
    assert(jump_gate.location).isOfType(Omega.Location);
    assert(jump_gate.location.x).equals(10);
    assert(jump_gate.location.y).equals(20);
    assert(jump_gate.location.z).equals(30);
  });

  describe("#toJSON", function(){
    it("returns jump gate json data", function(){
      var jg  = {id          : 'jg1',
                 name        : 'jg1n',
                 parent_id   : 'sys1',
                 location    : new Omega.Location({id : 'jg1l'}),
                 endpoint_id : 'sys2',
                 trigger_distance : 42};

      var ojg  = new Omega.JumpGate(jg);
      var json = ojg.toJSON();

      jg.json_class  = ojg.json_class;
      jg.location    = jg.location.toJSON();
      assert(json).isSameAs(jg);
    });
  });

  describe("#retrieve_details", function(){
    var details_cb;

    before(function(){
      details_cb = sinon.spy();
      page.session = new Omega.Session();
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

    describe("page session is null", function(){
      it("does not invoke details with trigger command", function(){
        page.session = null;
        jg.retrieve_details(page, details_cb);
        assert(details_cb.getCall(0).args[0].length).equals(1);
      });
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
      jg.init_gfx();
      var reload = sinon.spy(page.canvas, 'reload');
      jg.selected(page);
      sinon.assert.calledWith(reload, jg, sinon.match.func);
    });

    describe("reload callback", function(){
      it("adds selection sphere to jg scene components", function(){
        jg.init_gfx();
        var reload = sinon.stub(page.canvas, 'reload');
        jg.selected(page);

        var during_reload = reload.getCall(0).args[1];
        assert(jg.components).doesNotInclude(jg.selection.tmesh);
        during_reload();
        assert(jg.components).includes(jg.selection.tmesh);
      });
    });
  });

  describe("#unselected", function(){
    it("reloads jg in scene", function(){
      jg.init_gfx();
      var reload = sinon.spy(page.canvas, 'reload');
      jg.unselected(page);
      sinon.assert.calledWith(reload, jg, sinon.match.func);
    });

    describe("reload callback", function(){
      it("removes selection sphere from jg scene components", function(){
        jg.init_gfx();
        jg.selected(page);
        assert(jg.components).includes(jg.selection.tmesh);

        var reload = sinon.spy(page.canvas, 'reload');
        jg.unselected(page);

        var during_reload = reload.getCall(0).args[1];
        during_reload();
        assert(jg.components).doesNotInclude(jg.selection.tmesh);
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

    it("creates mesh for JumpGate", function(){
      var jg = Omega.Test.Canvas.Entities().jump_gate;
      assert(Omega.JumpGate.gfx.mesh).isOfType(Omega.JumpGateMesh);
      assert(Omega.JumpGate.gfx.mesh.tmesh).isOfType(THREE.Mesh);
      assert(Omega.JumpGate.gfx.mesh.tmesh.material).isOfType(THREE.MeshLambertMaterial);
      assert(Omega.JumpGate.gfx.mesh.tmesh.geometry).isOfType(THREE.Geometry);
      /// TODO assert material texture & geometry src path values ?
    });

    it("creates lamp for JumpGate", function(){
      Omega.Test.Canvas.Entities();
      assert(Omega.JumpGate.gfx.lamp).isOfType(Omega.JumpGateLamp);
      assert(Omega.JumpGate.gfx.lamp.olamp).isOfType(Omega.UI.CanvasLamp);
    });

    it("creates particle system for JumpGate", function(){
      Omega.Test.Canvas.Entities();
      assert(Omega.JumpGate.gfx.particles).isOfType(Omega.JumpGateParticles);
      assert(Omega.JumpGate.gfx.particles.particle_system).isOfType(THREE.ParticleSystem);
      assert(Omega.JumpGate.gfx.particles.particle_system.material).isOfType(THREE.ParticleBasicMaterial);
      assert(Omega.JumpGate.gfx.particles.particle_system.geometry).isOfType(THREE.Geometry);
    });

    it("creates selection material for JumpGate", function(){
      Omega.Test.Canvas.Entities();
      assert(Omega.JumpGate.gfx.selection_material).isOfType(Omega.JumpGateSelectionMaterial);
    });
  });

  describe("#init_gfx", function(){
    var jg;

    before(function(){
      /// preiinit using test page
      Omega.Test.Canvas.Entities();

      jg = new Omega.JumpGate({location :
             new Omega.Location({x: 100, y: -100, z: 200,
                                 orientation_x : 0,
                                 orientation_y : 0,
                                 orientation_z : 1})});
    });

    after(function(){
      if(Omega.JumpGate.gfx){
        if(Omega.JumpGate.gfx.mesh && Omega.JumpGate.gfx.mesh.clone.restore) Omega.JumpGate.gfx.mesh.clone.restore();
        if(Omega.JumpGate.gfx.lamp.clone.restore) Omega.JumpGate.gfx.lamp.clone.restore();
        if(Omega.JumpGate.gfx.particles.clone.restore) Omega.JumpGate.gfx.particles.clone.restore();
      }
    });

    it("loads jump gate gfx", function(){
      var load_gfx  = sinon.spy(jg, 'load_gfx');
      jg.init_gfx();
      sinon.assert.called(load_gfx);
    });

    it("clones JumpGate mesh", function(){
      var mesh = new Omega.JumpGateMesh(new THREE.Mesh());
      /// need to wait till template mesh is loaded b4 wiring up stub
      Omega.JumpGate.prototype.
        retrieve_resource('template_mesh', function(){
          sinon.stub(Omega.JumpGate.gfx.mesh, 'clone').returns(mesh);
        });

      jg.init_gfx();
      assert(jg.mesh).equals(mesh);
    });

    it("sets mesh position", function(){
      var offset = Omega.Config.resources.jump_gate.offset;
      jg.init_gfx();
      assert(jg.mesh.tmesh.position.x).equals(100  + offset[0]);
      assert(jg.mesh.tmesh.position.y).equals(-100 + offset[1]);
      assert(jg.mesh.tmesh.position.z).equals(200  + offset[2]);
    });

    it("sets mesh.omega_entity", function(){
      jg.init_gfx();
      assert(jg.mesh.omega_entity).equals(jg);
    });

    it("adds mesh to components", function(){
      jg.init_gfx();
      assert(jg.components).includes(jg.mesh.tmesh);
    });

    it("clones JumpGate lamp", function(){
      var lamp = new Omega.JumpGateLamp();
      sinon.stub(Omega.JumpGate.gfx.lamp, 'clone').returns(lamp);
      jg.init_gfx();
      assert(jg.lamp).equals(lamp);
    });

    it("sets lamp position", function(){
      var offset = Omega.JumpGateGfx.gfx_props;
      jg.init_gfx();
      assert(jg.lamp.olamp.component.position.toArray()).
        isSameAs([ 100  + offset.lamp_x,
                  -100  + offset.lamp_y,
                   200  + offset.lamp_z])
    });

    it("clones JumpGate particles", function(){
      var mesh = new Omega.JumpGateParticles();
      sinon.stub(Omega.JumpGate.gfx.particles, 'clone').returns(mesh);
      jg.init_gfx();
      assert(jg.particles).equals(mesh);
    });

    it("sets particles position", function(){
      jg.init_gfx();
      assert(jg.particles.particle_system.position.toArray()).
        isSameAs([90, -125, 275]);
    });

    it("creates a selection sphere for jg", function(){
      jg.init_gfx();
      assert(jg.selection).isOfType(Omega.JumpGateSelection);
      assert(jg.selection.tmesh).isOfType(THREE.Mesh);
      assert(jg.selection.tmesh.geometry).isOfType(THREE.SphereGeometry);
      assert(jg.selection.tmesh.material).
        equals(Omega.JumpGate.gfx.selection_material.material);
    });

    it("sets selection sphere position", function(){
      jg.init_gfx();
      assert(jg.selection.tmesh.position.toArray()).
        isSameAs([80, -100, 200]);
    });

    /// it("sets selection sphere radius") NIY

    it("adds lamp, and particles to jump gate scene components", function(){
      jg.init_gfx();
      assert(jg.components).includes(jg.lamp.olamp.component);
      assert(jg.components).includes(jg.particles.particle_system);
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
