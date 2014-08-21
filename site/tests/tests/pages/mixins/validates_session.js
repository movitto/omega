pavlov.specify("Omega.Pages.ValidatesSession", function(){
describe("Omega.Pages.ValidatesSession", function(){
  describe("#validate_session", function(){
    var page, session_valid, session_invalid;

    before(function(){
      page = $.extend({}, Omega.Pages.ValidatesSession);
      page.node = new Omega.Node();
      page._valid_session   = sinon.stub();
      page._invalid_session = sinon.stub();
    });

    after(function(){
      if(Omega.Session.restore_from_cookie.restore)
        Omega.Session.restore_from_cookie.restore();
    });

    it("restores session from cookie", function(){
      sinon.spy(Omega.Session, 'restore_from_cookie');
      page.validate_session();
      sinon.assert.called(Omega.Session.restore_from_cookie);
    });

    describe("session is not null", function(){
      it("validates session", function(){
        var session = new Omega.Session();
        sinon.stub(session, 'validate');
        sinon.stub(Omega.Session, 'restore_from_cookie').returns(session);
        page.validate_session();
        sinon.assert.calledWith(session.validate, page.node, sinon.match.func);
      });

      describe("session is not valid", function(){
        var session;

        before(function(){
          session = new Omega.Session();
          sinon.stub(session, 'validate');
          sinon.stub(Omega.Session, 'restore_from_cookie').returns(session);
          page.validate_session();
        })

        it("invokes _invalid_session", function(){
          session.validate.omega_callback()({error : {}});
          sinon.assert.called(page._invalid_session);
        });
      });

      describe("user session is valid", function(){
        var session;

        before(function(){
          session = new Omega.Session({user_id: 'user1'});
          sinon.spy(session, 'validate');
          sinon.stub(Omega.Session, 'restore_from_cookie').returns(session);
          page.validate_session();
        })

        it("sets session.user", function(){
          var user = Omega.Gen.user();
          session.validate.omega_callback()({result : user});
          assert(session.user).equals(user);
        });

        it("invokes _valid_session", function(){
          session.validate.omega_callback()({});
          sinon.assert.called(page._valid_session);
        })
      });
    });

    describe("#session is null", function(){
      it("invokes _invalid_session", function(){
        sinon.stub(Omega.Session, 'restore_from_cookie').returns(null);
        page.validate_session();
        sinon.assert.called(page._invalid_session);
      });
    });
  });
});});
