pavlov.specify("Omega.JumpGate", function(){
describe("Omega.JumpGate", function(){
  var jg, page;

  before(function(){
    jg = Omega.Gen.jump_gate();
    jg.endpoint_id = 'system2';
    jg.location.set(100, -200, 50.5678)

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

  describe("#endpoint_title", function(){
    describe("endpoint system set", function(){
      //it("returns name of endpoint system"); NIY
    });

    describe("endpoing system not set", function(){
      //it("returns endpoint_id"); NIY
    });
  });

  describe("#selected", function(){
    it("reloads jg in scene", function(){
      jg.init_gfx(Omega.Config);
      var reload = sinon.spy(page.canvas, 'reload');
      jg.selected(page);
      sinon.assert.calledWith(reload, jg, sinon.match.func);
    });

    describe("reload callback", function(){
      it("adds selection sphere to jg mesh", function(){
        jg.init_gfx(Omega.Config);
        var reload = sinon.stub(page.canvas, 'reload');
        jg.selected(page);

        var during_reload = reload.getCall(0).args[1];
        assert(jg.mesh.tmesh.getDescendants()).
          doesNotInclude(jg.selection.tmesh);
        during_reload();
        assert(jg.mesh.tmesh.getDescendants()).
          includes(jg.selection.tmesh);
      });
    });
  });

  describe("#unselected", function(){
    it("reloads jg in scene", function(){
      jg.init_gfx(Omega.Config);
      var reload = sinon.spy(page.canvas, 'reload');
      jg.unselected(page);
      sinon.assert.calledWith(reload, jg, sinon.match.func);
    });

    describe("reload callback", function(){
      it("removes selection sphere from jg scene components", function(){
        jg.init_gfx(Omega.Config);
        jg.selected(page);
        assert(jg.mesh.tmesh.getDescendants()).
          includes(jg.selection.tmesh);

        var reload = sinon.spy(page.canvas, 'reload');
        jg.unselected(page);

        var during_reload = reload.getCall(0).args[1];
        during_reload();
        assert(jg.mesh.tmesh.getDescendants()).
          doesNotInclude(jg.selection.tmesh);
      });
    });
  });
});}); // Omega.JumpGate
