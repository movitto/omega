pavlov.specify("Omega.Pages.AccountDetails", function(){
describe("Omega.Pages.AccountDetails", function(){
  var details, page;
  before(function(){
    page = new Omega.Pages.Account();
    details = page.details;
  });

  after(function(){
    Omega.UI.Dialog.remove();
  });

  describe("#wire_up", function(){
    it("wires up account_info_update click events", function(){
      assert($('#account_info_update')).doesNotHandle('click');
      details.wire_up();
      assert($('#account_info_update')).handles('click');
    });

    describe("on account info update click", function(){
      it("invokes this.update", function(){
        var update = sinon.spy(details, '_update');
        details.wire_up();
        $('#account_info_update').click();
        sinon.assert.called(update);
      });
    });
  });

  describe("#update", function(){
    describe("passwords do not match", function(){
      it("shows incorrect passwords dialog", function(){
        sinon.stub(details, 'passwords_match').returns(false);
        var show_dialog = sinon.stub(page.dialog, 'show_incorrect_passwords_dialog');
        details._update();
        sinon.assert.called(show_dialog);
      });
    });

    describe("passwords match", function(){
      it("invokes users::update_user", function(){
        var user = new Omega.User();
        sinon.stub(details, 'user').returns(user);
        var http_invoke = sinon.spy(page.node, 'http_invoke');
        details._update();
        sinon.assert.calledWith(http_invoke, 'users::update_user',
          sinon.match.ofType(Omega.User), sinon.match.func);
        var ruser = http_invoke.getCall(0).args[1];
        assert(ruser).equals(user);
      });

      describe("users::update_user response", function(){
        var request_cb;

        before(function(){
          var http_invoke = sinon.spy(page.node, 'http_invoke');
          details._update();
          request_cb = http_invoke.getCall(0).args[2];
        });

        describe("error response", function(){
          it("shows update error dialog", function(){
            var show_dialog = sinon.spy(page.dialog, 'show_update_error_dialog');
            request_cb({error : {message : 'update error'}})
            sinon.assert.calledWith(show_dialog, 'update error');
          });
        });

        describe("success response", function(){
          it("shows update success dialog", function(){
            var show_dialog = sinon.spy(page.dialog, 'show_update_success_dialog');
            request_cb({});
            sinon.assert.called(show_dialog);
          });
        });
      });
    });
  });

  describe("#username", function(){
    it("sets account info username", function(){
      details.username('foobar');
      assert($('#account_info_username input').val()).equals('foobar');
    });

    it("returns account info username", function(){
      $('#account_info_username input').val('barfoo');
      assert(details.username()).equals('barfoo');
    });
  });

  describe("#password", function(){
    it("returns account info password", function(){
      $('#user_password').val('pass');
      assert(details.password()).equals('pass');
    });
  });

  describe("#password_confirmation", function(){
    it("returns account info password confirmation", function(){
      $('#user_confirm_password').val('pass');
      assert(details.password_confirmation()).equals('pass');
    });
  });

  describe("#email", function(){
    it("sets account info email", function(){
      details.email('foo@bar.com');
      assert($('#account_info_email input').val()).
        equals('foo@bar.com');
    });

    it("returns account info email", function(){
      $('#account_info_email input').val('bar@foo.com');
      assert(details.email()).equals('bar@foo.com');
    });
  });

  //describe("#gravatar", function(){
    //it("sets account info gravatar"); // NIY
  //});

  describe("#entities", function(){
    it("appends ships to account info ships container", function(){
      details.entities([new Omega.Ship({id : 'ship1'}), new Omega.Ship({id : 'ship2'})]);
      details.entities([new Omega.Ship({id : 'ship3'})]);
      assert($('#account_info_ships').html()).equals('ship1 ship2 ship3 ');
    });

    it("appends stations to account info stations container", function(){
      details.entities([new Omega.Station({id : 'station1'}), new Omega.Station({id : 'station2'})]);
      details.entities([new Omega.Station({id : 'station3'})]);
      assert($('#account_info_stations').html()).equals('station1 station2 station3 ');
    });
  });

  describe("#passwords_match", function(){
    describe("user password matches confirmation", function(){
      it("returns true", function(){
        sinon.stub(details, 'password').returns('pass');
        sinon.stub(details, 'password_confirmation').returns('pass');
        assert(details.passwords_match()).isTrue();
      });
    })

    describe("user password does not match confirmation", function(){
      it("returns false", function(){
        sinon.stub(details, 'password').returns('pass');
        sinon.stub(details, 'password_confirmation').returns('ssap');
        assert(details.passwords_match()).isFalse();
      });
    })
  });

  describe("#user", function(){
    it('returns user generated from account info', function(){
      sinon.stub(details, 'username').returns('user');
      sinon.stub(details, 'password').returns('pass');
      sinon.stub(details, 'email').returns('us@e.r');
      var user = details.user();
      assert(user.id).equals('user');
      assert(user.password).equals('pass');
      assert(user.email).equals('us@e.r');
    });
  });

  //describe("#add_badge", function(){
  //  it("adds badge to account info badges") // NIY
  //});
});});

