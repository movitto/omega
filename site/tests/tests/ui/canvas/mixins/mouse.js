pavlov.specify("Omega.UI.Canvas", function(){
describe("Omega.UI.Canvas", function(){
  var canvas;

  before(function(){
    canvas = Omega.Test.canvas();
  });

  //describe("canvas clicked", function(){
  //  it("invokes _canvas_clicked"); // NIY
  //});

  //describe("mouse leaves canvas area", function(){
  //  it("triggers mouse up event"); // NIY
  //});

  //describe("mouse moves in canvas area", function(){
  //  it("updates mouse coordinates"); // NIY
  //});

  // NIY
  //describe("canvas clicked", function(){
  //  describe("click does not intersect omega entity", function(){
  //    it("does nothing")
  //  })

  //  describe("left click", function(){
  //    it("invokes _clicked_entity w/ clicked entity");
  //  })

  //  describe("right click", function(){
  //    it("invokes _rclicked_entity w/ clicked entity")
  //  });
  //});

  //describe("#detect hover", function(){
  //  describe("mouse coordinates do not intersect omega entity", function(){
  //    describe("previously hovering over entity", function(){
  //      it("invokes _unhovered_over w/ previously hovered entity")
  //      it("sets hover num to 0")
  //      it("clears hovered entity")
  //    });

  //    describe("not previously hovering over entity", function(){
  //      it("does nothing");
  //    });
  //  });

  //  describe("mouse coordinates intersect omega entity", function(){
  //    it("sets hovered entity")
  //    describe("hovering over a new entity", function(){
  //      it("sets hover num to 1")
  //    });
  //    describe("still hovering over same entity", function(){
  //      it("increments hover num")
  //    });

  //    it("invokes _hovered_over with entity")
  //  });
  //});

  describe("#_clicked_entity", function(){
    var entity;

    before(function(){
      entity = Omega.Gen.ship();
      canvas = new Omega.UI.Canvas({page : new Omega.Pages.Test()});
      sinon.stub(canvas.entity_container, 'show');
    });

    describe("entity has details", function(){
      it("shows entity container", function(){
        canvas._clicked_entity(entity);
        sinon.assert.calledWith(canvas.entity_container.show, entity);
      });
    });

    it("invokes entity clicked_in callback", function(){
      sinon.stub(entity, 'clicked_in');
      canvas._clicked_entity(entity);
      sinon.assert.calledWith(entity.clicked_in, canvas);
    });

    it("dispatches 'click' event to entity", function(){
      var cb = sinon.spy();
      entity.addEventListener('click', cb);
      canvas._clicked_entity(entity);
      sinon.assert.called(cb);
    });
  });

  describe("#_rclicked_entity", function(){
    var orig_entity, entity, canvas;

    before(function(){
      entity = Omega.Gen.ship();
      target = Omega.Gen.ship();
      canvas = new Omega.UI.Canvas({page : new Omega.Pages.Test()});

      entity.init_gfx();
      canvas.entity_container.show(entity)
    });

    it("invokes selected context_action callback", function(){
      sinon.stub(entity, 'context_action');
      canvas._rclicked_entity(target);
      sinon.assert.calledWith(entity.context_action, target, canvas.page);
    })

    it("dispatch rclick event to entity", function(){
      var cb = sinon.spy();
      entity.addEventListener('rclick', cb);
      canvas._rclicked_entity(entity);
      sinon.assert.called(cb);
    });
  });

  describe("#_hovered_over", function(){
    var entity, canvas;

    before(function(){
      entity = Omega.Gen.solar_system();
      canvas = new Omega.UI.Canvas();
    });

    it("invokes entity.on_hover callback", function(){
      sinon.stub(entity, 'on_hover');
      canvas._hovered_over(entity, 2);
      sinon.assert.calledWith(entity.on_hover, canvas, 2);
    });

    it("dispatches hover event to entity", function(){
      var cb = sinon.spy();
      sinon.stub(entity, 'on_hover'); /// stub out on_hover
      entity.addEventListener('hover', cb);
      canvas._hovered_over(entity, 2);
      sinon.assert.called(cb);
    });
  });

  describe("#_unhovered_over", function(){
    var entity, canvas;

    before(function(){
      entity = Omega.Gen.solar_system();
      canvas = new Omega.UI.Canvas();
    });

    it("invokes entity.on_unhover callback", function(){
      sinon.stub(entity, 'on_unhover');
      canvas._unhovered_over(entity);
      sinon.assert.calledWith(entity.on_unhover, canvas);
    });

    it("dispatches unhover event to entity", function(){
      var cb = sinon.spy();
      sinon.stub(entity, 'on_unhover'); /// stub out on_hover
      entity.addEventListener('unhover', cb);
      canvas._unhovered_over(entity);
      sinon.assert.called(cb);
    });
  });
});});
