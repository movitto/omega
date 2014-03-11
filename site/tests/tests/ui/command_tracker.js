pavlov.specify("Omega.UI.CommandTracker", function(){
describe("Omega.UI.CommandTracker", function(){
  var page, tracker, canvas_reload, canvas_add;

  before(function(){
    var node = new Omega.Node();
    page = new Omega.Pages.Test({node : node,
                                 canvas : Omega.Test.Canvas()});
    page.audio_controls = new Omega.UI.AudioControls({page: page});
    page.audio_controls.disabled = true;
    page.canvas.set_scene_root(new Omega.SolarSystem({id : 'system1'}))
    tracker = new Omega.UI.CommandTracker({page : page});

    /// stub these out so we don't have to load gfx
    canvas_reload = sinon.stub(page.canvas, 'reload');
    canvas_add = sinon.stub(page.canvas, 'add');
  });

  after(function(){
    page.canvas.reload.restore();
    page.canvas.add.restore();
    if(page.canvas.entity_container.refresh.restore) page.canvas.entity_container.refresh.restore();
  });

  describe("#_msg_received", function(){
    before(function(){
      page.entities = [];
    });

    describe("event occurred", function(){
      describe("motel event", function(){
        it("invokes motel_event callback", function(){
          var eargs = [{}];
          var motel_event = sinon.spy(tracker, '_callbacks_motel_event');
          tracker._msg_received('motel::on_rotation', eargs);
          sinon.assert.calledWith(motel_event, 'motel::on_rotation', eargs);
        });
      });

      describe("resource collected event", function(){
        it("invokes resource_collected callback", function(){
          var eargs = ['resource_collected', {}];
          var resource_collected = sinon.spy(tracker, '_callbacks_resource_collected');
          tracker._msg_received('manufactured::event_occurred', eargs);
          sinon.assert.calledWith(resource_collected, 'manufactured::event_occurred', eargs);
        });
      });

      describe("mining stopped event", function(){
        it("invokes mining_stopped callback", function(){
          var eargs = ['mining_stopped', {}];
          var mining_stopped = sinon.spy(tracker, '_callbacks_mining_stopped');
          tracker._msg_received('manufactured::event_occurred', eargs);
          sinon.assert.calledWith(mining_stopped, 'manufactured::event_occurred', eargs);
        });
      });

      describe("attacked event", function(){
        it("invokes attacked callback", function(){
          var eargs    = ['attacked', {}];
          var attacked = sinon.spy(tracker, '_callbacks_attacked');
          tracker._msg_received('manufactured::event_occurred', eargs);
          sinon.assert.calledWith(attacked, 'manufactured::event_occurred', eargs);
        });
      });

      describe("attacked stop event", function(){
        it("invokes attacked_stop callback", function(){
          var eargs = ['attacked_stop', {}];
          var attacked_stop = sinon.spy(tracker, '_callbacks_attacked_stop');
          tracker._msg_received('manufactured::event_occurred', eargs);
          sinon.assert.calledWith(attacked_stop, 'manufactured::event_occurred', eargs);
        });
      });

      describe("defended event", function(){
        it("invokes defended callback", function(){
          var eargs = ['defended', {}];
          var defended = sinon.spy(tracker, '_callbacks_defended');
          tracker._msg_received('manufactured::event_occurred', eargs);
          sinon.assert.calledWith(defended, 'manufactured::event_occurred', eargs);
        });
      });

      describe("defended stop event", function(){
        it("invokes defended_stop callback", function(){
          var eargs = ['defended_stop', {}];
          var defended_stop = sinon.spy(tracker, '_callbacks_defended_stop');
          tracker._msg_received('manufactured::event_occurred', eargs);
          sinon.assert.calledWith(defended_stop, 'manufactured::event_occurred', eargs);
        });
      });

      describe("destroyed_by event", function(){
        it("invokes destroyed_by callback", function(){
          var eargs = ['destroyed_by', {}];
          var destroyed_by = sinon.spy(tracker, '_callbacks_destroyed_by');
          tracker._msg_received('manufactured::event_occurred', eargs);
          sinon.assert.calledWith(destroyed_by, 'manufactured::event_occurred', eargs);
        });
      });

      describe("construction_complete event", function(){
        it("invokes construction_complete callback", function(){
          var eargs = ['construction_complete', {}];
          var construction_complete = sinon.stub(tracker, '_callbacks_construction_complete');
          tracker._msg_received('manufactured::event_occurred', eargs);
          sinon.assert.calledWith(construction_complete, 'manufactured::event_occurred', eargs);
        });
      });

      describe("construction_failed event", function(){
        it("invokes construction_failed callback", function(){
          var eargs = ['construction_failed', {}];
          var construction_failed = sinon.stub(tracker, '_callbacks_construction_failed');
          tracker._msg_received('manufactured::event_occurred', eargs);
          sinon.assert.calledWith(construction_failed, 'manufactured::event_occurred', eargs);
        });
      });

      describe("partial_construction event", function(){
        it("invokes partial_construction callback", function(){
          var eargs = ['partial_construction', {}];
          var partial_construction = sinon.stub(tracker, '_callbacks_partial_construction');
          tracker._msg_received('manufactured::event_occurred', eargs);
          sinon.assert.calledWith(partial_construction, 'manufactured::event_occurred', eargs);
        });
      });

      describe("system_jump event", function(){
        it("invokes system_jump callback", function(){
          var eargs = ['system_jump', {}]
          var system_jump = sinon.stub(tracker, '_callbacks_system_jump');
          tracker._msg_received('manufactured::event_occurred', eargs)
          sinon.assert.calledWith(system_jump, 'manufactured::event_occurred', eargs)
        });
      });
    });
  })

  describe("#track", function(){
    before(function(){
      page.entities = [];
    });

    describe("event handler already registered", function(){
      it("does nothing / just returns", function(){
        tracker.track("motel::on_rotation");
        assert(page.node._listeners['motel::on_rotation'].length).equals(1);
        tracker.track("motel::on_rotation");
        assert(page.node._listeners['motel::on_rotation'].length).equals(1);
      });
    });

    it("adds new node event handler for event", function(){
      var add_listener = sinon.spy(page.node, 'addEventListener');
      tracker.track("motel::on_rotation");
      sinon.assert.calledWith(add_listener, 'motel::on_rotation', sinon.match.func);
    });

    describe("on event", function(){
      it("invokes _msg_received", function(){
        var msg_received = sinon.spy(tracker, "_msg_received");
        tracker.track("motel::on_rotation");
        var handler = page.node._listeners['motel::on_rotation'][0];
        handler({data : ['event_occurred']});
        sinon.assert.calledWith(msg_received, 'motel::on_rotation', ['event_occurred']);
      });
    });
  }); 
});});
