pavlov.specify("ServerEvents", function(){
describe("ServerEvents", function(){
  before(function(){
  });

  describe("#handle", function(){
    it("creates callback for the server event");
    it("clears handlers on node for the server event")
    it("adds handler to node for the server event")
    it("adds handlers for multiple server events")

    describe("#on server event", function(){
      it("raises the server event on self")
      it("retreives entity to raise event on from Entities")
      it("raises server event on entity")
    });
  });

  describe("#clear", function(){
    it("clears handler on node for the server event")
    it("removes callback for server event")
  });

});}); // ServerEvents

pavlov.specify("Events", function(){
describe("Events", function(){
  describe("#track_movement", function(){
    it("handles motel::location_stopped server event")
    it("handles motel::on_movement server event")
    it("handles motel::on_rotation server event")
    it("invokes motel::track_stops")
    it("invokes motel::track_movement")
    describe("rotation distance is set", function(){
      it("invokes motel::track_rotation")
    });
  });

  describe("#stop_track_movement", function(){
    it("invokes motel::remove_callbacks")
  })

  describe("#track_mining", function(){
    it("handles manufactured::event_occurred server event")
    it("invokes manfufactured::subscribe_to resource_collected")
    it("invokes manfufactured::subscribe_to resource_collected")
    it("invokes manfufactured::subscribe_to mining_stopped")
  })

  describe("#track_offense", function(){
    it("handles manufactured::event_occurred server event")
    it("invokes manufactured::subscribe_to attacked")
    it("invokes manufactured::subscribe_to attacked_stop")
  })

  describe("#track_defense", function(){
    it("handles manufactured::event_occurred server event")
    it("invokes manufactured::subscribe_to defended")
    it("invokes manufactured::subscribe_to defended_stop")
    it("invokes manufactured::subscribe_to destroyed")
  })

  describe("#track_construction", function(){
    it("handles manufactured::event_occurred server event")
    it("invokes manufactured::subscribe_to construction_complete")
    it("invokes manufactured::subscribe_to partial_construction")
  })

  describe("#stop_track_manufactured", function(){
    it("invokes manufactured::remove_callbacks");
  })

});}); // Events

pavlov.specify("Commands", function(){
describe("Commands", function(){
  describe("#trigger_jump_gate", function(){
    it("retrieves registry ships owned by user within trigger distance of gate")
    it("invokes Commands.jump_ship w/ each entity")
    it("raises triggered event on jump gate with each entity")

    describe("callback specified", function(){
      it("invokes callback with jump gate and entities");
    })
  })

  describe("#jump_ship", function(){
    it("sets ship's location parent_id")
    it("invokes manufacture::move_entity")
    describe("successful move_entity result received", function(){
      it("updates ship solar system")
      it("raises jumped event on ship")
    })
  })

  describe("#move_ship", function(){
    it("updates ship's location")
    it("invokes manufactured::move_entity")
    describe("result callback specified", function(){
      it("invokes callback on move_entity result")
    })
  })

  describe("#launch_attack", function(){
    it("invokes manufactured::attack_entity")
    describe("result callback specified", function(){
      it("invokes callback on attack_entity result")
    })
  })

  describe("#dock_ship", function(){
    it("invokes manufactured::dock")
    describe("result callback specified", function(){
      it("invokes callback on dock result")
    })
  })

  describe("#undock_ship", function(){
    it("invokes manufactured::undock")
    describe("result callback specified", function(){
      it("invokes callback on undock result")
    })
  })

  describe("#transfer_resources", function(){
    it("invokes manufactured::transfer_resource for each ship resource")
    describe("result callback specified", function(){
      it("invokes callback on each transfer_resource result")
    })
  })

  describe("#start_mining", function(){
    it("invokes manufactured::start_mining")
    describe("result callback specified", function(){
      it("invokes callback on start_mining result")
    })
  })

  describe("#construct_entity", function(){
    it("invokes manufactured::construct_entity")
    describe("result callback specified", function(){
      it("invokes callback on construct_entity result")
    })
  })

  describe("#assign_mission", function(){
    it("invokes manufactured::assign_mission")
    describe("result callback specified", function(){
      it("invokes callback on assign_mission result")
    })
  })

});}); // Commands
