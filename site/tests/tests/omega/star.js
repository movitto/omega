pavlov.specify("Omega.Star", function(){
describe("Omega.Star", function(){
  it("parses type(color) into int", function(){
    var star = new Omega.Star({type: 'ABABAB'});
    assert(star.type_int).equals(0xABABAB);
  });

  describe("#toJSON", function(){
    it("returns planet json data", function(){
      var st  = {id          : 'st1',
                 name        : 'st1n',
                 parent_id   : 'sys1',
                 location    : new Omega.Location({id : 'st1l'}),
                 type        : 'ABABAB',
                 size        : 100};

      var ost  = new Omega.Star(st);
      var json = ost.toJSON();

      st.json_class  = ost.json_class;
      st.location    = st.location.toJSON();
      assert(json).isSameAs(st);
    });
  });

  //describe("#clicked_in", function(){
  //  it("resets canvas cam"); /// NIY
  //});
});}); // Omega.Star
