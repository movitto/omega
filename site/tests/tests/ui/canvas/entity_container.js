pavlov.specify("Omega.UI.CanvasEntityContainer", function(){
describe("Omega.UI.CanvasEntityContainer", function(){
  var canvas, container;

  before(function(){
    canvas = Omega.Test.Canvas();
    container = new Omega.UI.CanvasEntityContainer({canvas: canvas});
  });

  after(function(){
    Omega.Test.clear_events();
  });

  it('has a reference to canvas the container is for', function(){
    assert(container.canvas).equals(canvas);
  });

  describe("#wire_up", function(){
    it("registers entity container close click event handler", function(){
      assert($(container.close_id)).doesNotHandle('click');
      container.wire_up();
      assert($(container.close_id)).handles('click');
    });

    it("hides entity container", function(){
      var hide = sinon.spy(container, 'hide');
      $(container.div_id).show();
      assert($(container.div_id)).isVisible();
      container.wire_up();
      assert($(container.div_id)).isHidden();
      sinon.assert.called(hide);
    });

    it("registers entity container keydown event handler", function(){
      assert($(container.div_id)).doesNotHandle('keydown');
      container.wire_up();
      assert($(container.div_id)).handles('keydown');
    });

    describe("on entity container enter key", function(){
      it("hides entity container", function(){
        var hide = sinon.spy(container, 'hide');
        container.wire_up();
        $(container.div_id).trigger(jQuery.Event('keydown', {keyCode: 27}));
        sinon.assert.called(hide);
      });
    })
  });

  describe("#close button clicked", function(){
    it("it hides entity container", function(){
      var hide = sinon.spy(container, 'hide');
      container.wire_up();
      $(container.close_id).click();
      sinon.assert.calledWith(hide);
    });
  });

  describe("#hide", function(){
    var ship;
    before(function(){
      ship = Omega.Gen.ship();
      ship.init_gfx();
      container.show(ship);
    });

    it("unselects entity", function(){
      var unselected = sinon.spy(ship, 'unselected');
      container.hide();
      sinon.assert.calledWith(unselected, canvas.page);
    });

    it("removes entity container callbacks", function(){
      sinon.stub(container, '_remove_entity_callbacks');
      container.hide();
      sinon.assert.called(container._remove_entity_callbacks);
    });

    it("clears local entity", function(){
      container.hide();
      assert(container.entity).isNull();
    });

    it("clears dom", function(){
      sinon.spy(container, '_clear_dom');
      container.hide();
      sinon.assert.called(container._clear_dom);
    });

    it("hides dom element", function(){
      $(container.div_id).show();
      assert($(container.div_id)).isVisible();
      container.hide();
      assert($(container.div_id)).isHidden();
    });
  });

  describe("#_clear_dom", function(){
    it("clears container contents", function(){
      $(container.contents_id).html('foobar');
      container._clear_dom();
      assert($(container.contents_id).html()).equals('');
    });
  });

  describe("#show", function(){
    var ship;

    before(function(){
      ship = Omega.Gen.ship();
      ship.init_gfx();
    });

    it("hides entity container", function(){
      var hide = sinon.spy(container, 'hide');
      container.show({});
      sinon.assert.called(hide);
    })

    it("sets local entity", function(){
      container.show(ship);
      assert(container.entity).equals(ship);
    });

    it("sets entity details", function(){
      sinon.spy(container, '_set_entity_details');
      container.show(ship);
      sinon.assert.called(container._set_entity_details);
    })

    it("invokes entity selected callback", function(){
      var selected = sinon.spy(ship, 'selected');
      container.show(ship);
      sinon.assert.calledWith(selected, canvas.page);
    });

    it("adds entity container callbacks", function(){
      sinon.spy(container, '_add_entity_callbacks');
      container.show(ship);
      sinon.assert.called(container._add_entity_callbacks);
    });

    it("shows entity container", function(){
      assert($(container.div_id)).isHidden();
      container.show(ship);
      assert($(container.div_id)).isVisible();
    });

    it("sets focus on entity container", function(){
      container.show(ship);
      assert($(container.div_id).is(':focus')).isTrue();
    });
  });

  describe("#append", function(){
    it("appends text to entity container contents", function(){
      assert($(container.contents_id).html()).equals('');
      container.append('details');
      assert($(container.contents_id).html()).equals('details');
    });
  });

  describe("#_set_entity_details", function(){
    var ship;

    before(function(){
      ship = Omega.Gen.ship();
      ship.init_gfx();
    });

    it("retrieves entity details", function(){
      sinon.spy(ship, 'retrieve_details');
      container.show(ship);
      sinon.assert.calledWith(ship.retrieve_details,
                              canvas.page, sinon.match.func);
    });

    describe("entity_details callback", function(){
      it("appends details to entity container", function(){
        sinon.stub(ship, 'retrieve_details');
        container.show(ship);

        sinon.spy(container, 'append');
        var details_cb = ship.retrieve_details.omega_callback();
        details_cb('details');

        sinon.assert.calledWith(container.append, 'details');
        assert($(container.contents_id).html()).equals('details');
      });
    });
  });

  describe("#_init_entity_callbacks", function(){
    var ship;

    before(function(){
      ship = Omega.Gen.ship();
    });

    it("defines refresh entity container handler for entity", function(){
      container.entity = ship;
      container._init_entity_callbacks();
      assert(ship._refresh_entity_container).isNotNull();
    });

    it("defines refresh entity container details handler for entity", function(){
      container.entity = ship;
      container._init_entity_callbacks();
      assert(ship._refresh_entity_container_details).isNotNull();
    });
  });

  describe("#_remove_entity_callbacks", function(){
    var ship;

    before(function(){
      ship = Omega.Gen.ship();
    });

    it("removes refresh container handler for entity 'refresh_details_on' events", function(){
      container.entity = ship;
      container._add_entity_callbacks();
      sinon.stub(ship, 'removeEventListener');
      container._remove_entity_callbacks();
      for(var cb = 0; cb < ship.refresh_details_on.length; cb++)
        sinon.assert.called(ship.removeEventListener,
                            ship.refresh_details_on[cb]);
    });
  });

  describe("#_add_entity_callbacks", function(){
    var ship;

    before(function(){
      ship = Omega.Gen.ship();
    });

    it("adds refresh container callback to entity 'refresh_details_on' events handler", function(){
      container.entity = ship;
      container._add_entity_callbacks();
      for(var cb = 0; cb < ship.refresh_details_on.length; cb++)
        assert(ship).handlesEvent(ship.refresh_details_on[cb]);
    });
  });

  describe("#refresh_details", function(){
    before(function(){
      container.entity = {refresh_details : sinon.spy()};
    });

    it("refreshes entity details", function(){
      container.refresh_details();
      sinon.assert.called(container.entity.refresh_details);
    });

    describe("local entity not set", function(){
      it("does nothing", function(){
        var entity = container.entity;
        container.entity = null;
        container.refresh_details();
        sinon.assert.notCalled(entity.refresh_details);
      });
    });
  });

  describe("#refresh_cmds", function(){
    it("refreshes entity commands", function(){
      container.entity = Omega.Gen.ship();
      sinon.spy(container.entity, 'refresh_cmds');
      container.refresh_cmds();
      sinon.assert.calledWith(container.entity.refresh_cmds, canvas.page);
    });
  });

  describe("#refresh", function(){
    it("refreshes details", function(){
      sinon.spy(container, 'refresh_details');
      container.refresh();
      sinon.assert.called(container.refresh_details);
    });

    it("refreshes commands", function(){
      sinon.spy(container, 'refresh_cmds');
      container.refresh();
      sinon.assert.called(container.refresh_cmds);
    });
  });
});});

