pavlov.specify("Omega.JumpGate", function(){
describe("Omega.JumpGate", function(){
  var jg;

  before(function(){
    jg = Omega.Gen.jump_gate();
    jg.endpoint_id = 'system2';
    jg.location.set(100, -200, 50.5678)
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

  describe("#endpoint_title", function(){
    describe("endpoint system set", function(){
      //it("returns name of endpoint system"); NIY
    });

    describe("endpoing system not set", function(){
      //it("returns endpoint_id"); NIY
    });
  });

  describe("#_has_selection_sphere", function(){
    describe("selection sphere is a child of jg scene mesh", function(){
      it("returns true", function(){
        jg.init_gfx();
        jg._add_selection_sphere();
        assert(jg._has_selection_sphere()).isTrue();
      });
    });

    describe("selection sphere is not a child of jg scene mesh", function(){
      it("returns false", function(){
        jg.init_gfx();
        assert(jg._has_selection_sphere()).isFalse();
      });
    });
  });

  describe("#_add_selection_sphere", function(){
    it("adds selection sphere to position tracker", function(){
      jg.init_gfx();
      assert(jg.position_tracker().children).doesNotInclude(jg.selection.tmesh);
      jg._add_selection_sphere();
      assert(jg.position_tracker().children).includes(jg.selection.tmesh);
    });
  });

  describe("#_rm_selection_sphere", function(){
    it("removes selection sphere from scene mesh children", function(){
      jg.init_gfx();
      jg._add_selection_sphere();
      jg._rm_selection_sphere();
      assert(jg.position_tracker().children).doesNotInclude(jg.selection.tmesh);
    });
  });

  describe("#clicked_in", function(){
    var page;

    before(function(){
      page = new Omega.Pages.Test();
      sinon.stub(page.canvas, 'follow_entity');
    });

    it("instructs canvas to follow jg entity", function(){
      jg.clicked_in(page.canvas);
      sinon.assert.calledWith(page.canvas.follow_entity, jg);
    });
  });

  describe("#selected", function(){
    var page;

    before(function(){
      page = Omega.Test.page();
      sinon.stub(page.canvas, 'follow_entity');
      sinon.stub(page.canvas, 'reload');
    });

    after(function(){
      page.canvas.follow_entity.restore();
      page.canvas.reload.restore();
    });

    it("reloads jg in scene", function(){
      jg.init_gfx();
      jg.selected(page);
      sinon.assert.calledWith(page.canvas.reload, jg, sinon.match.func);
    });

    describe("reload callback", function(){
      it("adds selection sphere", function(){
        jg.init_gfx();
        jg.selected(page);

        sinon.spy(jg, '_add_selection_sphere');
        page.canvas.reload.omega_callback()();
        sinon.assert.called(jg._add_selection_sphere);
      });

      it("only adds selection sphere once", function(){
        jg.init_gfx();
        jg.selected(page);

        sinon.spy(jg, '_add_selection_sphere');
        page.canvas.reload.omega_callback()();
        page.canvas.reload.omega_callback()();
        sinon.assert.calledOnce(jg._add_selection_sphere);
      });
    });
  });

  describe("#unselected", function(){
    var page;

    before(function(){
      page = Omega.Test.page();
      sinon.stub(page.canvas, 'reload');
    });

    after(function(){
      page.canvas.reload.restore();
    });


    it("reloads jg in scene", function(){
      jg.init_gfx();
      jg.unselected(page);
      sinon.assert.calledWith(page.canvas.reload, jg, sinon.match.func);
    });

    describe("reload callback", function(){
      it("removes selection sphere from jg scene components", function(){
        jg.init_gfx();
        jg.selected(page);
        page.canvas.reload.omega_callback()();
        assert(jg.position_tracker().children).includes(jg.selection.tmesh);

        page.canvas.reload.reset();
        jg.unselected(page);
        page.canvas.reload.omega_callback()();
        assert(jg.position_tracker().children).doesNotInclude(jg.selection.tmesh);
      });
    });
  });
});}); // Omega.JumpGate
