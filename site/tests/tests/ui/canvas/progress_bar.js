pavlov.specify("Omega.UI.ProgressBar", function(){
describe("Omega.UI.ProgressBar", function(){
  describe("#init_gfx", function(){
    it("creates two progress bar line components");
    it("sets omega_obj on components");
  });

  describe("#update", function(){
    it("it updates line lengths from the specified percentage");
  });

  describe("#clone", function(){
    it("creates new progress bar w/ cloned properties and returns");
  });

  describe("#rendered_in", function(){
    it("updates component to always face camera");
  });
});}); /// Omega.UI.ProgressBar
