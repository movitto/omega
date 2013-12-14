pavlov.specify("Omega.UI.Loader", function(){
describe("Omega.UI.Loader", function(){
  describe("#json", function(){
    it("provides singleton THREE.JSONLoader", function(){
      assert(Omega.UI.Loader.json()).isOfType(THREE.JSONLoader);
      assert(Omega.UI.Loader.json()).equals(Omega.UI.Loader.json());
    })
  });

  describe("#preload", function(){
    ///it("preloads all configured resources"); NIY
  });
});});
