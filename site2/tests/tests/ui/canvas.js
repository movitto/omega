pavlov.specify("Omega.UI.Canvas", function(){
describe("Omega.UI.Canvas", function(){
  var canvas;

  before(function(){
    canvas = new Omega.UI.Canvas();
  })

  it('has a canvas controls instance', function(){
    assert(canvas.controls).isOfType(Omega.UI.Canvas.Controls);
  });

  it('has a canvas dialog instance', function(){
    assert(canvas.dialog).isOfType(Omega.UI.Canvas.Dialog);
  });

  it('has a entity container instance', function(){
    assert(canvas.entity_container).isOfType(Omega.UI.Canvas.EntityContainer);
  });

  it('has a reference to page the canvas is on', function(){
    var page   = new Omega.Pages.Test();
    var canvas = new Omega.UI.Canvas({page: page});
    assert(canvas.page).equals(page);
  });
});});

pavlov.specify("Omega.UI.Canvas.Controls", function(){
describe("Omega.UI.Canvas.Controls", function(){
  var controls;
  
  before(function(){
    controls = new Omega.UI.Canvas.Controls();
  })

  it('has a locations list', function(){
    assert(controls.locations_list).isOfType(Omega.UI.Canvas.Controls.List);
    assert(controls.locations_list.div_id).equals('#locations_list');
  });

  it('has an entities list', function(){
    assert(controls.entities_list).isOfType(Omega.UI.Canvas.Controls.List);
    assert(controls.entities_list.div_id).equals('#entities_list');
  });

  it('has a missions button', function(){
    assert(controls.missions_button).isOfType(Omega.UI.Canvas.Controls.Button);
    assert(controls.missions_button.div_id).equals('#missions_button');
  });

  it('has a cam reset button', function(){
    assert(controls.cam_reset_button).isOfType(Omega.UI.Canvas.Controls.Button);
    assert(controls.cam_reset_button.div_id).equals('#cam_reset');
  });

  it('has a reference to canvas the controls control', function(){
    var canvas = new Omega.UI.Canvas();
    var controls = new Omega.UI.Canvas.Controls({canvas: canvas});
    assert(controls.canvas).equals(canvas);
  });
});});

pavlov.specify("Omega.UI.Canvas.Controls.List", function(){
describe("Omega.UI.Canvas.Controls.List", function(){
  var list;

  before(function(){
    list = new Omega.UI.Canvas.Controls.List({div_id: '#locations_list'});
  })

  describe("mouse enter event", function(){
    it("shows child ul", function(){
      list.component().mouseenter();
      assert(list.list()).isVisible();
    });
  });

  describe("mouse leave event", function(){
    it("hides child ul", function(){
      list.component().mouseenter();
      list.component().mouseleave();
      assert(list.list()).isHidden();
    });
  });
});});

pavlov.specify("Omega.UI.Canvas.Controls.Button", function(){
describe("Omega.UI.Canvas.Controls.Button", function(){
  describe("#show_missions_dialog", function(){
  });
});});

pavlov.specify("Omega.UI.Canvas.EntityContainer", function(){
describe("Omega.UI.Canvas.EntityContainer", function(){
});});
