pavlov.specify("UIComponent", function(){
describe("UIComponent", function(){
  var c;
  before(function(){
    $('#qunit-fixture').
      append('<div id="component_id"></div><div id="close_control"></div><div id="toggle_control"></div>')
    c = new UIComponent();
    c.div_id = '#component_id'
    c.close_control_id = '#close_control'
    c.toggle_control_id = '#toggle_control'
  });

  describe("#on", function(){
    it("listens for event on page component", function(){
      var cc = c.component();
      var spy = sinon.spy(cc, 'live')
      c.on('click', function(){})
      sinon.assert.calledWith(spy, 'click')
      // TODO test other events
    })

    it("reraises page component event on self", function(){
      var cc = c.component();
      var spy = sinon.spy(c, 'raise_event')
      c.on('click', function(){})
      cc.trigger('click')
      sinon.assert.calledWith(spy, 'click')
    })
  })

  describe("#component", function(){
    it("returns handle to page component", function(){
      var cc = c.component();
      assert(cc.selector).equals('#component_id')
    })
  })

  describe("#append", function(){
    it("appends specified content to page component", function(){
      c.append("foobar")
      assert($('#component_id').html().slice(-6)).equals("foobar")
    })
  })

  describe("#close control", function(){
    it("returns handle to close-page-component control", function(){
      var cc = c.close_control()
      assert(cc.selector).equals("#close_control")
    })
  })

  describe("#toggle control", function(){
    it("returns handle to toggle-page-component control", function(){
      var tc = c.toggle_control()
      assert(tc.selector).equals("#toggle_control")
    })
  })

  describe("#show", function(){
    before(function(){
      c.subcomponents.push(new UIComponent());
    })

    it("sets toggle control", function(){
      var tc = c.toggle_control();
      var spy = sinon.spy(tc, 'attr')
      c.show();
      sinon.assert.calledWith(spy, 'checked', true)
    });

    it("shows page component", function(){
      var cc = c.component();
      var spy = sinon.spy(cc, 'show')
      c.show();
      sinon.assert.called(spy);
    });

    it("shows subcomponents", function(){
      var spy = sinon.spy(c.subcomponents[0], 'show');
      c.show();
      sinon.assert.called(spy)
    });

    it("raises show event", function(){
      var spy = sinon.spy(c, 'raise_event');
      c.show();
      sinon.assert.calledWith(spy, 'show')
    })
  })

  describe("#hide", function(){

    before(function(){
      c.subcomponents.push(new UIComponent());
    })

    it("sets toggle control", function(){
      var tc = c.toggle_control();
      var spy = sinon.spy(tc, 'attr')
      c.hide();
      sinon.assert.calledWith(spy, 'checked', false)
    });

    it("hides page component", function(){
      var cc = c.component();
      var spy = sinon.spy(cc, 'hide')
      c.hide();
      sinon.assert.called(spy);
    });

    it("hides subcomponents", function(){
      var spy = sinon.spy(c.subcomponents[0], 'hide');
      c.hide();
      sinon.assert.called(spy)
    });

    it("raises hides event", function(){
      var spy = sinon.spy(c, 'raise_event');
      c.hide();
      sinon.assert.calledWith(spy, 'hide')
    })
  })

  describe("#visible", function(){
    describe("component is visible", function(){
      it("returns false", function(){
        c.hide();
        assert(c.visible()).isFalse();
      });
    })

    describe("component is not visible", function(){
      it("returns true", function(){
        c.show();
        assert(c.visible()).isTrue();
      });
    })
  })

  describe("#toggle", function(){
    it("inverts toggled flag", function(){
      var o = c.toggled;
      c.toggled = false;
      c.toggle()
      assert(c.toggled).equals(true)
      c.toggle()
      assert(c.toggled).equals(false)
    })

    describe("toggled", function(){
      it("shows component", function(){
        var spy = sinon.spy(c, 'show')
        c.toggled = false;
        c.toggle();
        sinon.assert.called(spy);
      })
    });

    describe("not toggled", function(){
      it("hides component", function(){
        var spy = sinon.spy(c, 'hide')
        c.toggled = true;
        c.toggle();
        sinon.assert.called(spy);
      })
    });

    it("raises toggled event", function(){
      var spy = sinon.spy(c, 'raise_event')
      c.toggle();
      sinon.assert.calledWith(spy, 'toggle');
    })
  });

  describe("set size", function(){
    it("sets component height", function(){
      var spy = sinon.spy(c.component(), 'height')
      c.set_size(100, 200);
      sinon.assert.calledWith(spy, 200);
    })

    it("sets component width", function(){
      var spy = sinon.spy(c.component(), 'width')
      c.set_size(100, 200);
      sinon.assert.calledWith(spy, 100);
    })

    it("triggers component resize", function(){
      var spy = sinon.spy(c.component(), 'trigger')
      c.set_size(100, 200);
      sinon.assert.calledWith(spy, 'resize');
    })
  });

  describe("#click_coords", function(){
    it('returns component coordinates where page click occurred', function(){
      var ostub = sinon.stub(c.component(), 'offset').returns({left : 10, top : 20})
      c.set_size(100, 200);

      assert(c.click_coords(10,   20)[0]).close(   -1, 0.00001);
      assert(c.click_coords(10,   20)[1]).close(    1, 0.00001);
      assert(c.click_coords(11,   21)[0]).close(-0.98, 0.00001);
      assert(c.click_coords(11,   21)[1]).close( 0.99, 0.00001);
      assert(c.click_coords(20,   30)[0]).close( -0.8, 0.00001);
      assert(c.click_coords(20,   30)[1]).close(  0.9, 0.00001);
      assert(c.click_coords(110, 220)[0]).close(    1, 0.00001);
      assert(c.click_coords(110, 220)[1]).close(   -1, 0.00001);
    });
  })

  describe('#lock', function(){
    var spy;

    before(function(){
      spy = sinon.spy(c.component(), 'css');
    })

    it('sets component to use absolute positioning', function(){
      c.lock([]);
      sinon.assert.calledWith(spy, {position: 'absolute'})
    })

    it('locks components to the top side', function(){
      c.lock(['top']);
      sinon.assert.calledWith(spy, {top: c.component().position.top});
    })

    it('locks components to the left side', function(){
      c.lock(['left']);
      sinon.assert.calledWith(spy, {left: c.component().position.left});
    })

    it('locks components to the right side', function(){
      c.lock(['right']);
      sinon.assert.calledWith(spy, {right: sinon.match.number});
    })
  })

  describe("#wire_up", function(){
    it("removes close control live event handlers", function(){
      var spy = sinon.spy(c.close_control(), 'die')
      c.wire_up();
      sinon.assert.called(spy);
    })

    it("removes toggle control live event handlers", function(){
      var spy = sinon.spy(c.toggle_control(), 'die')
      c.wire_up();
      sinon.assert.called(spy);
    })

    it("adds close control click event handler", function(){
      var spy = sinon.spy(c.close_control(), 'live')
      c.wire_up();
      sinon.assert.calledWith(spy, 'click');
    })

    describe("close control clicked", function(){
      it("hides component", function(){
        var spy = sinon.spy(c.close_control(), 'live')
        c.wire_up();
        var cb = spy.getCall(0).args[1];
        var spy = sinon.spy(c, 'hide');
        cb.apply(null, []);
        sinon.assert.called(spy);
      })
    });

    it("adds toggled control click event handler", function(){
      var spy = sinon.spy(c.toggle_control(), 'live')
      c.wire_up();
      sinon.assert.calledWith(spy, 'click');
    })

    describe("toggle control clicked", function(){
      it("toggles component", function(){
        var spy = sinon.spy(c.toggle_control(), 'live')
        c.wire_up();
        var cb = spy.getCall(0).args[1];
        var spy = sinon.spy(c, 'toggle');
        cb.apply(null, []);
        sinon.assert.called(spy);
      })
    });

    it("sets toggled false", function(){
      c.wire_up();
      assert(c.toggled).isFalse();
    })

    it("toggles component", function(){
      var spy = sinon.spy(c, 'toggle');
      c.wire_up();
      sinon.assert.called(spy);
    })
  })

});}); // UIComponent

pavlov.specify("UIListComponent", function(){
describe("UIListComponent", function(){
  var lc;

  before(function(){
    $('#qunit-fixture').append('<div id="component_id"></div>')

    lc = new UIListComponent();
    lc.div_id = '#component_id';
  });

  describe("#clear", function(){
    it("clears item list", function(){
      lc.items.push("foobar")
      lc.clear();
      assert(lc.items).empty();
    });
  })

  describe("#add_item", function(){
    it("adds array of items to items list", function(){
      lc.add_item([{ id : 'a' }, { id : 'b'}])
      assert(lc.items).includes({ id : 'a' })
      assert(lc.items).includes({ id : 'b' })
    });

    it("adds item to items list", function(){
      lc.add_item({ id : 'a' })
      assert(lc.items).includes({ id : 'a' })
    });

    describe("existing item with same id", function(){
      it("overwrites old item", function(){
        lc.add_item({ id : 'a' })
        assert(lc.items[0]).isSameAs({ id : 'a' })
      });
    });
    
    //it("wires up item click handler")
    describe("item click", function(){
      it("raises click_item event on component", function(){
        var spy = sinon.spy(lc, 'raise_event')
        lc.add_item({ id : 'a' })
        $('#a').trigger('click');
        sinon.assert.calledWith(spy, 'click_item', { id : 'a' });
      })
    });

    it("refreshes the component", function(){
      var spy = sinon.spy(lc, 'refresh');
      lc.add_item({ id : 'a' })
      sinon.assert.called(spy);
    })
  })

  describe("#refresh", function(){
    it("invokes sort function to sort items", function(){
      var spy = sinon.spy();
      lc.sort = spy;
      lc.add_item({ id : 'a' })
      lc.add_item({ id : 'b' })
      lc.refresh();
      sinon.assert.called(spy);
    })

    it("renders item in component", function(){
      lc.add_item({ id : 'a', text : 'at' })
      lc.add_item({ id : 'b', text : 'bt' })
      lc.refresh();
      assert($(lc.div_id).html()).equals('<span id="a">at</span><span id="b">bt</span>')
    })

    //it("picks up alternative item wrapper")
  })

  describe("#add_text", function(){
    it("adds new item w/ specified text", function(){
      var spy = sinon.spy(lc, 'add_item');
      lc.add_text("fooz")
      sinon.assert.calledWith(spy, {id : 1, text : 'fooz', item : null})
    })

    it("adds items generated from an array of text", function(){
      var spy = sinon.spy(lc, 'add_item');
      lc.add_text(["foo", "bar"])
      sinon.assert.calledWith(spy, {id : 1, text : 'foo', item : null})
      sinon.assert.calledWith(spy, {id : 2, text : 'bar', item : null})
    })
  });

});}); // UIListComponent

pavlov.specify("CanvasComponent", function(){
describe("CanvasComponent", function(){
  var canvas; var cc;

  before(function(){
    $('#qunit-fixture').append('<div id="toggle_control"></div>')

    canvas = new Canvas();
    cc = new CanvasComponent({scene : canvas.scene});
    cc.toggle_canvas_id = '#toggle_control';
    cc.components.push({id : 'component1'});
  });

  describe("#toggle_canvas", function(){
    it("returns toggle-canvas-component page component", function(){
      assert(cc.toggle_canvas().selector).equals('#toggle_control');
    })
  });

  describe("#is_showing", function(){
    it("defaults to not showing", function(){
      assert(cc.is_showing()).isFalse()
    })

    it("returns is showing", function(){
      cc.sshow();
      assert(cc.is_showing()).isTrue()
    })
  });

  describe("#shide", function(){
    it("removes scene components from scene", function(){
      var spy = sinon.spy(canvas.scene, 'remove_component')
      cc.shide();
      sinon.assert.calledWith(spy, {id : 'component1'})
    });

    it("sets showing false", function(){
      cc.shide();
      assert(cc.is_showing()).isFalse()
    })

    it("unchecks toggle component", function(){
      var spy = sinon.spy(cc.toggle_canvas(), 'attr')
      cc.shide();
      sinon.assert.calledWith(spy, ':checked', false)
    })
  });

  describe("#sshow", function(){
    it("sets showing true", function(){
      cc.sshow();
      assert(cc.is_showing()).isTrue()
    });

    it("checks toggle component", function(){
      var spy = sinon.spy(cc.toggle_canvas(), 'attr')
      cc.sshow();
      sinon.assert.calledWith(spy, ':checked', true)
    });

    it("adds scene components to scene", function(){
      var spy = sinon.spy(canvas.scene, 'add_component')
      cc.sshow();
      sinon.assert.calledWith(spy, {id : 'component1'})
    });
  })

  describe("#stoggle", function(){
    describe("toggle component is checked", function(){
      it("shows component", function(){
        var stub = sinon.stub(cc.toggle_canvas(), 'is').withArgs(':checked').returns(true)
        var spy  = sinon.spy(cc, 'sshow');
        cc.stoggle();
        sinon.assert.called(spy);
      });
    });

    describe("toggle component is not checked", function(){
      it("hides component", function(){
        var stub = sinon.stub(cc.toggle_canvas(), 'is').withArgs(':checked').returns(false)
        var spy  = sinon.spy(cc, 'shide');
        cc.stoggle();
        sinon.assert.called(spy);
      });
    });

    it("animates scene", function(){
      var spy  = sinon.spy(canvas.scene, 'animate');
      cc.stoggle();
      sinon.assert.called(spy);
    });
  });

  describe("#cwire_up", function(){
    it("wires up toggle component click event", function(){
      var spy = sinon.spy(cc.toggle_canvas(), 'live')
      cc.cwire_up();
      sinon.assert.calledWith(spy, 'click');
    })

    it("unchecks toggle component", function(){
      cc.cwire_up();
      assert(cc.toggle_canvas().attr('checked')).isFalse();
    });

    describe("toggle component clicked", function(){
      it("toggles component in scene", function(){
        var spy = sinon.spy(cc.toggle_canvas(), 'live')
        cc.cwire_up();
        var cb = spy.getCall(0).args[1];
        var spy = sinon.spy(cc, 'stoggle');
        cb.apply(null, []);
        sinon.assert.called(spy);
      });
    });
  });

});}); // CanvasComponent

pavlov.specify("Canvas", function(){
describe("Canvas", function(){
  var canvas;

  before(function(){
    canvas = new Canvas();
    canvas.div_id = '#omega_canvas'
  });

  it("creates scene subcomponent", function(){
    assert(canvas.scene).isTypeOf(Scene);
  })

  it("creates selection box subcomponent", function(){
    assert(canvas.select_box).isTypeOf(SelectBox);
  })

  describe("#canvas_component", function(){
    it("returns canvas page component", function(){
      assert(canvas.canvas_component().selector).equals('#omega_canvas canvas')
    });
  });

  it("sets scene size to convas size", function(){
    var scene = new Scene({canvas : canvas});
    var spy = sinon.spy(scene, 'set_size');
    canvas = new Canvas({scene : scene});
    sinon.assert.called(spy);
    // TODO verify actual size
  })

  // TODO
  //describe("canvas shown", function(){
  //  it("shows 'Hide' on canvas toggle control")
  //});
  //describe("canvas hidden", function(){
  //  it("shows 'Show' on canvas toggle control")
  //});

  describe("canvas resized", function(){
    it("resizes scene", function(){
      var spy = sinon.spy(canvas.scene, 'set_size');
      canvas.raise_event('resize');
      sinon.assert.called(spy);
    })

    it("reanimates scene", function(){
      var spy = sinon.spy(canvas.scene, 'animate');
      canvas.raise_event('resize');
      sinon.assert.called(spy);
    })
  });
  describe("canvas clicked", function(){
    it("captures canvas click coordinates", function(){
      var spy = sinon.spy(canvas, 'click_coords');
      canvas.raise_event('click', { pageX : 10, pageY : 20 });
      sinon.assert.calledWith(spy, 10, 20)
    })

    it("passes click coordinates onto scene clicked handler", function(){
      var stub = sinon.stub(canvas, 'click_coords').returns([10, 20]);
      var spy  = sinon.spy(canvas.scene, 'clicked');
      canvas.raise_event('click', { pageX : 10, pageY : 20});
      sinon.assert.calledWith(spy, 10, 20);
    })
  });

  

  describe("mouse moved over canvas", function(){
    it("it delegates to select box", function(){
      var spy = sinon.spy(canvas.select_box.component(), 'trigger');
      var evnt = create_mouse_event('mousemove');
      canvas.raise_event('mousemove', evnt);
      sinon.assert.calledWith(spy, evnt);
    });
  });

  describe("mouse down over canvas", function(){
    it("it delegates to select box", function(){
      var spy = sinon.spy(canvas.select_box.component(), 'trigger');
      var evnt = create_mouse_event('mousedown');
      canvas.raise_event('mousedown', evnt);
      sinon.assert.calledWith(spy, evnt);
    });
  });
  describe("mouse up over canvas", function(){
    it("it delegates to select box", function(){
      var spy = sinon.spy(canvas.select_box.component(), 'trigger');
      var evnt = create_mouse_event('mouseup');
      canvas.raise_event('mouseup', evnt);
      sinon.assert.calledWith(spy, evnt);
    });
  });

});}); // Canvas

pavlov.specify("Scene", function(){
describe("Scene", function(){
  var canvas; var scene;

  before(function(){
    canvas = new Canvas();
    scene = canvas.scene;
  })

  it("creates camera subcomponent", function(){
    assert(scene.camera).isTypeOf(Camera);
  })

  it("creates skybox subcomponent", function(){
    assert(scene.skybox).isTypeOf(Skybox);
  })

  it("creates axis subcomponent", function(){
    assert(scene.axis).isTypeOf(Axis);
  })

  it("creates grid subcomponent", function(){
    assert(scene.grid).isTypeOf(Grid);
  })

  describe("#set_size", function(){
    it("it sets THREE renderer size", function(){
      var spy = sinon.spy(scene.renderer, 'setSize');
      scene.set_size(10, 30);
      sinon.assert.calledWith(spy, 10, 30);
    });

    it("sets camera size", function(){
      var spy = sinon.spy(scene.camera, 'set_size');
      scene.set_size(10, 30);
      sinon.assert.calledWith(spy, 10, 30);
    });

    it("resets camera", function(){
      var spy = sinon.spy(scene.camera, 'reset');
      scene.set_size(10, 30);
      sinon.assert.called(spy);
    });
  });

  describe("#add_entity", function(){
    var c;

    before(function(){
      c = new TestEntity({ id : 42});
      c.components.push(new THREE.Geometry())
    })

    it("adds entity to scene", function(){
      scene.add_entity(c);
      assert(scene.entities[42]).equals(c)
    });

    it("adds entity components to scene", function(){
      var spy = sinon.spy(scene, 'add_component');
      scene.add_entity(c);
      sinon.assert.calledWith(spy, c.components[0]);
    });

    it("invokes entity.added_to(scene)", function(){
      var spy = sinon.spy();
      c.added_to = spy;
      scene.add_entity(c);
      sinon.assert.calledWith(spy, scene);
    })
  });

  describe("#add_new_entity", function(){
    describe("entity in scene", function(){
      it("does not add entitiy to scene", function(){
        var c = new TestEntity({ id : 42});
        scene.add_entity(c);
        var spy = sinon.spy(scene, 'add_entity');
        scene.add_new_entity(c);
        sinon.assert.notCalled(spy);
      });
    });

    describe("entity not in scene", function(){
      it("invokes add_entity", function(){
        var spy = sinon.spy(scene, 'add_entity');
        var c = new TestEntity({ id : 42});
        scene.add_new_entity(c);
        sinon.assert.called(spy);
      })
    });
  });

  describe("#remove_entity", function(){
    describe("entity not in scene", function(){
      it("does not modify entities", function(){
        var c1 = new TestEntity({ id : 42});
        var c2 = new TestEntity({ id : 43});
        scene.add_entity(c1);
        scene.remove_entity(c2.id);
        assert(scene.entities[c1.id]).equals(c1);
      });
    });

    it("removes each entity component from scene", function(){
      var spy = sinon.spy(scene, 'remove_component');
      var c = new TestEntity({ id : 42});
      c.components.push(new THREE.Geometry())
      scene.add_entity(c);
      scene.remove_entity(c.id);
      sinon.assert.calledWith(spy, c.components[0]);
    });

    it("invokes entity.removed_from(scene)", function(){
      var spy = sinon.spy();
      var c = new TestEntity({ id : 42});
      c.removed_from = spy;

      scene.add_entity(c);
      scene.remove_entity(c.id);
      sinon.assert.calledWith(spy, scene);
    });
  });

  describe("#reload_entity", function(){
    var c;

    before(function(){
      c = new TestEntity({id : 42});
      scene.add_entity(c);
    })

    describe("entity not in scene", function(){
      it("does not modify entities", function(){
        var spy1 = sinon.spy(scene, 'remove_entity')
        var spy2 = sinon.spy(scene, 'add_entity')
        scene.reload_entity(new TestEntity({id : 43}))
        sinon.assert.notCalled(spy1)
        sinon.assert.notCalled(spy2)
      });
    });

    it("removes entity from scene", function(){
      var spy = sinon.spy(scene, 'remove_entity')
      scene.reload_entity(c);
      sinon.assert.calledWith(spy, c.id)
    })

    describe("callback specified", function(){
      it("invokes callback with scene & entity", function(){
        var spy = sinon.spy();
        scene.reload_entity(c, spy);
        sinon.assert.calledWith(spy, scene, c);
      });
    });

    it("adds entity to scene", function(){
      var spy = sinon.spy(scene, 'add_entity');
      scene.reload_entity(c);
      sinon.assert.calledWith(spy, c);
    });

    it("animates scene", function(){
      var spy = sinon.spy(scene, 'animate');
      scene.reload_entity(c);
      sinon.assert.called(spy);
    });
  });

  describe("#has", function(){
    describe("scene has entity", function(){
      it("returns true", function(){
        var c = new TestEntity({id : 42});
        scene.add_entity(c);
        assert(scene.has(c.id)).isTrue();
      });
    });

    describe("scene does not have entity", function(){
      it("returns false", function(){
        var c = new TestEntity({id : 42});
        assert(scene.has(c.id)).isFalse();
      });
    });
  });

  describe("#clear_entities", function(){
    var c1, c2;

    before(function(){
      c1 = new TestEntity({id : 42});
      c2 = new TestEntity({id : 43});
      scene.add_entity(c1);
      scene.add_entity(c2);
    })

    it("removes each entity", function(){
      var spy = sinon.spy(scene, 'remove_entity');
      scene.clear_entities();
      sinon.assert.calledWith(spy, c1.id.toString());
      sinon.assert.calledWith(spy, c2.id.toString());
    });

    it("clears entities array", function(){
      scene.clear_entities();
      assert(scene.entities).empty();
    })
  });

  describe("#add_component", function(){
    it("adds component to THREE scene", function(){
      var spy = sinon.spy(scene._scene, 'add');
      var c = new THREE.Geometry()
      scene.add_component(c);
      sinon.assert.calledWith(spy, c);
    });
  });

  describe("#remove_component", function(){
    it("removes component from THREE scene", function(){
      var spy = sinon.spy(scene._scene, 'remove');
      var c = new THREE.Geometry()
      scene.remove_component(c);
      sinon.assert.calledWith(spy, c);
    });
  });

  describe("#set", function(){
    it("sets root entity", function(){
      var r = new TestEntity()
      scene.set(r);
      assert(scene.root).equals(r);
    });

    it("adds each child entity", function(){
      var spy = sinon.spy(scene, 'add_entity');
      var r = new TestEntity({ id : 30 })
      var c = new TestEntity({ id : 50 })
      r._children.push(c)
      scene.set(r);
      sinon.assert.calledWith(spy, c);
    });

    it("raises set event", function(){
      var spy = sinon.spy(scene, 'raise_event');
      var r = new TestEntity()
      scene.set(r);
      sinon.assert.calledWith(spy, 'set');
    })

    it("animates the scene", function(){
      var spy = sinon.spy(scene, 'animate');
      var r = new TestEntity()
      scene.set(r);
      sinon.assert.called(spy);
    });
  });

  describe("#get", function(){
    it("returns root entity", function(){
      var r = new TestEntity()
      scene.set(r);
      assert(scene.get()).equals(r);
    })
  });

  describe("#refresh", function(){
    it("resets current root", function(){
      var r = new TestEntity()
      scene.set(r);

      var spy = sinon.spy(scene, 'set');
      scene.refresh();
      sinon.assert.calledWith(spy, r);
    });
  });

  describe("#clicked", function(){
    var c;

    before(function(){
      // TODO setup three scene to test other picking rays
      c = new TestEntity({id : 42})
      c.clickable_obj = new THREE.Mesh(new THREE.SphereGeometry(1000, 100, 100),
                                       new THREE.MeshBasicMaterial({color: 0xABABAB}));
      c.clickable_obj.position.x = 0;
      c.clickable_obj.position.y = 0;
      c.clickable_obj.position.z = -100;
      c.components.push(c.clickable_obj);

      var r = new TestEntity({id : 42})
      r._children.push(c);
      scene.set(r);
    });

    it("invokes entity.clicked_in(scene)", async(function(){
      on_animation(scene, function(){
        var spy = sinon.spy(c, 'clicked_in');
        scene.clicked(0, 0);
        sinon.assert.calledWith(spy, scene);
        resume();
      });
      scene.animate();
    }));

    it("raises click event on entity", async(function(){
      on_animation(scene, function(){
        var spy = sinon.spy(c, 'raise_event');
        scene.clicked(0, 0);
        sinon.assert.calledWith(spy, 'click', scene);
        resume();
      })
      scene.animate();
    }))
    //it("raises clicked space event");
  });

  //describe("#page_coordinate", function(){
  //  it("returns 2d coordinates of 3d coordinate in scene", function(){
  //  });
  //});

  describe("#unselect", function(){
    it("invokes entity.unselected_in(scene)", function(){
      var c = new TestEntity({ id : 42 })
      scene.add_entity(c);
      var spy = sinon.spy(c, 'unselected_in');
      scene.unselect(c.id);
      sinon.assert.calledWith(spy, scene);
    });

    it("raises unselected event on entity", function(){
      var c = new TestEntity({ id : 42 })
      scene.add_entity(c);
      var spy = sinon.spy(c, 'raise_event');
      scene.unselect(c.id);
      sinon.assert.calledWith(spy, 'unselected', scene);
    });
  });

  //describe("#animate", function(){
  //  it("requests animation frame");
  //});
  //describe("#render", function(){
  //  it("renders scene with THREE renderer");
  //});

  describe("#position", function(){
    it("returns THREE scene position", function(){
      assert(scene.position()).equals(scene._scene.position);
    });
  });
});}); // Scene

pavlov.specify("Camera", function(){
describe("Camera", function(){
  describe("#new_cam", function(){
    it("creates new THREE perspective camera");
  });
  describe("#set_size", function(){
    it("sets width/height");
    it("creates new camera");
  });
  describe("#reset", function(){
    it("sets camera position");
    it("focuses camera on scene");
    it("animates scene");
  });
  describe("#focus", function(){
    describe("new focus point specified", function(){
      it("points THREE camera at focus point");
    });
    it("returns camera focus point");
  });
  describe("#position", function(){
    describe("new camera position specified", function(){
      it("sets THREE camera position");
    });
    it("returns camera position")
  });
  describe("#zoom", function(){
    it("moves camera along its focus axis");
  });
  describe("#rotate", function(){
    it("rotates camera by specified spherical coordinates");
  });
  describe("#pan", function(){
    it("pans camera along its x,y axis");
  });
  describe("#wire_up", function(){
    it("wires up page camera controls");
  });
});}); // Camera

pavlov.specify("Skybox", function(){
describe("Skybox", function(){
  describe("#background", function(){
    describe("new background specified", function(){
      it("sets skybox background")
    });
    it("returns skybox background")
  });
});}); // Skybox

pavlov.specify("SelectBox", function(){
describe("SelectBox", function(){

  describe("#start_showing", function(){
    it("sets down page position")
    it("shows component")
  });
  describe("#stop_showing", function(){
    it("hides component");
  });
  describe("#update_area", function(){
    it("computes widith/height from down/current mouse positions");
    it("adjust component size")
  });

  it("handles mousemove event")
  describe("mouse move event", function(){
    it("updates area")
  });

  it("handles mousedown event")
  describe("mouse down event", function(){
    it("starts showing");
  });

  it("handles mouseup event")
  describe("mouse up event", function(){
    it("stops showing")
  });

});}); // SelectBox

pavlov.specify("Dialog", function(){
describe("Dialog", function(){
  describe("#subdiv", function(){
    it("returns subdiv page component");
  });
  it("sets title");
  it("sets selector");
  it("sets text");
  describe("show", function(){
    it("loads content from selector");
    it("appends text")
    it("sets dialog title");
    it("opens dialog");
  });
  describe("hide", function(){
    it("closes dialog");
  });
});}); // Dialog

pavlov.specify("EntitiesContainer", function(){
describe("EntitiesContainer", function(){
  it("wraps items list in a ul");
  it("handles mouseenter event");
  describe("mouse enter event", function(){
    it("shows ul")
  });
  it("handles mouseleave event");
  describe("mouse leave event", function(){
    it("hides ul")
  });
  describe("#hide_all", function(){
    it("hides all entities containers")
    it("hides missions button")
  });
});}); // EntitiesContainer

pavlov.specify("StatusIndicator", function(){
describe("StatusIndicator", function(){
  describe("#set_bg", function(){
    it("sets component background");
    describe("specified background is null", function(){
      it("clears component background");
    });
  });
  describe("#has_state", function(){
    describe("state is on state stack", function(){
      it("returns true");
    });
    describe("state is not on state stack", function(){
      it("returns false");
    });
  });
  describe("#is_state", function(){
    describe("state is last state stack", function(){
      it("returns true");
    });
    describe("state is not last state on stack", function(){
      it("returns false");
    });
  });
  describe("push_state", function(){
    it("pushes new state onto stack");
    it("sets background");
  });
  describe("pop_state", function(){
    it("pops a state off stack");
    it("sets background");
  });
});}); // StatusIndicator

pavlov.specify("NavContainer", function(){
describe("NavContainer", function(){
  describe("#show_login_controls", function(){
    it("shows register link");
    it("shows login link");
    it("hides account link");
    it("hides logout link");
  });
  describe("#show_logout_controls", function(){
    it("hides register link");
    it("hides login link");
    it("shows account link");
    it("shows logout link");
  });
});}); // NavContainer

pavlov.specify("AccountInfoContainer", function(){
describe("AccountInfoContainer", function(){
  describe("#username", function(){
    it("gets username input value")
    it("sets username input value")
  });
  describe("#password", function(){
    it("gets password input value")
    it("sets password input value")
  });
  describe("#email", function(){
    it("gets email input value")
    it("sets email input value")
  });
  describe("#gravatar", function(){
    it("gets gravatar page component value")
    it("sets gravatar page component value")
  });
  describe("#entities", function(){
    it("sets entities list")
  });
  describe("#passwords_match", function(){
    describe("passwords match", function(){
      it("returns true")
    });
    describe("passwords don't match", function(){
      it("returns false")
    });
  });
  describe("#user", function(){
    it("returns new user created from inputs")
  });
  describe("#add_badge", function(){
    it("it adds badge to ui");
  });
});}); // AccountInfoContainer
