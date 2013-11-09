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
});});

pavlov.specify("Omega.UI.Canvas.Controls.Dialog", function(){
describe("Omega.UI.Canvas.Controls.Dialog", function(){
  after(function(){
    Omega.UI.Dialog.remove();
  });

  it('has a reference to canvas the dialog is for', function(){
    var canvas = new Omega.UI.Canvas();
    var dialog = new Omega.UI.Canvas.Dialog({canvas: canvas});
    assert(dialog.canvas).equals(canvas);
  });

  describe("#show_missions_dialog", function(){
    var node, user_id, session, page, canvas, dialog;

    before(function(){
      user_id = 'user1';
      node    = new Omega.Node();
      session = new Omega.Session({user_id: user_id});
      page    = new Omega.Pages.Test({node: node, session: session});
      canvas  = new Omega.UI.Canvas({page: page});
      dialog  = new Omega.UI.Canvas.Dialog({canvas: canvas});

    });

    var get_missions_cb = function(){
      var spy = sinon.spy(node, 'http_invoke');
      dialog.show_missions_dialog();
      var missions_cb = spy.getCall(0).args[1];
      return missions_cb;
    }

    it("invokes missions::get_missions", function(){
      var spy = sinon.spy(node, 'http_invoke');
      dialog.show_missions_dialog();
      sinon.assert.calledWith(spy, 'missions::get_missions', sinon.match.func);
    });

    it("hides dialog", function(){
      var spy = sinon.spy(dialog, 'hide');
      get_missions_cb()({})
      sinon.assert.called(spy);
    })

    describe("user has assigned mission currently in progress", function(){
      it("shows mission metadata", function(){

        var mission =
          new Omega.Mission({title: 'mission1',
                             description: 'mission description1',
                             assigned_to_id : user_id,
                             assigned_time  : new Date().toString() });
        var response = {result: [mission]}

        get_missions_cb()(response)
        assert(dialog.title).equals('Assigned Mission');
        assert(dialog.div_id).equals('#assigned_mission_dialog');
        assert($('#assigned_mission_title').html()).equals('<b>mission1</b>');
        assert($('#assigned_mission_description').html()).equals('mission description1');
        assert($('#assigned_mission_assigned_time').html()).equals('<b>Assigned</b>: ' + mission.assigned_time);
        assert($('#assigned_mission_expires').html()).equals('<b>Expires</b>: ' + mission.expires());
      })
    })

    describe("user does not have assigned mission in process", function(){
      var response;

      before(function(){
        var mission1, mission2, mission3,
            mission4, mission5, mission6;
        mission1 = new Omega.Mission({id:    'missiona',
                                      title: 'mission1'});
        mission2 = new Omega.Mission({id:    'missionb',
                                      title: 'mission2'});
        mission3 = new Omega.Mission({id:    'missionc',
                                      title: 'mission3',
                                      assigned_to_id : user_id,
                                      victorious : true});
        mission4 = new Omega.Mission({id:    'missiond',
                                      title: 'mission4',
                                      assigned_to_id : 'another',
                                      victorious : true});
        mission5 = new Omega.Mission({id:    'missione',
                                      title: 'mission5',
                                      assigned_to_id : user_id,
                                      failed : true});
        mission6 = new Omega.Mission({id:    'missionf',
                                      title: 'mission6',
                                      assigned_to_id : user_id,
                                      failed : true});

        response = {result: [mission1, mission2, mission3, mission4, mission5, mission6]};
      })

      it("shows list of unassigned missions with assignment links", function(){
        get_missions_cb()(response)
        assert(dialog.title).equals('Missions');
        assert(dialog.div_id).equals('#missions_dialog');
        assert($('#missions_list').html()).equals('mission1 <span id="assign_mission_missiona" class="assign_mission">assign</span><br>mission2 <span id="assign_mission_missionb" class="assign_mission">assign</span><br>');
      })

      it("should # of successful/failed user missions", function(){
        get_missions_cb()(response)
        assert($('#completed_missions').html()).equals('(Victorious: 1 / Failed: 2)');
      })

      describe("assign mission command", function(){
        describe("error on mission assignment", function(){
          //it("shows error in dialog") // NIY
        })

        describe("successful mission assignment", function(){
          //it("hides dialog") // NIY
        })
      })
    })

    it("shows dialog", function(){
      var spy = sinon.spy(dialog, 'hide');
      get_missions_cb()({})
      sinon.assert.called(spy);
    })
  });
});});

pavlov.specify("Omega.UI.Canvas.EntityContainer", function(){
describe("Omega.UI.Canvas.EntityContainer", function(){
});});
