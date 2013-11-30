pavlov.specify("Omega.Stat", function(){
describe("Omega.Stat", function(){
  describe("Stat#get", function(){
    it("invokes stats::get to retrieve stat");
    describe("stats::get response", function(){
      it("converts results into Omega.Stat instances");
      it("invokes callback with stats");
    })
  });
});});
