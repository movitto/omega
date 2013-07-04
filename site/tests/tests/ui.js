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
  before(function(){
  });

  it("defaults to not showing")

  it("tracks scene components")

  describe("#toggle_canvas", function(){
    it("returns toggle-canvas-component page component")
  });

  describe("#is_showing", function(){
    it("returns is showing")
  });

  describe("#shide", function(){
    it("removes scene components from scene");
    it("sets showing false")
    it("unchecks toggle component")
  });

  describe("#sshow", function(){
    it("sets showing true");
    it("checks toggle component");
    it("adds scene components to scene");
  })

  describe("#stoggle", function(){
    describe("toggle component is checked", function(){
      it("shows component");
    });
    describe("toggle component is not checked", function(){
      it("hides component");
    });
    it("animates scene");
  });

  describe("#cwire_up", function(){
    it("wires up toggle component click event");
    it("unchecks toggle component");
    describe("toggle component clicked", function(){
      it("toggles component in scene");
    });
  });

});}); // CanvasComponent

pavlov.specify("Canvas", function(){
describe("Canvas", function(){
  before(function(){
  });

  it("creates scene subcomponent")
  it("creates selection box subcomponent")

  describe("#canvas_component", function(){
    it("returns canvas page component");
  });

  it("sets scene size to convas size")

  describe("canvas shown", function(){
    it("shows 'Hide' on canvas toggle control")
  });
  describe("canvas hidden", function(){
    it("shows 'Show' on canvas toggle control")
  });
  describe("canvas resized", function(){
    it("resizes scene")
    it("reanimates scene")
  });
  describe("canvas clickd", function(){
    it("captures canvas click coordinates")
    it("passes click coordinates onto scene clicked handler")
  });
  describe("mouse moved over canvas", function(){
    it("it delegates to select box");
  });
  describe("mouse down over canvas", function(){
    it("it delegates to select box");
  });
  describe("mouse up over canvas", function(){
    it("it delegates to select box");
  });

});}); // Canvas

pavlov.specify("Scene", function(){
describe("Scene", function(){
  it("creates camera subcomponent")
  it("creates skybox subcomponent")
  it("creates axis subcomponent")
  it("creates grid subcomponent")
  describe("#set_size", function(){
    it("it sets THREE renderer size");
    it("sets camera size");
    it("resets camera");
  });
  describe("#add_entity", function(){
    it("adds entity components to scene");
    it("invokes entity.add_to(scene)")
  });
  describe("#add_new_entity", function(){
    describe("entity in scene", function(){
      it("does not add entitiy to scene");
    });
    describe("entity not in scene", function(){
      it("invokes add_entity")
    });
  });
  describe("#remove_entity", function(){
    describe("entity not in scene", function(){
      it("just returns");
    });
    it("removes each entity component from scene");
    it("invokes entity.removed_from(scene)");
  });
  describe("#reload_entity", function(){
    describe("entity not in scene", function(){
      it("just returns");
    });
    it("removes entity from scene")
    describe("callback specified", function(){
      it("invokes callback with scene, entity");
    });
    it("adds entity to scene");
    it("animates scene");
  });
  describe("#has", function(){
    describe("scene has entity", function(){
      it("returns true");
    });
    describe("scene does not have entity", function(){
      it("returns false");
    });
  });
  describe("#clear_entities", function(){
    it("removes each entity")
    it("clears entities array")
  });
  describe("#add_component", function(){
    it("adds component to THREE scene");
  });
  describe("#remove_component", function(){
    it("removes component from THREE scene");
  });
  describe("#set", function(){
    it("sets root entity");
    it("adds each child entity");
    it("raises set event")
  });
  describe("#get", function(){
    it("returns root entity")
  });
  describe("#refresh", function(){
    it("resets current root");
  });
  describe("#clicked", function(){
    it("retrieves scene entity clicked");
    it("invokes entity.clicked_in(scene)");
    it("raises click event on entity")
    //it("raises clicked space event");
  });
  describe("#page_coordinate", function(){
    it("returns 2d coordinates of 3d coordinate in scene");
  });
  describe("#unselect", function(){
    describe("entity id is invalid", function(){
      it("just returns");
    });
    it("invokes entity.unselected_in(scene)");
    it("raises unselected event on entity");
  });
  describe("#animate", function(){
    it("requests animation frame");
  });
  describe("#render", function(){
    it("renders scene with THREE renderer");
  });
  describe("#position", function(){
    it("returns THREE scene position");
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
