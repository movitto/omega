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
      ship = new Omega.Ship({location : new Omega.Location()});
      container.show(ship);
    });

    it("unselects entity", function(){
      var unselected = sinon.spy(ship, 'unselected');
      container.hide();
      sinon.assert.calledWith(unselected, canvas.page);
    });

    it("clears local entity", function(){
      container.hide();
      assert(container.entity).isNull();
    });

    it("clears container contents", function(){
      $(container.contents_id).html('foobar');
      container.hide();
      assert($(container.contents_id).html()).equals('');
    });

    it("hides dom element", function(){
      $(container.div_id).show();
      assert($(container.div_id)).isVisible();
      container.hide();
      assert($(container.div_id)).isHidden();
    });
  });

  describe("#show", function(){
    var ship;

    before(function(){
      ship = new Omega.Ship({location : new Omega.Location()});
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

    it("retrieves entity details", function(){
      var retrieve_details = sinon.spy(ship, 'retrieve_details');
      container.show(ship);
      sinon.assert.calledWith(retrieve_details, canvas.page, sinon.match.func);
    });

    describe("entity_details callback", function(){
      it("appends details to entity container", function(){
        var retrieve_details = sinon.stub(ship, 'retrieve_details');
        container.show(ship);

        var append = sinon.spy(container, 'append');
        var details_cb = retrieve_details.getCall(0).args[1];
        details_cb('details');

        sinon.assert.calledWith(append, 'details');
        assert($(container.contents_id).html()).equals('details');
      });
    });

    it("invokes entity selected callback", function(){
      var selected = sinon.spy(ship, 'selected');
      container.show(ship);
      sinon.assert.calledWith(selected, canvas.page);
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

  describe("#refresh", function(){
    var entity;
    before(function(){
      entity = {id : 'e1'};
      canvas.page.entity(entity.id, entity);
    });

    after(function(){
      canvas.page.entity(entity.id, null);
    });

    it("refreshes entity from page", function(){
      container.show(entity);
      var entity2 = {}
      canvas.page.entity(entity.id, entity2);
      container.refresh();
      assert(container.entity).equals(entity2);
    });

    it("reshows scene with current entity", function(){
      container.show(entity);

      var show = sinon.spy(container, 'show');
      container.refresh();
      sinon.assert.calledWith(show, entity);
    });

    describe("local entity not set", function(){
      it("does nothing", function(){
        var show = sinon.spy(container, 'show');
        container.refresh();
        sinon.assert.notCalled(show);
      });
    });
  });
});});

