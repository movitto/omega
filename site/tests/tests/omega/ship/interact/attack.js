// Test mixin usage through ship
pavlov.specify("Omega.ShipAttackInteractions", function(){
describe("Omega.ShipAttackInteractions", function(){
  var ship, page;

  before(function(){
    ship = Omega.Gen.ship();
    ship.location.set(0,0,0);
    ship.init_gfx()
    page = new Omega.Pages.Test();
  });

  describe("#attack_targets", function(){
    before(function(){
      page.session = new Omega.Session({user_id : 'user1'});
      ship.attack_distance = 50;

      /// by default, all will be returned
      page.entities = [];
      for(var e = 0; e < 5; e++){
        var eship = Omega.Gen.ship({user_id : 'user2', hp : 100});
        eship.location.set(0, 0, 0);
        page.entities.push(eship);
      }

      page.entities[0].user_id = 'user1';             /// user owned
      page.entities[2].location.set(5, 5, 5);         /// within valid distance
      page.entities[3].location.set(1000, 1000, 1000) /// outside valid distance
      page.entities[4].hp = 0;                        /// not alive
    });

    it("returns all non-user-owned ships in vicinity that are alive", function(){
      assert(ship._attack_targets(page)).isSameAs([page.entities[1],
                                                   page.entities[2]]);
    });
  });

  describe("#select_attack_target", function(){
    it("shows attack dialog w/ attack targets", function(){
      var ships = [Omega.Gen.ship(), Omega.Gen.ship()];
      sinon.stub(ship, '_attack_targets').returns(ships)
      sinon.stub(ship.dialog(), 'show_attack_dialog');
      ship._select_attack_target(page);
      sinon.assert.calledWith(ship.dialog().show_attack_dialog,
                              page, ship, ships);
    });
  });

  describe("#_start_attacking", function(){
    var tgt, evnt;

    before(function(){
      tgt = Omega.Gen.ship();
      evnt = $.Event('click');
      evnt.currentTarget = $('<span/>');
      evnt.currentTarget.data('target', tgt);

      sinon.stub(page.node, 'http_invoke');
    });

    it("invokes manufactured::attack_entity with command target", function(){
      ship._start_attacking(page, evnt);
      sinon.assert.calledWith(page.node.http_invoke,
        'manufactured::attack_entity', ship.id, tgt.id, sinon.match.func);
    });

    describe("on manufactured::attack_entity response", function(){
      var response_cb;

      before(function(){
        ship._start_attacking(page, evnt);
        response_cb = page.node.http_invoke.omega_callback();
      });

      describe("on failure", function(){
        it("invokes _attack_failed", function(){
          var response = {error  : {message : 'attack err'}};
          sinon.stub(ship, '_attack_failed');
          response_cb(response);
          sinon.assert.calledWith(ship._attack_failed, response);
        });
      });

      describe("on success", function(){
        it("invokes _attack_success", function(){
          var nship = new Omega.Ship({attacking : tgt});
          var response = {result : nship};
          sinon.stub(ship, '_attack_success');
          response_cb(response);
          sinon.assert.calledWith(ship._attack_success, response);
        })
      });
    });

    it("sets attack cycle movement", function(){
      sinon.spy(ship, '_move_for_attack')
      ship._start_attacking(page, evnt);
      sinon.assert.called(ship._move_for_attack);
    });
  });

  describe("#_attack_failed", function(){
    var response = {error  : {message : 'attack err'}};

    before(function(){
      sinon.stub(ship.dialog(), 'show_error_dialog');
      sinon.spy(ship.dialog(), 'append_error');
    });

    after(function(){
      ship.dialog().show_error_dialog.restore();
      ship.dialog().append_error.restore();
    });

    it("shows error dialog", function(){
      ship._attack_failed(response);
      sinon.assert.called(ship.dialog().show_error_dialog);
    });

    it("sets dialog title", function(){
      ship._attack_failed(response);
      assert(ship.dialog().title).equals('Attack Error');
    });

    it("appends error to dialog", function(){
      ship._attack_failed(response);
      sinon.assert.calledWith(ship.dialog().append_error, 'attack err');
    });
  });

  describe("#_attack_success", function(){
    var nship, tgt, response;

    before(function(){
      sinon.stub(ship.dialog(), 'hide');
      sinon.stub(page.audio_controls, 'play');

      tgt      = Omega.Gen.ship();
      nship    = Omega.Gen.ship();
      response = {result : nship};
    });

    after(function(){
      ship.dialog().hide.restore();
    });

    it("hides the dialog", function(){
      ship._attack_success(response, page, tgt);
      sinon.assert.called(ship.dialog().hide);
    });

    it("updates ship attack target", function(){
      ship._attack_success(response, page, tgt);
      assert(ship.attacking).equals(tgt);
    });

    it("updates ship attack graphics", function(){
      sinon.spy(ship, 'update_attack_gfx');
      ship._attack_success(response, page, tgt);
      sinon.assert.called(ship.update_attack_gfx);
    });

    it("plays start_attack ship combat audio", function(){
      ship._attack_success(response, page, tgt);
      sinon.assert.calledWith(page.audio_controls.play,
                              ship.combat_audio, 'start_attack');
    });
  });

  describe("#_move_for_attack", function(){
    var tgt;

    before(function(){
      tgt = Omega.Gen.ship();

      sinon.stub(page.node, 'http_invoke');
    });

    it("invokes manufactured::follow_entity with targets, distance, and strategy", function(){
      ship.attack_distance = 50;
      sinon.stub(ship, '_attack_movement_strategy').returns('strategy');
      ship._move_for_attack(page, tgt);
      sinon.assert.calledWith(page.node.http_invoke,
        'manufactured::follow_entity', ship.id, tgt.id,
        ship.attack_distance / 2, 'strategy', sinon.match.func);
    });

    describe("on manufactured::follow_entity response", function(){
      var response_cb;

      before(function(){
        ship._move_for_attack(page, tgt);
        response_cb = page.node.http_invoke.omega_callback();
      });

      describe("on failure", function(){
        it("invokes _attack_movement_failed", function(){
          var response = {error  : {message : 'movement err'}};
          sinon.stub(ship, '_attack_movement_failed');
          response_cb(response);
          sinon.assert.calledWith(ship._attack_movement_failed, response);
        });
      });

      describe("on success", function(){
        it("invokes _attack_movement_success", function(){
          var nship = new Omega.Ship({});
          var response = {result : nship};
          sinon.stub(ship, '_attack_movement_success');
          response_cb(response);
          sinon.assert.calledWith(ship._attack_movement_success, response);
        });
      });
    });
  });

  describe("#_attack_movement_strategy", function(){
    it("returns strategy for ship weapons class type", function(){
      sinon.stub(ship, 'weapons_class_type').returns('light');
      assert(ship._attack_movement_strategy()).equals('figure8');

      ship = new Omega.Ship();
      sinon.stub(ship, 'weapons_class_type').returns('heavy');
      assert(ship._attack_movement_strategy()).equals('follow');
    });
  });
});});
