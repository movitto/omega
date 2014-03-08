/// Test Mixin usage through JumpGate
pavlov.specify("Omega.JumpGateCommands", function(){
describe("Omega.JumpGateCommands", function(){
  var jg, page;

  before(function(){
    jg = Omega.Gen.jump_gate({id : 'jg1', endpoint_id : 'system2'});
    jg.location.set(100, -200, 50.57);

    page = new Omega.Pages.Test({canvas : Omega.Test.Canvas()});
  });

  describe("#retrieve_details", function(){
    var details_cb;

    before(function(){
      details_cb = sinon.spy();
      page.session = new Omega.Session();
    });

    it("invokes details cb with jg endpoint id, location, and trigger command", function(){
      var text = 'Jump Gate to system2<br/>'  +
                 '@ 100/-200/50.57<br/><br/>';

      jg.retrieve_details(page, details_cb);
      sinon.assert.called(details_cb);

      var details = details_cb.getCall(0).args[0];
      assert(details[0]).equals(text);
      assert(details[1][0].id).equals('trigger_jg_jg1');
      assert(details[1][0].className).equals('trigger_jg details_command');
      assert(details[1].text()).equals('trigger');
    });

    describe("page session is null", function(){
      it("does not invoke details with trigger command", function(){
        page.session = null;
        jg.retrieve_details(page, details_cb);
        assert(details_cb.getCall(0).args[0].length).equals(1);
      });
    });

    it("sets jump gate in trigger command data", function(){
      jg.retrieve_details(page, details_cb)
      $('#qunit-fixture').append(details_cb.getCall(0).args[0]);
      assert($('#trigger_jg_jg1').data('jump_gate')).equals(jg);
    });

    it("handles trigger command click event", function(){
      jg.retrieve_details(page, details_cb);
      var trigger_jg = details_cb.getCall(0).args[0][1];
      assert(trigger_jg).handles('click');
    });

    describe("trigger command clicked", function(){
      it("invokes jg.trigger", function(){
        jg.retrieve_details(page, details_cb);
        $('#qunit-fixture').append(details_cb.getCall(0).args[0]);

        var trigger = sinon.stub(jg, '_trigger');
        $('#trigger_jg_jg1').click();
        sinon.assert.calledWith(trigger, page);
      });
    });
  });

  describe("#trigger", function(){
    var ship1, ship2, ship3, ship4, station1;

    before(function(){
      ship1 = new Omega.Ship({user_id : 'user1',
                    location: new Omega.Location({x:100,y:-200,z:50})});
      ship2 = new Omega.Ship({user_id : 'user1',
                    location: new Omega.Location({x:105,y:-200,z:50})});
      ship3 = new Omega.Ship({user_id : 'user1',
                    location: new Omega.Location({x:1500,y:700,z:-1000})});
      ship4 = new Omega.Ship({user_id : 'user2',
                    location: new Omega.Location({x:10,y:20,z:30})});
      station1 = new Omega.Ship({user_id : 'station'});

      jg.endpoint = new Omega.SolarSystem({id : 'system2',
                          location : new Omega.Location({id : 'system2_loc'})})

      page.entities = [ship1, ship2, ship3, ship4, station1];
      page.node     = new Omega.Node();
      page.session  = new Omega.Session({user_id : 'user1'});
    });

    it("invokes manufactured::move_entity on all user owned ships in vicinity of gate", function(){
      var http_invoke = sinon.spy(page.node, 'http_invoke');
      jg._trigger(page);
      sinon.assert.calledWith(http_invoke, 'manufactured::move_entity', ship1.id, ship1.location, sinon.match.func);
      sinon.assert.calledWith(http_invoke, 'manufactured::move_entity', ship2.id, ship2.location, sinon.match.func);
      sinon.assert.neverCalledWith(http_invoke, 'manufactured::move_entity', ship3);
      sinon.assert.neverCalledWith(http_invoke, 'manufactured::move_entity', ship4);
      sinon.assert.neverCalledWith(http_invoke, 'manufactured::move_entity', station1);
    });

    describe("on manufactured::move_entity response", function(){
      var handler, error_response, success_response;

      before(function(){
        var spy = sinon.stub(page.node, 'http_invoke');
        jg._trigger(page);
        handler = spy.getCall(0).args[3];

        error_response = {error : {message : "jg_error"}};
        success_response = {result : null};
      });

      after(function(){
        Omega.UI.Dialog.remove();
      });

      describe("error during commend", function(){
        it("sets command dialog title", function(){
          handler(error_response);
          assert(jg.dialog().title).equals('Jump Gate Trigger Error');
        });

        it("shows command dialog", function(){
          var show = sinon.spy(jg.dialog(), 'show_error_dialog');
          handler(error_response);
          sinon.assert.called(show);
          assert(jg.dialog().component()).isVisible();
        });

        it("appends error to command dialog", function(){
          var append_error = sinon.spy(jg.dialog(), 'append_error');
          handler(error_response);
          sinon.assert.calledWith(append_error, 'jg_error');
          assert($('#command_error').html()).equals('jg_error');
        });
      })

      describe("successful command response", function(){
        after(function(){
          if(page.canvas.remove.restore) page.canvas.remove.restore();
        });

        it("sets new system on registry ship", function(){
          handler(success_response);
          assert(ship1.system_id).equals('system2');
        });

        it("removes ship from canvas scene", function(){
          var spy = sinon.spy(page.canvas, 'remove');
          handler(success_response);
          sinon.assert.calledWith(spy, ship1);
        });
      });
    });
  });
});});
