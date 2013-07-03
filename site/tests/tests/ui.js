pavlov.specify("UIComponent", function(){
describe("UIComponent", function(){
  before(function(){
  });

  it("tracks subcomponents")

  describe("#on", function(){
    it("listens for event on page componet")
    it("reraises page component event on self")
  })

  describe("#component", function(){
    it("returns handle to page component")
  })

  describe("#append", function(){
    it("appends specified content to page component")
  })

  describe("#close control", function(){
    it("returns handle to close-page-component control")
  })

  describe("#toggle control", function(){
    it("returns handle to toggle-page-component control")
  })

  describe("#show", function(){
    it("checks toggle control");
    it("shows page component");
    it("shows subcomponents");
    it("raises show event")
  })

  describe("#hide", function(){
    it("unchecks toggle control");
    it("hides page component");
    it("hides subcomponents");
    it("raises hides event")
  })

  describe("#visible", function(){
    describe("component is visible", function(){
      it("returns false");
    })

    describe("component is not visible", function(){
      it("returns true");
    })
  })

  describe("#toggle", function(){
    it("inverts toggled flag")

    describe("toggled", function(){
      it("shows component")
    });

    describe("not toggled", function(){
      it("hides component")
    });

    it("raises toggled event")
  });

  describe("set size", function(){
    it("sets component height")
    it("sets component width")
    it("triggers component resize")
  });

  describe("#click_coords", function(){
    it('returns page coordinates which click occurred');
  })

  describe('#lock', function(){
    it('locks components to the top side')
    it('locks components to the left side')
    it('locks components to the right side')
  })

  describe("#wire_up", function(){
    it("removes close control live event handlers")
    it("removes toggle control live event handlers")

    it("adds close control click event handler")
    describe("close control clicked", function(){
      it("hides component")
    });

    it("adds toggled control click event handler")
    describe("toggle control clicked", function(){
      it("toggles component")
    });

    it("sets toggled true")
    it("toggles component")
  })

});}); // UIComponent

pavlov.specify("UIListComponent", function(){
describe("UIListComponent", function(){
  before(function(){
  });

  it("track list of items")

  describe("#clear", function(){
    it("clears item list");
  })

  describe("#add_item", function(){
    it("adds array of items to items list");
    it("adds item to items list");

    describe("existing item with same id", function(){
      it("overwrites old item");
    });
    
    it("wires up item click handler")
    describe("item click", function(){
      it("raises click_item event on component")
    });

    it("refreshes the component")
  })

  describe("#refresh", function(){
    describe("page component doesn't exist", function(){
      it("just returns")
    });

    it("invokes sort function to sort items")

    it("sets component html to rendered item list")
  })

  describe("#add_text", function(){
    it("adds new item w/ specified text")
    it("adds items generated from an array of text")
    it("auto increments item ids")
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
