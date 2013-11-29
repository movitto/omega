pavlov.specify("Omega.UI.CommandDialog", function(){
describe("Omega.UI.CommandDialog", function(){
  after(function(){
    Omega.UI.Dialog.remove();
  })

  describe('#append_error', function(){
    it('appends error to dialog', function(){
      var dialog = new Omega.UI.CommandDialog();
      dialog.append_error('command error');
      assert($('#command_error').html()).equals('command error');
    });
  });

  describe("#show_error_dialog", function(){
    it("shows the command_dialog");
  });

  describe("#show_destination_selection_dialog", function(){
    it("sets dialog title");
    it("shows select destination dialog");
    it("sets dest entity id");
    it("sets current x coordinate as dest x");
    it("sets current y coordinate as dest y");
    it("sets current z coordinate as dest z");
    it("wires up move command button");
  });

  describe("on move command button click", function(){
    it("invokes entity._move with coordinates retrieved from inputs")
  });

  describe("#show_attack_dialog", function(){
    it("sets dialog title");
    it("shows select attack target dialog");
    it("sets attack entity id");
    it("adds attack commands for targets to dialog");
    it("sets entity on attack commands");
    it("sets target on attack commands");
  });

  describe("on attack command click", function(){
    it("invokes entity._start_attacking with event");
  });

  describe("#show_docking_dialog", function(){
    it("sets dialog title");
    it("shows select docking station dialog");
    it("sets docking entity id");
    it("adds docking commands for stations to dialog");
    it("sets entity on docking commands");
    it("sets station on docking commands");
  });

  describe("on docking command click", function(){
    it("invokes entity._dock with event");
  });

  describe("#show_mining_dialog", function(){
    it("sets dialog title");
    it("shows select mining target dialog");
    it("sets mining entity id");
  });

  describe("#append_mining_cmd", function(){
    it("adds mining command for specified resource to dialog");
    it("sets entity on mining command")
    it("sets resource on mining command")
  });

  describe("on mining command click", function(){
    it("invokes entity._start_mining with event");
  });
});});
