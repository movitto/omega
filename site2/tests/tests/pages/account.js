pavlov.specify("Omega.Pages.AccountDetails", function(){
describe("Omega.Pages.AccountDetails", function(){
  describe("#wire_up", function(){
    it("wires up account_info_update click events")
    describe("on account info update click", function(){
      it("invokes this.update")
    });
  });

  describe("#update", function(){
    describe("passwords match", function(){
      it("shows incorrect passwords dialog");
    });

    describe("passwords do not match", function(){
      it("invokes users::update_user")
      describe("users::update_user response", function(){
        describe("error response", function(){
          it("shows update error dialog");
        });

        describe("success response", function(){
          it("shows update success dialog");
        });
      });
    });
  });

  describe("#username", function(){
    it("sets account info username");
    it("returns account info username");
  });

  describe("#password", function(){
    it("returns account info password");
  });

  describe("#email", function(){
    it("sets account info email");
    it("returns account info email");
  });

  describe("#gravatar", function(){
    it("sets account info gravatar");
  });

  describe("#entities", function(){
    it("appends ships to account info ships container");
    it("appends stations to account info stations container");
  });

  describe("#passwords_match", function(){
    describe("user password matches confirmation", function(){
      it("returns true");
    })

    describe("user password does not match confirmation", function(){
      it("returns false");
    })
  });

  describe("#user", function(){
    it('returns user generated from account info');
  });

  describe("#add_badge", function(){
    it("adds badge to account info badges")
  });
});});

pavlov.specify("Omega.Pages.AccountDialog", function(){
describe("Omega.Pages.AccountDialog", function(){
  describe("#show_incorrect_passwords_dialog", functions(){
    it("hides the dialog");
    it("sets the dialog title")
    it("shows the incorrect_passwords dialog");
  });

  describe("#show_update_error_dialog", function(){
    it("hides the dialog");
    it("sets the dialog title")
    it("sets the update error message in the dialog")
    it("shows the user update_error dialog");
  });

  describe("#show_update_success_dialog", function(){
    it("hides the dialog");
    it("sets the dialog title")
    it("shows the user_updated dialog");
  });
});});

pavlov.specify("Omega.Pages.Account", function(){
describe("Omega.Pages.Account", function(){
  it("initializes local config")
  it("inititalizes local node")
  it("initializes account info details")

  it("restores session from cookie")
  it("validates sessions")
  describe("session validated", function(){
    it("populates account info details container")
    it("retrieves ships owned by user")

    describe("retrieve ships callback", function(){
      it("processes_entities with ships retrieved")
    });

    it("retrieves stations owned by user");

    describe("retrieve stations callback", function(){
      it("processes_entities with ships retrieved")
    });

    it("retrieves user stats")

    describe("retrieve stats callback", function(){
      it("processes_stats with stats retrieved")
    });
  });

  describe("invalid session", function(){
    it("clears session")
  });

  describe("#wire_up", function(){
    it("wires up details");
  });

  describe("#process_entities", function(){
    it("processes each entity")
  });

  describe("#process_entity", function(){
    it("adds entity to account info entity details")
  });

  describe("#process_stats", function(){
    describe("local user is in stats", function(){
      it("adds badge to account info badges")
    })
  });
});});
