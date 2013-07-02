pavlov.specify("omega.js", function(){
  describe("restore_session", function(){
    it("restores session from cookie");
    describe("session is null", function(){
      it("logs in as anon");
    });
    describe("session is not null", function(){
      it("sets headers on node");
      it("validates session");
      describe("error on session validation", function(){
        it("logs in as anon");
      });
      describe("session validated successfully", function(){
        it("establishes session");
      });
    });
  }); // restore_session
  describe("login_anon", function(){
    it("logs in anon user using session");
  });
  describe("#session_established", function(){
    it("sets global node");
    it("shows logout controls");
    it("subscribes to chat messages");
    describe("on chat message", function(){
      it("adds message to chat container");
    });
    it("shows chat container");
    it("shows missions button");
    it("retrieves and processes ships owned by user")
    it("retrieves and processes stations owned by user")
    it("populates account information")
    it("retrieves stats");
  });
  describe("#process_entities", function(){
    it("adds user entities to account info");
    it("processes each entity");
  });
  describe("#process_entity", function(){
    describe("entity in registry", function(){
      it("updates entity");
    });
    describe("entity not in registry", function(){
      it("adds entity to registry");
    });
    it("stores location in registry")
    it("adds entity to entities container")
    it("shows entities container")
    it("handles entity page events")

    describe("entity jumped", function(){
      it("removes entity from scene");
    });

    it("track entity movement/rotation/stops");
    describe("entity movement/rotation/stop", function(){
      it("invokes a motel_event");
    });

    it("tracks manu events");
    describe("manu event occurred", function(){
      it("invokes a manufactured event");
    });

    it("loads system entity is in");
    describe("system loaded", function(){
      it("sets entity solar system");
    });
  });
  describe("#refresh_entity_container", function(){
    it("clears entity container contents");
    it("adds entity details to entity container");
    it("shows entity container");
  });
  describe("#motel_event", function(){
    it("updates entity ownining location");
    describe("scene has entity", function(){
      it("updates entity in scene");
    });
    describe("entity selected", function(){
      it("refreshes entity container");
    });
  });
  describe("#manufactured_event", function(){
    describe("resource_collected", function(){
      it("updates ship");
      describe("scene has ship", function(){
        it("animates scene");
      });
    });
    describe("mining_stopped", function(){
      it("updates ship");
      describe("scene has ship", function(){
        it("animates scene");
      });
    });
    describe("attacked", function(){
      it("updates attacker");
      it("updates defender");
      it("sets attacker.attacker = defender");
      describe("scene has attacker or defender", function(){
        it("animates scene");
      });
    });
    describe("attacked_stop", function(){
      it("updates attacker");
      it("updates defender");
      it("sets attacker.attacker = null");
      describe("scene has attacker or defender", function(){
        it("animates scene");
      });
    });
    describe("defended", function(){
      it("updates attacker");
      it("updates defender");
      it("sets attacker.attacker = defender");
      describe("scene has attacker or defender", function(){
        it("animates scene");
      });
    });
    describe("defended_stop", function(){
      it("updates attacker");
      it("updates defender");
      it("sets attacker.attacker = null");
      describe("scene has attacker or defender", function(){
        it("animates scene");
      });
    });
    describe("destroyed", function(){
      it("updates attacker");
      it("updates defender");
      it("sets attacker.attacker = null");
      describe("scene has attacker or defender", function(){
        it("animates scene");
      });
    });
    describe("construction_complete", function(){
      it("retrieves ship with id");
      it("adds ship to registry")
      it("processes entity")
    });
  });
  describe("#process_stats", function(){
    it("adds badges to account info");
  });
  describe("#handle_events", function(){
    it("handles click event");
    describe("entity clicked", function(){
      it("invokes clicked entity callback");
    });
  });
  describe("#clicked_entity", function(){
    describe("clicked solar system", function(){
      it("dispatches to clicked system");
    });
    describe("clicked asteroid", function(){
      it("dispatches to clicked asteroid");
    });
    describe("clicked ship", function(){
      it("dispatches to clicked ship");
    });
    describe("clicked station", function(){
      it("dispatches to clicked station");
    });
  });
  describe("#popup_entity_container", function(){
    it("clears entity container callbacks");
    it("handles hide event");
    describe("container hidden", function(){
      it("unselects selected entity");
      it("hides dialog");
    });
    it("handles entity unselected event");
    it("entity unselected");
    describe("entity container visible", function(){
      it("hides entity container");
    });
    it("clears entity container contents");
    it("adds entity details to entity container");
    it("shows entity container");
  });
  describe("#clicked_system", function(){
    it("sets scene");
  });
  describe("#clicked_asteroid", function(){
    it("invokes cosmos::get_resources");
    describe("on resource retrieval", function(){
      it("appends resource information to entity container");
    });
  });
  describe("#clicked_ship", function(){
    describe("ship does not belong to current user", function(){
      it("just returns");
    });

    it("clears ship callbacks for all commmands");
    it("handles all ship commands");
    describe("on ship 'selection' commands", function(){
      it("it pops up dialog to make selection");
    });
    describe("on ship 'finish selection' commands", function(){
      it("closes dialog");
      it("animates scene");
    });
    describe("on ship 'reload' commands", function(){
      it("reloads entity in scene");
    });
    describe("on ship mining selection command", function(){
      it("retrieves asteroids in the vicinity");
      it("invokes cosmos::get_resources for each asteroid");
      describe("on resources retreived", function(){
        it("adds resource info to dialog");
      });
    });
  });
  describe("#clicked_station", function(){
    describe("station does not belong to current user", function(){
      it("just returns");
    });
  });
  describe("#load_system", function(){
    it("TODO")
  });
  describe("#load_galaxy", function(){
    it("TODO")
  });
  describe("#wire_up_ui", function(){
    it("wires up nav container");
    it("wires up status indicator");
    it("wires up jplayer");
    it("wires up entities lists");
    it("wires up canvas");
    it("wires up chat container");
    it("wires up account info container");
  });
  describe("#wire_up_nav", function(){
    it("handles login link click event");
    describe("on login link click", function(){
      it("pops up login dialog");
    });

    it("handles login button click event");
    describe("on login button click", function(){
      it("hides login dialog");
      it("reads username / password inputs");
      it("creates new user");
      it("logs user in");
      describe("on successful user login", function(){
        it("establishes session");
      });
    });

    it("handles register link click event");
    describe("on register link click", function(){
      it("pops up register dialog");
      it("generates recpatcha");
    });

    it("handles register button click event");
    describe("on register button click", function(){
      it("hides register dialog");
      it("reads username / password / email / recaptcha inputs");
      it("creates new user");
      it("invokes register user web request");
      describe("on failed user registration", function(){
        it("shows failed registration dialog with reason");
      });
      describe("on successful user registration", function(){
        it("shows successful registration dialog");
      });
    });

    it("handles logout link click event");
    describe("on logout link click", function(){
      it("logs the session out");
      it("hides missions button");
      it("hides entities container");
      it("hides locations container");
      it("hides entity container");
      it("hides dialog");
      it("hides chat container");
      it("hides chat container toggle");
      it("clears canvas scene");
      it("hides canvas skybox/axis/grid");
      it("resets canvas camera");
      it("shows login controls");
    });
  });

  describe("#wire_up_status", function(){
    it("handles all node requests");
    describe("on node request", function(){
      it("pushes 'loading' status onto indicator");
    });

    it("handles all node messages received");
    describe("on node msg received", function(){
      it("pops top status off indicator stack");
    });
  });

  describe("#wire_up_jplayer", function(){
    it("TODO");
  });

  describe("#wire_up_entities_lists", function(){
    it("handles locations container click_item events");
    describe("on locations container click_item", function(){
      it("sets scene to clicked item");
    });
    it("handles entities container click_item events");
    describe("on entities container click_item", function(){
      it("sets scene to clicked item's solar system");
    });
    it("handles missions button click events");
    describe("on mission button click", function(){
      it("retrieves all missions");
      it("shows missions");
    });
    it("handles assign mission click event");
    describe("on assign mission click", function(){
      describe("error during mission assignment", function(){
        it("shows error in dialog");
      });
      describe("successful mission assignment", function(){
        it("updates registry entity")
        it("hides dialog");
      });
    });
  });

  describe("#set_scene", function(){
    it("hides dialog");
    it("unselects selected entity");
    it("removes old skybox");
    it("clears scene entities");
    it("sets scene root entity");
    describe("camera focus specified", function(){
      it("focuses camera on specified location");
    });
    it("sets skybox background");
    it("adds skybox to scene");
    describe("root entity is a solar system", function(){
      it("clears child planet callbacks");
      it("tracks child planet movement");
      describe("on planet movement event", function(){
        it("raises motel event");
      });
    });
  });
  describe("#show_missions", function(){
    it("retrieves unassigned/assigned/victorious/failed/current missions");
    describe("mission currently in process", function(){
      it("shows mission details in dialog");
    });
    describe("mission not currently in process", function(){
      it("shows unassigned mission information in dialog");
      it("shows victorious/fails mission stats in dialog");
    });
    it("shows dialog");
  });
  describe("#wire_up_canvas", function(){
    it("dispatches to canvas.wire_up");
    it("dispatches to canvas.scene.camera.wire_up");
    it("dispatches to canvas.scene.axis.wire_up");
    it("dispatches to canvas.scene.grid.wire_up");
    it("dispatches to entity container.wire_up");
    it("handles window resize events");
    describe("on window resize", function(){
      it("only responds to root windows resize events");
      it("sets canvas size");
    });
    it("it listens for all texture loading events");
    describe("on texture loading", function(){
      it("reanimates scene");
    });
    it("it listens for scene set event");
    describe("on scene set", function(){
      it("removes movement/manu event tracking from all entities not in current system");
      it("refreshes entities under current system");
      it("resets the camera");
    });
  });
  describe("#wire_up_chat", function(){
    it("dispatches to chat_container.wire_up");
    it("handles chat button click event");
    describe("on chat button click", function(){
      it("retrieves chat input");
      it("sends new chat message to server");
      it("adds message to output");
      it("clears chat input");
    });
  });
  describe("#wire_up_account_info", function(){
    it("handles account info update button click event");
    describe("passwords do no match", function(){
      it("pops up an alert / does not continue");
    });
    it("invokes update_user request");
    describe("successful user update", function(){
      it("pops up an alert w/ confirmation");
    });
  });

}); // omega.js
