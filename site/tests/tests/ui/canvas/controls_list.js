pavlov.specify("Omega.UI.CanvasControlsList", function(){
describe("Omega.UI.CanvasControlsList", function(){
  var list;

  before(function(){
    list = new Omega.UI.CanvasControlsList({div_id: '#locations_list'});
    list.wire_up();
  })

  after(function(){
    Omega.Test.clear_events();
  })

  describe("mouse enter event", function(){
    //it("sets has mouse true"); /// NIY
    //it("stops list effects"); /// NIY

    it("shows child ul", function(){
      list.component().mouseenter();
      assert(list.list()).isVisible();
    });
  });

  describe("mouse leave event", function(){
    //it("sets has mouse false"); /// NIY

    it("hides child ul", function(){
      list.component().mouseenter();
      list.component().mouseleave();
      assert(list.list()).isHidden();
    });
  });

  describe("#component", function(){
    it("returns list jquery component", function(){
      assert(list.component()).isSameAs($('#locations_list'));
    });
  });

  describe("#list", function(){
    it("returns list dom component", function(){
      assert(list.list()).isSameAs($($('#locations_list ul')[0]));
    });
  });

  describe("#children", function(){
    it("returns children under list", function(){
      $('#locations_list ul').append('<li id="c1"/>');
      assert(list.children().length).equals(1);
      assert(list.children()[0].id).equals('c1');
    });
  });

  describe("#title", function(){
    //it("returns first non-ul dom component under list"); /// NIY
  });

  describe("#clear", function(){
    it("clears list items", function(){
      var item = {};
      list.add(item)
      list.clear();
      assert(list.list().children('li').length).equals(0);
    });
  });

  describe("#has", function(){
    describe("list has child entity with the specified id", function(){
      it("returns true", function(){
        var item = {id : 'foobar'};
        list.add(item);
        assert(list.has('foobar')).isTrue();
      });
    });

    describe("list does not have child entity with the specified id", function(){
      it("returns false", function(){
        assert(list.has('foobar')).isFalse();
      });
    });
  });

  describe("#add", function(){
    it("adds new li to list", function(){
      var item = {};
      list.add(item)
      assert(list.list().children('li').length).equals(1);
    });

    //describe("item index is specified", function(){
    //  it("adds new li to list before other li's with higher indices"); /// NIY
    //});

    it("sets li text to item text", function(){
      var item = {text: 'item1'}
      list.add(item)
      assert($(list.list().children('li')[0]).html()).equals('item1');
    });

    it("sets item id in li data", function(){
      var item = {id: 'item1'}
      list.add(item)
      assert($(list.list().children('li')[0]).data('id')).equals('item1');
    });

    it("sets item in li data", function(){
      var item = {data: {}}
      list.add(item)
      assert($(list.list().children('li')[0]).data('item')).equals(item['data']);
    });

    //it("sets item color in li css"); /// NIY

    //describe("list has title and we're adding first element", function(){
      //it("starts list effect") /// NIY
    //});
  });

  describe("#show", function(){
    it("shows component", function(){
      $('#locations_list ul').hide();
      list.show();
      assert($('#locations_list ul')).isVisible();
    });
  });

  describe("#hide", function(){
    it("hides component", function(){
      list.show();
      list.hide();
      assert($('#locations_list ul')).isHidden();
    });
  });

  //describe("#_repeat", function(){ /// NIY
  //  it("flashes list title");
  //  it("periodically repeats effect")
  //  describe("this._run_effects is false", function(){
  //    it("does not repeat effects");
  //  });
  //});

  //describe("#start", function(){ /// NIY
  //  it("starts repeating effect loop");
  //  describe("list has mouse focus", function(){
  //    it("does not start effect loop");
  //  });
  //});

  //describe("#stop", function(){ /// NIY
  //  it("clears title effects");
  //  it("sets _run_effects to false")
  //});
});});
