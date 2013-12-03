pavlov.specify("Omega.Ship", function(){
describe("Omega.Ship", function(){
  var ship, page;

  before(function(){
    ship = new Omega.Ship({id : 'ship1', user_id : 'user1',
                    attack_distance : 100,
                    mining_distance : 100,
                    location  : new Omega.Location({x:99,y:-2,z:100}),
                    resources : [{quantity : 50, material_id : 'gold'},
                                 {quantity : 25, material_id : 'ruby'}]});
    page = new Omega.Pages.Test({canvas: Omega.Test.Canvas(),
                                 node: new Omega.Node() });
  });

  describe("#belongs_to_user", function(){
    it("returns bool indicating if ship belongs to user", function(){
      assert(ship.belongs_to_user('user1')).isTrue();
      assert(ship.belongs_to_user('user2')).isFalse();
    });
  });

  describe("#retrieve_details", function(){
    var details_cb;

    before(function(){
      details_cb = sinon.spy();
    });

    it("invokes details cb with ship id, location, and resources", function(){
      var text = ['Ship: ship1<br/>',
                  '@ 99/-2/100<br/>'      ,
                  'Resources:<br/>'       ,
                  '50 of gold<br/>'       ,
                  '25 of ruby<br/>'      ];

      ship.retrieve_details(page, details_cb);
      sinon.assert.called(details_cb);

      var details = details_cb.getCall(0).args[0];
      assert(details[0]).equals(text[0]);
      assert(details[1]).equals(text[1]);
      assert(details[2]).equals(text[2]);
      assert(details[3]).equals(text[3]);
      assert(details[4]).equals(text[4]);
    });

    it("invokes details with commands", function(){
      ship.retrieve_details(page, details_cb);
      var details = details_cb.getCall(0).args[0];
      for(var c = 0; c < Omega.Ship.prototype.cmds.length; c++){
        var cmd = Omega.Ship.prototype.cmds[c];
        var detail_cmd = details[5+c];
        assert(detail_cmd[0].id).equals(cmd.id + ship.id);
        assert(detail_cmd[0].className).equals(cmd.class);
        assert(detail_cmd.html()).equals(cmd.text);
      }
    });

    it("sets ship in all command data", function(){
      ship.retrieve_details(page, details_cb);
      var details = details_cb.getCall(0).args[0];
      for(var c = 0; c < Omega.Ship.prototype.cmds.length; c++){
        var detail_cmd = details[5+c];
        assert(detail_cmd.data('ship')).equals(ship);;
      }
    });

    it("wires up command click events", function(){
      ship.retrieve_details(page, details_cb);
      var details = details_cb.getCall(0).args[0];
      for(var c = 0; c < Omega.Ship.prototype.cmds.length; c++){
        var detail_cmd = details[5+c];
        assert(detail_cmd).handles('click');
      }
    });

    describe("on command click", function(){
      it("invokes command handler", function(){
        ship.retrieve_details(page, details_cb);
        var details = details_cb.getCall(0).args[0];

        var stubs = [], cmds = [];
        for(var c = 0; c < Omega.Ship.prototype.cmds.length; c++){
          var scmd = Omega.Ship.prototype.cmds[c];
          stubs.push(sinon.stub(ship, scmd['handler']));
          cmds.push(details[5+c]);
        }

        $('#qunit-fixture').append(cmds);
        for(var c = 0; c < cmds.length; c++)
          cmds[c].click();
        for(var s = 0; s < stubs.length; s++)
          sinon.assert.calledWith(stubs[s], page);
      });
    });
  });

  describe("#selected", async(function(){
    it("sets mesh material emissive", function(){
      var ship = Omega.Test.Canvas.Entities().ship;
      ship.retrieve_resource('mesh', function(){
        ship.selected(Omega.Test.Page());
        assert(ship.mesh.material.emissive.getHex()).equals(0xff0000);
        start();
      });
    })
  }));

  describe("#unselected", async(function(){
    it("resets mesh material emissive", function(){
      var ship = Omega.Test.Canvas.Entities().ship;
      ship.retrieve_resource('mesh', function(){
        ship.unselected(Omega.Test.Page());
        assert(ship.mesh.material.emissive.getHex()).equals(0);
        start();
      });
    })
  }));

  describe("#_select_destination", function(){
    it("shows select destination dialog", function(){
      var show_dialog = sinon.spy(ship.dialog(), 'show_destination_selection_dialog');
      ship._select_destination(page);
      sinon.assert.calledWith(show_dialog, page, ship);
    });
  });

  describe("#_move", function(){
    it("invokes manufactured::move_entity with updated location", function(){
      var http_invoke = sinon.spy(page.node, 'http_invoke');
      ship._move(page, 100, 200, -50);
      sinon.assert.calledWith(http_invoke,
        'manufactured::move_entity', ship.id,
        sinon.match.ofType(Omega.Location),
        sinon.match.func);
      var loc = http_invoke.getCall(0).args[2];
      assert(loc).isNotEqualTo(ship.loc);
      assert(loc.x).equals(100);
      assert(loc.y).equals(200);
      assert(loc.z).equals(-50);
    });

    describe("on manufactured::move_entity response", function(){
      var response_cb, nship,
          success_response, error_response;

      before(function(){
        var http_invoke = sinon.spy(page.node, 'http_invoke');
        ship._move(page, 100, 200, -50);
        response_cb = http_invoke.getCall(0).args[3];

        var sloc = new Omega.Location({movement_strategy :
          {json_class : 'Motel::MovementStrategies::Rotate'}});
        nship = new Omega.Ship({location : sloc});
        success_response = {result : nship};
        error_response   = {error  : {message : 'move err'}};
      });

      describe("error response", function(){
        it("shows error dialog", function(){
          var show = sinon.spy(ship.dialog(), 'show_error_dialog');
          response_cb(error_response);
          sinon.assert.called(show);
        });

        it("sets dialog title", function(){
          response_cb(error_response);
          assert(ship.dialog().title).equals('Movement Error');
        });

        it("appends error to dialog", function(){
          var append = sinon.spy(ship.dialog(), 'append_error');
          response_cb(error_response);
          sinon.assert.calledWith(append, 'move err');
        });
      });

      describe("successful response", function(){
        var reload;

        before(function(){
          reload = sinon.stub(page.canvas, 'reload');
        })

        after(function(){
          page.canvas.reload.restore();
        });

        it("hides the dialog", function(){
          var hide = sinon.spy(ship.dialog(), 'hide');
          response_cb(success_response);
          sinon.assert.called(hide);
        });

        it("updates ship movement strategy", function(){
          response_cb(success_response);
          assert(ship.location.movement_strategy).equals(nship.location.movement_strategy);
        });

        it("reloads ship in canvas scene", function(){
          response_cb(success_response);
          sinon.assert.calledWith(reload, ship);
        });

        it("updates ship graphics", function(){
          response_cb(success_response);
          var reload_cb = reload.getCall(0).args[1];

          var update_gfx = sinon.spy(ship, 'update_gfx');
          reload_cb();
          sinon.assert.called(update_gfx);
        });
      });
    });
  });

  describe("#select_attack_target", function(){
    it("shows attack dialog w/ all non-user-owned ships in vicinity", function(){
      var ship1 = new Omega.Ship({user_id : 'user1', location: new Omega.Location({x:101,y:0,z:101})});
      var ship2 = new Omega.Ship({user_id : 'user2', location: new Omega.Location({x:100,y:0,z:100})});
      var ship3 = new Omega.Ship({user_id : 'user2', location: new Omega.Location({x:105,y:5,z:105})});
      var ship4 = new Omega.Ship({user_id : 'user2', location: new Omega.Location({x:1000,y:1000,z:1000})});
      var station1 = new Omega.Station();
      page.entities = [ship1, ship2, ship3, ship4, station1];
      page.session = new Omega.Session({user_id : 'user1'});

      var show_dialog = sinon.spy(ship.dialog(), 'show_attack_dialog');
      ship._select_attack_target(page);
      sinon.assert.calledWith(show_dialog, page, ship, [ship2, ship3]);
    });
  });

  describe("#_start_attacking", function(){
    var tgt, evnt;

    before(function(){
      tgt = new Omega.Ship({id : 'tgt'});
      evnt = $.Event('click');
      evnt.currentTarget = $('<span/>');
      evnt.currentTarget.data('target', tgt);
    });

    it("invokes manufactured::attack_entity with command target", function(){
      var http_invoke = sinon.spy(page.node, 'http_invoke');
      ship._start_attacking(page, evnt);
      sinon.assert.calledWith(http_invoke,
        'manufactured::attack_entity', ship.id,
        tgt.id, sinon.match.func);
    });

    describe("on manufactured::attack_entity response", function(){
      var response_cb, nship,
          success_response, error_response;

      before(function(){
        var http_invoke = sinon.spy(page.node, 'http_invoke');
        ship._start_attacking(page, evnt);
        response_cb = http_invoke.getCall(0).args[3];

        nship = new Omega.Ship({attacking : tgt});
        success_response = {result : nship};
        error_response   = {error  : {message : 'attack err'}};
      });

      describe("error response", function(){
        it("shows error dialog", function(){
          var show = sinon.spy(ship.dialog(), 'show_error_dialog');
          response_cb(error_response);
          sinon.assert.called(show);
        });

        it("sets dialog title", function(){
          response_cb(error_response);
          assert(ship.dialog().title).equals('Attack Error');
        });

        it("appends error to dialog", function(){
          var append = sinon.spy(ship.dialog(), 'append_error');
          response_cb(error_response);
          sinon.assert.calledWith(append, 'attack err');
        });
      });

      describe("successful response", function(){
        var reload;

        before(function(){
          reload = sinon.stub(page.canvas, 'reload');
        })

        after(function(){
          page.canvas.reload.restore();
        });

        it("hides the dialog", function(){
          var hide = sinon.spy(ship.dialog(), 'hide');
          response_cb(success_response);
          sinon.assert.called(hide);
        });

        it("updates ship attack target", function(){
          response_cb(success_response);
          assert(ship.attacking).equals(tgt);
        });

        it("reloads ship in canvas scene", function(){
          response_cb(success_response);
          sinon.assert.calledWith(reload, ship);
        });

        it("updates ship graphics", function(){
          response_cb(success_response);
          var reload_cb = reload.getCall(0).args[1];

          var update_gfx = sinon.spy(ship, 'update_gfx');
          reload_cb();
          sinon.assert.called(update_gfx);
        });
      });
    });
  });

  describe("#_select_docking_station", function(){
    it("shows docking dialog w/ all user-owned stations in vicinity of ship", function(){
      var ship1     = new Omega.Ship();
      var station1  = new Omega.Station({user_id : 'user1', docking_distance : 100,
                                         location : new Omega.Location({x:100,y:0,z:100})});
      var station2  = new Omega.Station({user_id : 'user1', docking_distance : 100,
                                         location : new Omega.Location({x:105,y:5,z:105})});
      var station3  = new Omega.Station({user_id : 'user2', docking_distance: 100});
      var station4  = new Omega.Station({user_id : 'user1', docking_distance : 100,
                                         location : new Omega.Location({x:1000,y:1000,z:1000})});
      page.entities = [ship1, station1, station2, station3, station4];
      page.session  = new Omega.Session({user_id : 'user1'});

      var show_dialog = sinon.spy(ship.dialog(), 'show_docking_dialog');
      ship._select_docking_station(page);
      sinon.assert.calledWith(show_dialog, page, ship, [station1, station2]);
    });
  });

  describe("#_dock", function(){
    var station, evnt;

    before(function(){
      station = new Omega.Station({id : 'station1'});
      evnt = $.Event('click');
      evnt.currentTarget = $('<span/>');
      evnt.currentTarget.data('station', station);
    });

    it("invokes manufacured::dock with command station", function(){
      var http_invoke = sinon.spy(page.node, 'http_invoke');
      ship._dock(page, evnt);
      sinon.assert.calledWith(http_invoke,
        'manufactured::dock', ship.id, station.id,
        sinon.match.func);
    });

    describe("on manufactured::dock response", function(){
      var response_cb, nship,
          success_response, error_response;

      before(function(){
        var http_invoke = sinon.spy(page.node, 'http_invoke');
        ship._dock(page, evnt);
        response_cb = http_invoke.getCall(0).args[3];

        nship = new Omega.Ship({docked_at : station});
        success_response = {result : nship};
        error_response   = {error  : {message : 'dock err'}};
      });

      describe("manufactured::dock error", function(){
        it("shows error dialog", function(){
          var show = sinon.spy(ship.dialog(), 'show_error_dialog');
          response_cb(error_response);
          sinon.assert.called(show);
        });

        it("sets dialog title", function(){
          response_cb(error_response);
          assert(ship.dialog().title).equals('Docking Error');
        });

        it("appends error to dialog", function(){
          var append = sinon.spy(ship.dialog(), 'append_error');
          response_cb(error_response);
          sinon.assert.calledWith(append, 'dock err');
        });
      });

      describe("successful response", function(){
        var reload;

        before(function(){
          reload = sinon.stub(page.canvas, 'reload');
        });

        after(function(){
          page.canvas.reload.restore();
        });

        it("hides the dialog", function(){
          var hide = sinon.spy(ship.dialog(), 'hide');
          response_cb(success_response);
          sinon.assert.called(hide);
        });

        it("updates ship docked at entity", function(){
          response_cb(success_response);
          assert(ship.docked_at).equals(station);
        });

        it("reloads ship in canvas scene", function(){
          response_cb(success_response);
          sinon.assert.calledWith(reload, ship);
        });

        it("updates ship graphics", function(){
          response_cb(success_response);
          var reload_cb = reload.getCall(0).args[1];

          var update_gfx = sinon.spy(ship, 'update_gfx');
          reload_cb();
          sinon.assert.called(update_gfx);
        });
      });
    });
  });

  describe("#_undock", function(){
    before(function(){
      ship.docked_at = new Omega.Station();
    });

    it("invokes manufactured::undock", function(){
      var http_invoke = sinon.spy(page.node, 'http_invoke');
      ship._undock(page);
      sinon.assert.calledWith(http_invoke,
        'manufactured::undock', ship.id,
        sinon.match.func);
    });

    describe("on manufactured::undock response", function(){
      var response_cb, nship,
          success_response, error_response;

      before(function(){
        var http_invoke = sinon.spy(page.node, 'http_invoke');
        ship._undock(page);
        response_cb = http_invoke.getCall(0).args[2];

        nship = new Omega.Ship({});
        success_response = {result : nship};
        error_response   = {error  : {message : 'undock err'}};
      });

      describe("error response", function(){
        it("shows error dialog", function(){
          var show = sinon.spy(ship.dialog(), 'show_error_dialog');
          response_cb(error_response);
          sinon.assert.called(show);
        });

        it("sets dialog title", function(){
          response_cb(error_response);
          assert(ship.dialog().title).equals('Undocking Error');
        });

        it("appends error to dialog", function(){
          var append = sinon.spy(ship.dialog(), 'append_error');
          response_cb(error_response);
          sinon.assert.calledWith(append, 'undock err');
        });
      });

      describe("successful response", function(){
        var reload;

        before(function(){
          reload = sinon.stub(page.canvas, 'reload');
        });

        after(function(){
          page.canvas.reload.restore();
        });

        it("clears ship docked_at entity", function(){
          response_cb(success_response);
          assert(ship.docked_at).isNull();
        });

        it("reloads ship in canvas scene", function(){
          response_cb(success_response);
          sinon.assert.calledWith(reload, ship);
        });

        it("updates ship graphics", function(){
          response_cb(success_response);
          var reload_cb = reload.getCall(0).args[1];

          var update_gfx = sinon.spy(ship, 'update_gfx');
          reload_cb();
          sinon.assert.called(update_gfx);
        });
      });
    });
  });

  describe("#_transfer", function(){
    before(function(){
      ship.docked_to_id = 'station1';

      var res1 = new Omega.Resource();
      var res2 = new Omega.Resource();
      ship.resources = [res1, res2];
    });

    it("invokes manufactured::transfer_resource with all ship resources", function(){
      var http_invoke = sinon.spy(page.node, 'http_invoke');
      ship._transfer(page);
      sinon.assert.calledWith(http_invoke,
        'manufactured::transfer_resource', ship.id,
        ship.docked_to_id, ship.resources[0],
        sinon.match.func);
      sinon.assert.calledWith(http_invoke,
        'manufactured::transfer_resource', ship.id,
        ship.docked_to_id, ship.resources[1],
        sinon.match.func);
    });

    describe("on manufactured::transfer_resource response", function(){
      var response_cb, nship,
          success_response, error_response;

      before(function(){
        var http_invoke = sinon.spy(page.node, 'http_invoke');
        ship._transfer(page);
        response_cb = http_invoke.getCall(0).args[4];

        nship = new Omega.Ship({docked_to : new Omega.Station(),
                                resources : [new Omega.Resource()]});
        success_response = {result : [nship, nship.docked_to]};
        error_response   = {error  : {message : 'transfer err'}};
      });

      describe("error response", function(){
        it("shows error dialog", function(){
          var show = sinon.spy(ship.dialog(), 'show_error_dialog');
          response_cb(error_response);
          sinon.assert.called(show);
        });

        it("sets dialog title", function(){
          response_cb(error_response);
          assert(ship.dialog().title).equals('Transfer Error');
        });

        it("appends error to dialog", function(){
          var append = sinon.spy(ship.dialog(), 'append_error');
          response_cb(error_response);
          sinon.assert.calledWith(append, 'transfer err');
        });
      });

      describe("successful response", function(){
        var reload;

        before(function(){
          reload = sinon.stub(page.canvas, 'reload');
        });

        after(function(){
          page.canvas.reload.restore();
        });

        it("updates ship resources", function(){
          response_cb(success_response);
          assert(ship.resources).equals(nship.resources);
        });

        it("reloads ship in canvas scene", function(){
          response_cb(success_response);
          sinon.assert.calledWith(reload, ship);
        });

        it("updates ship graphics", function(){
          response_cb(success_response);
          var reload_cb = reload.getCall(0).args[1];

          var update_gfx = sinon.spy(ship, 'update_gfx');
          reload_cb();
          sinon.assert.called(update_gfx);
        });
      });
    });
  });

  describe("#_select_mining_target", function(){
    var ast1, ast2, ast3;
    before(function(){
      ast1 = new Omega.Asteroid({id : 'ast1', location : new Omega.Location({x:100,y:0,z:100})})
      ast2 = new Omega.Asteroid({id : 'ast2', location : new Omega.Location({x:101,y:1,z:101})});
      ast3 = new Omega.Asteroid({id : 'ast3', location : new Omega.Location({x:1000,y:1000,z:1000})});
      var asts = [ast1, ast2, ast3];
      page.entities = asts;
    });

    it("shows mining dialog", function(){
      var show_dialog = sinon.spy(ship.dialog(), 'show_mining_dialog');
      ship._select_mining_target(page);
      sinon.assert.calledWith(show_dialog, page, ship);
    });

    it("invokes cosmos::get_resources with each asteroid in vicinity of ship", function(){
      var http_invoke = sinon.spy(page.node, 'http_invoke');
      ship._select_mining_target(page);
      sinon.assert.calledWith(http_invoke, 'cosmos::get_resources', ast1.id);
      sinon.assert.calledWith(http_invoke, 'cosmos::get_resources', ast2.id);
    });

    describe("successfull cosmos::get_resources response", function(){
      var resources, response, response_cb;
      before(function(){
        var http_invoke = sinon.spy(page.node, 'http_invoke');
        ship._select_mining_target(page);
        response_cb = http_invoke.getCall(0).args[2];

        resources = [new Omega.Resource(), new Omega.Resource()];
        response = {result : resources};
      });

      it("appends mining command for resources to dialog", function(){
        var append_cmd = sinon.spy(ship.dialog(), 'append_mining_cmd');
        response_cb(response);
        sinon.assert.calledWith(append_cmd, page, ship, resources[0]);
        sinon.assert.calledWith(append_cmd, page, ship, resources[1]);
      });
    });
  });

  describe("_start_mining", function(){
    var resource, evnt;

    before(function(){
      resource = new Omega.Resource({id : 'res1'});
      evnt = $.Event('click');
      evnt.currentTarget = $('<span/>');
      evnt.currentTarget.data('resource', resource);
    });

    it("invokes manufactured::start_mining with command resource", function(){
      var http_invoke = sinon.spy(page.node, 'http_invoke');
      ship._start_mining(page, evnt);
      sinon.assert.calledWith(http_invoke,
        'manufactured::start_mining', ship.id, resource.id,
        sinon.match.func);
    });

    describe("on manufactured::start_mining response", function(){
      var response_cb, nship,
          success_response, error_response;

      before(function(){
        var http_invoke = sinon.spy(page.node, 'http_invoke');
        ship._start_mining(page, evnt);
        response_cb = http_invoke.getCall(0).args[3];

        nship = new Omega.Ship({mining: resource});
        success_response = {result : nship};
        error_response   = {error  : {message : 'mining err'}};
      });

      describe("manufactured::start_mining error", function(){
        it("shows error dialog", function(){
          var show = sinon.spy(ship.dialog(), 'show_error_dialog');
          response_cb(error_response);
          sinon.assert.called(show);
        });

        it("sets dialog title", function(){
          response_cb(error_response);
          assert(ship.dialog().title).equals('Mining Error');
        });

        it("appends error to dialog", function(){
          var append = sinon.spy(ship.dialog(), 'append_error');
          response_cb(error_response);
          sinon.assert.calledWith(append, 'mining err');
        });
      });

      describe("successful manufactured::start_mining response", function(){
        var reload;

        before(function(){
          reload = sinon.stub(page.canvas, 'reload');
        });

        after(function(){
          page.canvas.reload.restore();
        });

        it("hides the dialog", function(){
          var hide = sinon.spy(ship.dialog(), 'hide');
          response_cb(success_response);
          sinon.assert.called(hide);
        });

        it("updates ship mining target", function(){
          response_cb(success_response);
          assert(ship.mining).equals(nship.mining);
        });

        it("reloads ship in canvas scene", function(){
          response_cb(success_response);
          sinon.assert.calledWith(reload, ship);
        });

        it("updates ship graphics", function(){
          response_cb(success_response);
          var reload_cb = reload.getCall(0).args[1];

          var update_gfx = sinon.spy(ship, 'update_gfx');
          reload_cb();
          sinon.assert.called(update_gfx);
        });
      });
    });
  });

  describe("#load_gfx", function(){
    describe("graphics are initialized", function(){
      var orig;

      before(function(){
        orig = Omega.Ship.gfx;
      });

      after(function(){
        Omega.Ship.gfx = orig;
      });

      it("does nothing / just returns", function(){
        Omega.Ship.gfx = {'corvette' : {lamps:null}};
        new Omega.Ship({type:'corvette'}).load_gfx();
        assert(Omega.Ship.gfx['corvette'].lamps).isNull();
      });
    });

    it("creates mesh for Ship", async(function(){
      var ship = Omega.Test.Canvas.Entities().ship;
      ship.retrieve_resource('mesh', function(){
        assert(Omega.Ship.gfx[ship.type].mesh).isOfType(THREE.Mesh);
        assert(Omega.Ship.gfx[ship.type].mesh.material).isOfType(THREE.MeshLambertMaterial);
        assert(Omega.Ship.gfx[ship.type].mesh.geometry).isOfType(THREE.Geometry);
        start();
        /// TODO assert material texture & geometry src path values
      });
    }));

    it("creates highlight effects for Ship", function(){
      var ship = Omega.Test.Canvas.Entities().ship;
      assert(Omega.Ship.gfx[ship.type].highlight).isOfType(THREE.Mesh);
      assert(Omega.Ship.gfx[ship.type].highlight.material).isOfType(THREE.MeshBasicMaterial);
      assert(Omega.Ship.gfx[ship.type].highlight.geometry).isOfType(THREE.CylinderGeometry);
    });

    it("creates lamps for Ship", function(){
      var ship = Omega.Test.Canvas.Entities().ship;
      assert(Omega.Ship.gfx[ship.type].lamps.length).equals(Omega.Config.resources.ships[ship.type].lamps.length);
      for(var l = 0; l < Omega.Ship.gfx[ship.type].lamps.length; l++){
        var lamp = Omega.Ship.gfx[ship.type].lamps[l];
        assert(lamp).isOfType(THREE.Mesh);
        assert(lamp.material).isOfType(THREE.MeshBasicMaterial);
        assert(lamp.geometry).isOfType(THREE.SphereGeometry);
      }
    });

    it("creates trails for Ship", function(){
      var ship = Omega.Test.Canvas.Entities().ship;
      assert(Omega.Ship.gfx[ship.type].trails.length).equals(Omega.Config.resources.ships[ship.type].trails.length);
      for(var t = 0; t < Omega.Ship.gfx[ship.type].trails.length; t++){
        var trail = Omega.Ship.gfx[ship.type].trails[t];
        assert(trail).isOfType(THREE.ParticleSystem);
        assert(trail.material).isOfType(THREE.ParticleBasicMaterial);
        assert(trail.geometry).isOfType(THREE.Geometry);
      }
    });

    it("creates attack vector for Ship", function(){
      var ship = Omega.Test.Canvas.Entities().ship;
      assert(Omega.Ship.gfx[ship.type].attack_vector).isOfType(THREE.ParticleSystem);
      assert(Omega.Ship.gfx[ship.type].attack_vector.material).isOfType(THREE.ParticleBasicMaterial);
      assert(Omega.Ship.gfx[ship.type].attack_vector.geometry).isOfType(THREE.Geometry);
    });

    it("creates mining vector for Ship", function(){
      var ship = Omega.Test.Canvas.Entities().ship;
      assert(Omega.Ship.gfx[ship.type].mining_vector).isOfType(THREE.Line);
      assert(Omega.Ship.gfx[ship.type].mining_vector.material).isOfType(THREE.LineBasicMaterial);
      assert(Omega.Ship.gfx[ship.type].mining_vector.geometry).isOfType(THREE.Geometry);
    });
  });

  describe("#init_gfx", function(){
    var type = 'corvette';
    var ship;

    before(function(){
      /// preiinit using test page
      Omega.Test.Canvas.Entities();

      ship = new Omega.Ship({type: type,
        location : new Omega.Location({x: 100, y: -100, z: 200})});
    });

    after(function(){
      if(Omega.Ship.gfx){
        if(Omega.Ship.gfx[type].mesh && Omega.Ship.gfx[type].mesh.clone.restore) Omega.Ship.gfx[type].mesh.clone.restore();
        if(Omega.Ship.gfx[type].highlight && Omega.Ship.gfx[type].highlight.clone.restore) Omega.Ship.gfx[type].highlight.clone.restore();
        if(Omega.Ship.gfx[type].lamps)
          for(var l = 0; l < Omega.Ship.gfx[type].lamps.length; l++)
            if(Omega.Ship.gfx[type].lamps[l].clone.restore)
              Omega.Ship.gfx[type].lamps[l].clone.restore();
        if(Omega.Ship.gfx[type].trails)
          for(var t = 0; t < Omega.Ship.gfx[type].trails.length; t++)
            if(Omega.Ship.gfx[type].trails[t].clone.restore)
              Omega.Ship.gfx[type].trails[t].clone.restore();
        if(Omega.Ship.gfx[type].attack_vector && Omega.Ship.gfx[type].attack_vector.clone.restore) Omega.Ship.gfx[type].attack_vector.clone.restore();
        if(Omega.Ship.gfx[type].mining_vector && Omega.Ship.gfx[type].mining_vector.clone.restore) Omega.Ship.gfx[type].mining_vector.clone.restore();
      }
    });

    it("loads ship gfx", function(){
      var ship   = new Omega.Ship({type: type});
      var load_gfx  = sinon.spy(ship, 'load_gfx');
      ship.init_gfx();
      sinon.assert.called(load_gfx);
    });

    it("clones Ship mesh", async(function(){
      var mesh = new THREE.Mesh();
      /// need to wait till template mesh is loaded b4 wiring up stub
      Omega.Ship.prototype.
        retrieve_resource('corvette', 'template_mesh', function(){
          sinon.stub(Omega.Ship.gfx[type].mesh, 'clone').returns(mesh);
        });

      ship.init_gfx();
      ship.retrieve_resource('mesh', function(){
        assert(ship.mesh).equals(mesh);
        start();
      });
    }));

    it("sets mesh position", async(function(){
      ship.init_gfx();
      ship.retrieve_resource('mesh', function(){
        assert(ship.mesh.position.x).equals(100);
        assert(ship.mesh.position.y).equals(-100);
        assert(ship.mesh.position.z).equals(200);
        start();
      });
    }));

    it("sets mesh omega_entity", async(function(){
      ship.init_gfx();
      ship.retrieve_resource('mesh', function(){
        assert(ship.mesh.omega_entity).equals(ship);
        start();
      });
    }));

    it("clones Ship highlight effects", function(){
      var mesh = new THREE.Mesh();
      sinon.stub(Omega.Ship.gfx[type].highlight, 'clone').returns(mesh);
      ship.init_gfx();
      assert(ship.highlight).equals(mesh);
    });

    it("clones Ship lamps", function(){
      var spies = [];
      for(var l = 0; l < Omega.Ship.gfx[type].lamps.length; l++)
        spies.push(sinon.spy(Omega.Ship.gfx[type].lamps[l], 'clone'));
      ship.init_gfx();
      for(var s = 0; s < spies.length; s++)
        sinon.assert.called(spies[s]);
    });

    it("clones Ship trails", function(){
      var spies = [];
      for(var t = 0; t < Omega.Ship.gfx[type].trails.length; t++)
        spies.push(sinon.spy(Omega.Ship.gfx[type].trails[t], 'clone'));
      ship.init_gfx();
      for(var s = 0; s < spies.length; s++)
        sinon.assert.called(spies[s]);
    });

    it("clones Ship attack vector", function(){
      var mesh = new THREE.Mesh();
      sinon.stub(Omega.Ship.gfx[type].attack_vector, 'clone').returns(mesh);
      ship.init_gfx();
      assert(ship.attack_vector).equals(mesh);
    });

    it("clones Ship mining vector", function(){
      var mesh = new THREE.Mesh();
      sinon.stub(Omega.Ship.gfx[type].mining_vector, 'clone').returns(mesh);
      ship.init_gfx();
      assert(ship.mining_vector).equals(mesh);
    });

    it("sets scene components to ship mesh, highlight effects, lamps", function(){
      ship.init_gfx();
      var expected = [ship.mesh, ship.highlight].concat(ship.lamps);
      assert(ship.components).isSameAs(expected);
    });
  });

  describe("#run_effects", function(){
    it("runs lamp effects", function(){
      var ship = new Omega.Ship({type : 'corvette'});
      ship.init_gfx();

      var spies = [];
      for(var l = 0; l < ship.lamps.length; l++)
        spies.push(sinon.spy(ship.lamps[l], 'run_effects'))

      ship.run_effects();

      for(var s = 0; s < spies.length; s++)
        sinon.assert.called(spies[s]);
    });

    /// it("runs trail effects"); // NIY
    /// it("runs attack effects"); // NIY
  });

  describe("#get", function(){
    var node, get_cb, invoke_spy;

    before(function(){
      node = new Omega.Node();
      get_cb = sinon.spy();
      invoke_spy = sinon.stub(node, 'http_invoke');
    });

    it("invokes manufacutred::get_entity request", function(){
      Omega.Ship.get('ship1', node, get_cb);
      sinon.assert.calledWith(invoke_spy,
        'manufactured::get_entity',
        'with_id', 'ship1', sinon.match.func);
    });

    describe("manufactured::get_entity callback", function(){
      var invoke_cb;
      before(function(){
        Omega.Ship.get('ship1', node, get_cb);
        invoke_cb = invoke_spy.getCall(0).args[3];
      });

      it("invokes callback with ship", function(){
        invoke_cb({result : {id: '42'}});
        sinon.assert.calledWith(get_cb, sinon.match.ofType(Omega.Ship), null);
      });

      describe("error received", function(){
        it("invokes callback with error", function(){
          invoke_cb({error : {message : "err"}});
          sinon.assert.calledWith(get_cb, null, "err");
        });
      });
    });
  });

  describe("#owned_by", function(){
    var node, retrieval_cb, invoke_spy;

    before(function(){
      node = new Omega.Node();
      retrieval_cb = sinon.spy();
      invoke_spy = sinon.stub(node, 'http_invoke');
    });

    it("invokes manufactured::get_entities request", function(){
      Omega.Ship.owned_by('user1', node, retrieval_cb);
      sinon.assert.calledWith(invoke_spy, 'manufactured::get_entities',
        'of_type', 'Manufactured::Ship', 'owned_by', 'user1');
    });

    describe("manufactured::get_entity callback", function(){
      it("invokes callback", function(){
        Omega.Ship.owned_by('user1', node, retrieval_cb);
        invoke_spy.getCall(0).args[5]({});
        sinon.assert.called(retrieval_cb);
      });

      it("creates new ship instances", function(){
        Omega.Ship.owned_by('user1', node, retrieval_cb);
        invoke_spy.getCall(0).args[5]({result : [{id: 'sh1'},{id: 'sh2'}]});
        var ships = retrieval_cb.getCall(0).args[0];
        assert(ships.length).equals(2);
        assert(ships[0]).isOfType(Omega.Ship);
        assert(ships[0].id).equals('sh1');
        assert(ships[1]).isOfType(Omega.Ship);
        assert(ships[1].id).equals('sh2');
      });
    });
  });
});}); // Omega.Ship
