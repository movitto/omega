pavlov.specify("Omega.UI.IndexNav", function(){
describe("Omega.UI.IndexNav", function(){
  var page;

  before(function(){
    page = new Omega.Pages.Index();
  });

  after(function(){
    if(Omega.UI.IndexNav.prototype.show_login_controls.restore)
      Omega.UI.IndexNav.prototype.show_login_controls.restore();
    if(Omega.UI.IndexNav.prototype.show_logout_controls.restore)
      Omega.UI.IndexNav.prototype.show_logout_controls.restore();
  });

  it("has a handle to page the nav is on", function(){
    var nav = new Omega.UI.IndexNav({page : page});
    assert(nav.page).equals(page);
  });

  describe("#wire_up", function(){
    var nav;

    before(function(){
      nav = new Omega.UI.IndexNav({page : page});
    });

    after(function(){
      Omega.Test.clear_events();
    });

    it("registers login link event handlers", function(){
      assert(nav.login_link).doesNotHandle('click');
      nav.wire_up();
      assert(nav.login_link).handles('click');
    });

    it("registers logout link event handlers", function(){
      assert(nav.logout_link).doesNotHandle('click');
      nav.wire_up();
      assert(nav.logout_link).handles('click');
    });

    it("registers register link event handlers", function(){
      assert(nav.register_link).doesNotHandle('click');
      nav.wire_up();
      assert(nav.register_link).handles('click');
    });
  });

  describe("user clicks login link", function(){
    var nav;

    before(function(){
      page.dialog  = new Omega.UI.IndexDialog({page: page});
      nav = new Omega.UI.IndexNav({page : page});
      nav.wire_up();
    });

    after(function(){
      Omega.Test.clear_events();
    });

    it("invokes index_dialog.show_login_dialog", function(){
      page.dialog = new Omega.UI.IndexDialog();
      var spy = sinon.spy(page.dialog, 'show_login_dialog');
      nav.login_link.click();
      sinon.assert.called(spy);
    });
  });

  describe("user clicks register link", function(){
    var nav;

    before(function(){
      page.dialog  = new Omega.UI.IndexDialog({page: page});
      nav = new Omega.UI.IndexNav({page : page});
      nav.wire_up();
    });

    after(function(){
      Omega.Test.clear_events();
    });

    it("invokes index_dialog.show_register_dialog", function(){
      var spy = sinon.spy(page.dialog, 'show_register_dialog');
      nav.register_link.click();
      sinon.assert.called(spy);
    });
  });

  describe("user clicks logout link", function(){
    var nav;

    before(function(){
      page.session = new Omega.Session();
      nav = new Omega.UI.IndexNav({page : page});
      nav.wire_up();
    });

    after(function(){
      Omega.Test.clear_events();
    });

    it("invokes session.logout", function(){
      var spy = sinon.spy(page.session, 'logout');
      nav.logout_link.click();
      sinon.assert.called(spy);
    });

    it("shows login controls", function(){
      var spy = sinon.spy(nav, 'show_login_controls');
      nav.logout_link.click();
      sinon.assert.called(spy);
    });
  });

  describe("#show_login_controls", function(){
    it("shows the register link", function(){
      var nav = new Omega.UI.IndexNav();
      nav.show_login_controls();
      assert(nav.register_link).isVisible();
    });

    it("shows the login link", function(){
      var nav = new Omega.UI.IndexNav();
      nav.show_login_controls();
      assert(nav.login_link).isVisible();
    });

    it("hides the account link", function(){
      var nav = new Omega.UI.IndexNav();
      nav.show_login_controls();
      assert(nav.account_link).isHidden();
    });

    it("hides the logout link", function(){
      var nav = new Omega.UI.IndexNav();
      nav.show_login_controls();
      assert(nav.logout_link).isHidden();
    });
  });

  describe("#show_logout_controls", function(){
    it("hides the register link", function(){
      var nav = new Omega.UI.IndexNav();
      nav.show_logout_controls();
      assert(nav.register_link).isHidden();
    });

    it("hides the login link", function(){
      var nav = new Omega.UI.IndexNav();
      nav.show_logout_controls();
      assert(nav.login_link).isHidden();
    });

    it("shows the account link", function(){
      var nav = new Omega.UI.IndexNav();
      nav.show_logout_controls();
      assert(nav.account_link).isVisible();
    });

    it("shows the logout link", function(){
      var nav = new Omega.UI.IndexNav();
      nav.show_logout_controls();
      assert(nav.logout_link).isVisible();
    });
  });
});});

pavlov.specify("Omega.UI.IndexDialog", function(){
describe("Omega.UI.IndexDialog", function(){
  var page, dialog;

  before(function(){
    page   = new Omega.Pages.Index();
    dialog = new Omega.UI.IndexDialog({page : page});
  });

  after(function(){
    Omega.UI.Dialog.remove();
  })

  it("has a handle to page the dialog is on", function(){
    assert(dialog.page).equals(page);
  });

  describe("#wire_up", function(){
    after(function(){
      Omega.Test.clear_events();
    });

    it("registers login button event handlers", function(){
      assert(dialog.login_button).doesNotHandle('click');
      dialog.wire_up();
      assert(dialog.login_button).handles('click');
    });

    it("registers register button event handlers", function(){
      assert(dialog.register_button).doesNotHandle('click');
      dialog.wire_up();
      assert(dialog.register_button).handles('click');
    });
  });

  describe("#show_login_dialog", function(){
    it("hides the dialog", function(){
      var dialog = new Omega.UI.IndexDialog();
      var spy = sinon.spy(dialog, 'hide');
      dialog.show_login_dialog();
      sinon.assert.called(spy);
    });

    it("displays login dialog", function(){
      var dialog = new Omega.UI.IndexDialog();
      dialog.show_login_dialog();
      assert(dialog.title).equals('Login');
      assert(dialog.div_id).equals('#login_dialog');
    });

    it("shows the dialog", function(){
      var dialog = new Omega.UI.IndexDialog();
      dialog.show_login_dialog();
      assert(dialog.dialog()).isVisible();
    });
  });

  describe("#show_register_dialog", function(){
    var page;

    before(function(){
      page = new Omega.Pages.Index();
    })

    after(function(){
      if(Recaptcha.create.restore) Recaptcha.create.restore();
    })

    it("hides the dialog", function(){
      var dialog = new Omega.UI.IndexDialog({page: page});
      var spy = sinon.spy(dialog, 'hide');
      dialog.show_register_dialog();
      sinon.assert.called(spy);
    });

    it("generates a recaptcha", function(){
      var spy = sinon.spy(Recaptcha, 'create')
      var dialog = new Omega.UI.IndexDialog({page: page});
      dialog.show_register_dialog();
      sinon.assert.calledWith(spy, page.config.recaptcha_pub, "omega_recaptcha")
    });

    it("displays register dialog", function(){
      var dialog = new Omega.UI.IndexDialog({page: page});
      dialog.show_register_dialog();
      assert(dialog.title).equals('Register');
      assert(dialog.div_id).equals('#register_dialog');
    });

    it("shows the dialog", function(){
      var dialog = new Omega.UI.IndexDialog({page: page});
      dialog.show_register_dialog();
      assert(dialog.dialog()).isVisible();
    });
  });

  describe("#show_login_failed_dialog", function(){
    it("hides the dialog", function(){
      var dialog = new Omega.UI.IndexDialog();
      var spy = sinon.spy(dialog, 'hide');
      dialog.show_login_failed_dialog();
      sinon.assert.called(spy);
    });

    it("displays login failed dialog", function(){
      var dialog = new Omega.UI.IndexDialog();
      dialog.show_login_failed_dialog();
      assert(dialog.title).equals('Login Failed');
      assert(dialog.div_id).equals('#login_failed_dialog');
    });

    it("sets login error", function(){
      var dialog = new Omega.UI.IndexDialog();
      dialog.show_login_failed_dialog('invalid credentials');
      assert($('#login_err').html()).equals('Login Failed: invalid credentials');
    });

    it("shows the dialog", function(){
      var dialog = new Omega.UI.IndexDialog();
      dialog.show_login_failed_dialog();
      assert(dialog.dialog()).isVisible();
    });
  });

  describe("#show_registration_submitted_dialog", function(){
    it("hides the dialog", function(){
      var dialog = new Omega.UI.IndexDialog();
      var spy = sinon.spy(dialog, 'hide');
      dialog.show_registration_submitted_dialog();
      sinon.assert.called(spy);
    });

    it("displays registration submitted dialog", function(){
      var dialog = new Omega.UI.IndexDialog();
      dialog.show_registration_submitted_dialog();
      assert(dialog.title).equals('Registration Submitted');
      assert(dialog.div_id).equals('#registration_submitted_dialog');
    });

    it("shows the dialog", function(){
      var dialog = new Omega.UI.IndexDialog();
      dialog.show_registration_submitted_dialog();
      assert(dialog.dialog()).isVisible();
    });
  });

  describe("#show_registration_failed_dialog", function(){
    it("hides the dialog", function(){
      var dialog = new Omega.UI.IndexDialog();
      var spy = sinon.spy(dialog, 'hide');
      dialog.show_registration_failed_dialog();
      sinon.assert.called(spy);
    });

    it("displays registration failed dialog", function(){
      var dialog = new Omega.UI.IndexDialog();
      dialog.show_registration_failed_dialog();
      assert(dialog.title).equals('Registration Failed');
      assert(dialog.div_id).equals('#registration_failed_dialog');
    });

    it("sets registration error", function(){
      var dialog = new Omega.UI.IndexDialog();
      dialog.show_registration_failed_dialog('invalid email');
      assert($('#registration_err').html()).equals('Failed to create account: invalid email');
    });

    it("shows the dialog", function(){
      var dialog = new Omega.UI.IndexDialog();
      dialog.show_registration_failed_dialog();
      assert(dialog.dialog()).isVisible();
    });
  });

  describe("login button clicked", function(){
    var dialog, page;

    before(function(){
      page = new Omega.Pages.Index();
      dialog = page.dialog;
      dialog.wire_up();

      $('#login_username').attr('value', 'uid');
      $('#login_password').attr('value', 'ups');
    })

    after(function(){
      if(Omega.Session.login.restore) Omega.Session.login.restore();
      Omega.Test.clear_events();
    })

    it("logs user in with session", function(){
      var spy = sinon.spy(Omega.Session, 'login')
      dialog.login_button.click();
      sinon.assert.calledWith(spy, sinon.match(function(v){
        return v.id == 'uid' && v.password == 'ups';
      }), page.node);
    });

    describe("login error", function(){
      it("shows login_failed dialog", function(){
        var spy = sinon.stub(Omega.Session, 'login')
        dialog.login_button.click();

        var login_callback = spy.getCall(0).args[2];
        spy = sinon.spy(dialog, 'show_login_failed_dialog');
        login_callback.apply(null, [{error: {message: 'invalid credentials'}}]);
        sinon.assert.calledWith(spy, 'invalid credentials');
      });
    });

    describe("valid login", function(){
      var login_callback, session;

      before(function(){
        var stub = sinon.stub(Omega.Session, 'login')
        dialog.login_button.click();
        login_callback = stub.getCall(0).args[2];
        session = new Omega.Session();
        session.id = 'foo'
      })

      it("hides login dialog", function(){
        dialog.show_login_dialog();
        login_callback.apply(null, [session]);
        assert(dialog.dialog()).isHidden();
      });

      it("sets page session", function(){
        login_callback.apply(null, [session]);
        assert(page.session).equals(session);
      });

      it("shows page navigation logout controls", function(){
        var spy = sinon.spy(page.nav, 'show_logout_controls');
        login_callback.apply(null, [session]);
        sinon.assert.called(spy);
      });
    });
  });

  describe("register button clicked", function(){
    var page, dialog;

    before(function(){
      page = new Omega.Pages.Index();
      dialog = page.dialog;
      dialog.wire_up();

      $('#register_username').attr('value', 'uid');
      $('#register_password').attr('value', 'ups');
      $('#register_email').attr('value', 'uem');
    });

    after(function(){
      Omega.Test.clear_events();
    });

    it("sends user registration", function(){
      var spy = sinon.spy(page.node, 'http_invoke');
      dialog.register_button.click();
      sinon.assert.calledWith(spy, 'users::register', sinon.match(function(v){
        // TODO also validate recaptcha / recaptcha response
        return v.id == 'uid' && v.password == 'ups' && v.email == 'uem';
      }));
    });

    describe("registration error", function(){
      it("shows registration failed dialog", function(){
        var spy = sinon.spy(page.node, 'http_invoke');
        dialog.register_button.click();

        var register_callback = spy.getCall(0).args[2];
        spy = sinon.spy(dialog, 'show_registration_failed_dialog');
        register_callback.apply(null, [{error: {message: 'invalid email'}}]);
        sinon.assert.calledWith(spy, 'invalid email');
      });
    });

    describe("successful registration", function(){
      it("displays registration email dialog", function(){
        var spy = sinon.spy(page.node, 'http_invoke');
        dialog.register_button.click();

        var register_callback = spy.getCall(0).args[2];
        spy = sinon.spy(dialog, 'show_registration_submitted_dialog');
        register_callback.apply(null, [{}])
        sinon.assert.called(spy);
      });
    });
  });
});});

pavlov.specify("Omega.Pages.Index", function(){
describe("Omega.Pages.Index", function(){
  after(function(){
    if(Omega.Session.restore_from_cookie.restore) Omega.Session.restore_from_cookie.restore();
    if(Omega.UI.StatusIndicator.restore) Omega.UI.StatusIndicator.restore();
  });

  it("loads config", function(){
    var index = new Omega.Pages.Index();
    assert(index.config).equals(Omega.Config);
  });

  it("has a node", function(){
    var index = new Omega.Pages.Index();
    assert(index.node).isOfType(Omega.Node);
  });

  it("has an entities registry", function(){
    var index = new Omega.Pages.Index();
    assert(index.entities).isSameAs({});
  });

  it("has a command tracker", function(){
    var index = new Omega.Pages.Index();
    assert(index.command_tracker).isOfType(Omega.UI.CommandTracker);
  });

  it("has a session restored from cookie", function(){
    var spy = sinon.spy(Omega.Session, 'restore_from_cookie');
    var index = new Omega.Pages.Index();
    sinon.assert.called(spy);
  });

  describe("session is not null", function(){
    it("validates session", function(){
      var session = new Omega.Session();
      var spy = sinon.spy(session, 'validate');
      var stub = sinon.stub(Omega.Session, 'restore_from_cookie').returns(session);
      var index = new Omega.Pages.Index();
      sinon.assert.calledWith(spy, index.node);
    });

    describe("session is not valid", function(){
      var index, validate_cb;

      before(function(){
        var session = new Omega.Session();
        var spy = sinon.spy(session, 'validate');
        var stub = sinon.stub(Omega.Session, 'restore_from_cookie').returns(session);

        index = new Omega.Pages.Index();
        validate_cb = spy.getCall(0).args[1];
      })

      it("nullifies session", function(){
        validate_cb.apply(null, [{error : {}}]);
        assert(index.session).isNull();
      });

      it("shows login controls", function(){
        var spy = sinon.spy(index.nav, 'show_login_controls');
        validate_cb.apply(null, [{error : {}}]);
        sinon.assert.called(spy);
      });
    });

    describe("user session is valid", function(){
      var index, session, validate_cb;

      before(function(){
        session = new Omega.Session({user_id: 'user1'});
        var spy = sinon.spy(session, 'validate');
        var stub = sinon.stub(Omega.Session, 'restore_from_cookie').returns(session);

        index = new Omega.Pages.Index();
        validate_cb = spy.getCall(0).args[1];
      })

      after(function(){
        if(Omega.Ship.owned_by.restore) Omega.Ship.owned_by.restore();
        if(Omega.Station.owned_by.restore) Omega.Station.owned_by.restore();
      });

      it("shows logout controls", function(){
        spy = sinon.spy(index.nav, 'show_logout_controls');
        validate_cb.apply(null, [{}]);
        sinon.assert.called(spy);
      });

      it("retrieves ships owned by user", function(){
        var spy = sinon.spy(Omega.Ship, 'owned_by');
        validate_cb.apply(null, [{}]);
        sinon.assert.calledWith(spy, session.user_id, index.node, sinon.match.func);
      });

      it("retrieves stations owned by user", function(){
        var spy = sinon.spy(Omega.Station, 'owned_by');
        validate_cb.apply(null, [{}]);
        sinon.assert.calledWith(spy, session.user_id, index.node, sinon.match.func);
      });

      it("processes entities retrieved", function(){
        var shspy = sinon.spy(Omega.Ship, 'owned_by');
        var stspy = sinon.spy(Omega.Station, 'owned_by');
        validate_cb.apply(null, [{}]);

        var shcb = shspy.getCall(0).args[2];
        var stcb = stspy.getCall(0).args[2];

        var spy = sinon.stub(index, 'process_entities');
        shcb('ships')
        stcb('stations');
        sinon.assert.calledWith(spy, 'ships');
        sinon.assert.calledWith(spy, 'stations');
      });
    });
  });

  //describe("#handle_events", function(){
  //  it("tracks all motel and manufactured events");
  //});

  describe("#process_entities", function(){
    var index, ships;

    before(function(){
      index = new Omega.Pages.Index();
      ships = [new Omega.Ship({id: 'sh1', system_id: 'sys1'}),
               new Omega.Ship({id: 'sh2', system_id: 'sys2'})];
    });

    after(function(){
      if(Omega.SolarSystem.with_id.restore) Omega.SolarSystem.with_id.restore();
    });

    it("handles events", function(){
      var handle_events = sinon.spy(index, 'handle_events');
      index.process_entities(ships);
      sinon.assert.called(handle_events);
    });
    
    it("invokes process_entity with each entity", function(){
      var process_entity = sinon.spy(index, 'process_entity');
      index.process_entities(ships);
      sinon.assert.calledWith(process_entity, ships[0]);
      sinon.assert.calledWith(process_entity, ships[1]);
    });
  });

  describe("#process_entity", function(){
    var index, ship, station;
    before(function(){
      index = new Omega.Pages.Index();
      ship  = new Omega.Ship({id: 'sh1', system_id: 'sys1'});
      station = new Omega.Station({id : 'st1', system_id : 'sys1'})
    });

    after(function(){
      if(Omega.SolarSystem.with_id.restore) Omega.SolarSystem.with_id.restore();
    })

    it("stores entity in registry", function(){
      index.process_entity(ship);
      assert(index.entities).includes(ship);
    });

    it("adds entities to entities_list", function(){
      var spy = sinon.spy(index.canvas.controls.entities_list, 'add');
      index.process_entity(ship);
      sinon.assert.calledWith(spy, {id: 'sh1', text: 'sh1', data: ship});
    });

    it("retrieves systems entities are in", function(){
      var spy = sinon.spy(Omega.SolarSystem, 'with_id');
      index.process_entity(ship);
      sinon.assert.calledWith(spy, 'sys1', index.node, sinon.match.func);
    });

    it("processes systems retrieved", function(){
      var spy = sinon.spy(Omega.SolarSystem, 'with_id');
      index.process_entity(ship);
      var cb = spy.getCall(0).args[2];

      spy = sinon.spy(index, 'process_system');
      var sys1 = {};
      cb(sys1);
      sinon.assert.calledWith(spy, sys1);
    });

    it("tracks ships", function(){
      var track_ship = sinon.spy(index, 'track_ship');
      index.process_entity(ship);
      sinon.assert.calledWith(track_ship, ship);
    });

    it("tracks stations", function(){
      var track_station = sinon.spy(index, 'track_station');
      index.process_entity(station);
      sinon.assert.calledWith(track_station, station);
    });
  });

  describe("#track_ship", function(){
    var index, ship, ws_invoke;
    before(function(){
      index = new Omega.Pages.Index();
      ship = new Omega.Ship({id : 'ship42',
                             location : new Omega.Location({id:'loc42'})}); 
      ws_invoke = sinon.stub(index.node, 'ws_invoke');
    });

    it("invokes motel::track_strategy", function(){
      index.track_ship(ship);
      sinon.assert.calledWith(ws_invoke, 'motel::track_strategy', ship.location.id);
    });

    it("invokes motel::track_stops", function(){
      index.track_ship(ship);
      sinon.assert.calledWith(ws_invoke, 'motel::track_stops', ship.location.id);
    });

    it("invokes motel::track_movement", function(){
      index.track_ship(ship);
      sinon.assert.calledWith(ws_invoke, 'motel::track_movement', ship.location.id, index.config.ship_movement);
    });

    it("invokes motel::track_rotation", function(){
      index.track_ship(ship);
      sinon.assert.calledWith(ws_invoke, 'motel::track_rotation', ship.location.id, index.config.ship_rotation);
    });

    it("invokes motel::subscribe_to resource_collected", function(){
      index.track_ship(ship);
      sinon.assert.calledWith(ws_invoke, 'manufactured::subscribe_to', ship.id, 'resource_collected');
    });

    it("invokes motel::subscribe_to mining_stopped", function(){
      index.track_ship(ship);
      sinon.assert.calledWith(ws_invoke, 'manufactured::subscribe_to', ship.id, 'mining_stopped');
    });

    it("invokes motel::subscribe_to attacked", function(){
      index.track_ship(ship);
      sinon.assert.calledWith(ws_invoke, 'manufactured::subscribe_to', ship.id, 'attacked');
    });

    it("invokes motel::subscribe_to attacked_stop", function(){
      index.track_ship(ship);
      sinon.assert.calledWith(ws_invoke, 'manufactured::subscribe_to', ship.id, 'attacked_stop');
    });

    it("invokes motel::subscribe_to defended", function(){
      index.track_ship(ship);
      sinon.assert.calledWith(ws_invoke, 'manufactured::subscribe_to', ship.id, 'defended');
    });

    it("invokes motel::subscribe_to defended_stop", function(){
      index.track_ship(ship);
      sinon.assert.calledWith(ws_invoke, 'manufactured::subscribe_to', ship.id, 'defended_stop');
    });

    it("invokes motel::subscribe_to destroyed_by", function(){
      index.track_ship(ship);
      sinon.assert.calledWith(ws_invoke, 'manufactured::subscribe_to', ship.id, 'destroyed_by');
    });
  });

  describe("#track_station", function(){
    var index, station, ws_invoke;
    before(function(){
      index   = new Omega.Pages.Index();
      station = new Omega.Station({id : 'station42',
                                   location : new Omega.Location({id:'loc42'})}); 
      ws_invoke = sinon.stub(index.node, 'ws_invoke');
    });

    it("invokes manufactured::subscribe_to construction_complete", function(){
      index.track_station(station);
      sinon.assert.calledWith(ws_invoke, 'manufactured::subscribe_to', station.id, 'construction_complete');
    });

    it("invokes manufactured::subscribe_to partial_construction", function(){
      index.track_station(station);
      sinon.assert.calledWith(ws_invoke, 'manufactured::subscribe_to', station.id, 'partial_construction');
    });
  });

  describe("#process_system", function(){
    var index, system;

    before(function(){
      index = new Omega.Pages.Index();
      system = {id: 'system1', name: 'systema', galaxy_id: 'gal1'}
    });

    after(function(){
      if(Omega.Galaxy.with_id.restore) Omega.Galaxy.with_id.restore();
    });

    it("adds system to locations_list", function(){
      var spy = sinon.spy(index.canvas.controls.locations_list, 'add');
      index.process_system(system)
      sinon.assert.calledWith(spy, {id: 'system1', text: 'systema', data: system});
    });

    it("adds retrieves galaxy system is in", function(){
      var spy = sinon.spy(Omega.Galaxy, 'with_id');
      index.process_system(system)
      sinon.assert.calledWith(spy, system.parent_id);
    });

    it("processes galaxy", function(){
      var spy = sinon.spy(Omega.Galaxy, 'with_id');
      index.process_system(system)
      var cb = spy.getCall(0).args[2];

      spy = sinon.spy(index, 'process_galaxy');
      var galaxy = {};
      cb(galaxy);
      sinon.assert.calledWith(spy, galaxy);
    });
  });

  describe("#process_galaxy", function(){
    it("adds galaxy to locations_list", function(){
      var index = new Omega.Pages.Index();
      var galaxy = {id: 'galaxy1', name: 'galaxya'}

      var spy = sinon.spy(index.canvas.controls.locations_list, 'add');
      index.process_galaxy(galaxy)
      sinon.assert.calledWith(spy, {id: 'galaxy1', text: 'galaxya', data: galaxy});
    });
  });

  it("has a status indicator", function(){
    var index = new Omega.Pages.Index();
    assert(index.status_indicator).isOfType(Omega.UI.StatusIndicator);
  });

  it("instructs status indicator to follow node", function(){
    var si    = new Omega.UI.StatusIndicator();
    var spy   = sinon.spy(si, 'follow_node');
    var stub  = sinon.stub(Omega.UI, 'StatusIndicator').returns(si);
    var index = new Omega.Pages.Index();
    sinon.assert.calledWith(spy, index.node);
  })

  it("has an index dialog", function(){
    var index = new Omega.Pages.Index();
    assert(index.dialog).isOfType(Omega.UI.IndexDialog);
    assert(index.dialog.page).isSameAs(index);
  });

  it("has an index nav", function(){
    var index = new Omega.Pages.Index();
    assert(index.nav).isOfType(Omega.UI.IndexNav);
    assert(index.nav.page).isSameAs(index);
  });

  it("has a canvas", function(){
    var index = new Omega.Pages.Index();
    assert(index.canvas).isOfType(Omega.UI.Canvas);
  });

  describe("#entity", function(){
    it("gets/sets entity", function(){
      var index = new Omega.Pages.Index();
      var foo = {};
      index.entity('foo', foo);
      assert(index.entity('foo')).equals(foo);
    });
  });

  describe("#wire_up", function(){
    var index,
        wire_nav, wire_dialog, wire_canvas;

    before(function(){
      index = new Omega.Pages.Index();
      wire_nav    = sinon.stub(index.nav,    'wire_up');
      wire_dialog = sinon.stub(index.dialog, 'wire_up');
      wire_canvas = sinon.stub(index.canvas, 'wire_up');
    });

    it("wires up navigation", function(){
      index.wire_up();
      sinon.assert.called(wire_nav);
    });

    it("wires up dialog", function(){
      index.wire_up();
      sinon.assert.called(wire_dialog);
    });

    it("wires up canvas", function(){
      index.wire_up();
      sinon.assert.called(wire_canvas);
    });
  });
});});
