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

  describe("user clicks canvas", function(){
    describe("user clicked on entity in scene", function(){
      it("raises click event on entity", function(){
        var mesh1  = new THREE.Mesh(new THREE.SphereGeometry(1000, 100, 100),
                                    new THREE.MeshBasicMaterial({color: 0xABABAB}));
        var mesh2  = mesh1.clone();
        mesh1.position.set(1000, 0, 0);
        mesh2.position.set(0, 0, 0);

        mesh1.omega_entity = new Omega.Ship({id: 'sh1'});
        mesh2.omega_entity = new Omega.Ship({id: 'sh2'});

        var spy1 = sinon.spy();
        var spy2 = sinon.spy();
        mesh1.omega_entity.addEventListener('click', spy1);
        mesh2.omega_entity.addEventListener('click', spy2);

        var canvas = Omega.Test.Canvas();
        canvas.scene.add(mesh1);
        canvas.scene.add(mesh2);

        var side = canvas.canvas.offset().left - canvas.canvas.width();
        canvas.canvas.css({right: $(document).width() - side});
        canvas.canvas.show();
        canvas.canvas.animate();

        var evnt = new jQuery.Event("click");
        evnt.pageX = canvas.canvas.width()/2;
        evnt.pageY = canvas.canvas.height()/2;
        canvas.canvas.trigger(evnt);
        sinon.assert.calledWith(spy2, {type: 'click'})
        sinon.assert.notCalled(spy1);
      });
    });
  });

  describe("canvas after #setup", function(){
    it("has a scene", function(){
      var canvas = Omega.Test.Canvas();
      assert(canvas.scene).isOfType(THREE.Scene);
    });

    it("has a renderer", function(){
      var canvas = Omega.Test.Canvas();
      assert(canvas.renderer).isOfType(THREE.WebGLRenderer);
      assert(canvas.renderTarget).isOfType(THREE.WebGLRenderTarget);
    });

    it("has two effects composers", function(){
      var canvas = Omega.Test.Canvas();
      assert(canvas.composer).isOfType(THREE.EffectComposer);
      assert(canvas.shader_composer).isOfType(THREE.EffectComposer);
    })

    it("has a perspective camera", function(){
      var canvas = Omega.Test.Canvas();
      assert(canvas.cam).isOfType(THREE.PerspectiveCamera);
    });

    it("has orbit controls", function(){
      var canvas = Omega.Test.Canvas();
      assert(canvas.cam_controls).isOfType(THREE.OrbitControls);
    });

    it("adds render pass to shader composer", function(){
      var canvas = Omega.Test.Canvas();
      assert(canvas.shader_composer.passes.length).equals(1);
      assert(canvas.shader_composer.passes[0]).isOfType(THREE.RenderPass);
    })

    it("adds a render/bloom/shader passes to composer", function(){
      var canvas = Omega.Test.Canvas();
      assert(canvas.composer.passes.length).equals(3);
      assert(canvas.composer.passes[0]).isOfType(THREE.RenderPass);
      assert(canvas.composer.passes[1]).isOfType(THREE.BloomPass);
      assert(canvas.composer.passes[2]).isOfType(THREE.ShaderPass);
      //assert(canvas.composer.passes[2]); // TODO verify ShaderPass pulls in ShaderComposer via AdditiveBlending
      assert(canvas.composer.passes[2].renderToScreen).isTrue();
    });
  });
});});

pavlov.specify("Omega.UI.Canvas.Controls", function(){
describe("Omega.UI.Canvas.Controls", function(){
  var node, page, canvas, controls;
  
  before(function(){
    node = new Omega.Node();
    page = new Omega.Pages.Test({node: node});
    canvas = new Omega.UI.Canvas({page: page});
    controls = new Omega.UI.Canvas.Controls({canvas: canvas});
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
    assert(controls.canvas).equals(canvas);
  });

  describe("missions button click", function(){
    after(function(){
      if(Omega.Mission.all.restore) Omega.Mission.all.restore();
    });

    it("retrieves all missions", function(){
      var spy = sinon.spy(Omega.Mission, 'all');
      controls.missions_button.component().click();
      sinon.assert.calledWith(spy, node, sinon.match.func)
    });

    it("shows missions dialog", function(){
      var spy1 = sinon.spy(Omega.Mission, 'all');
      var spy2 = sinon.spy(canvas.dialog, 'show_missions_dialog');
      controls.missions_button.component().click();

      var response = {};
      spy1.getCall(0).args[1](response)
      sinon.assert.calledWith(spy2, response);
    });
  })
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

  describe("#add", function(){
    it("adds new li to list", function(){
      var item = {};
      list.add(item)
      assert(list.list().children('li').length).equals(1);
    });

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
  });
});});

pavlov.specify("Omega.UI.Canvas.Controls.Button", function(){
describe("Omega.UI.Canvas.Controls.Button", function(){
});});

pavlov.specify("Omega.UI.Canvas.Controls.Dialog", function(){
describe("Omega.UI.Canvas.Controls.Dialog", function(){
  var user_id  = 'user1';
  var node     = new Omega.Node();
  var session  = new Omega.Session({user_id: user_id});
  var page     = new Omega.Pages.Test({node: node, session: session});
  var canvas   = new Omega.UI.Canvas({page: page});

  // TODO factory pattern
  var mission1 = new Omega.Mission({title: 'mission1',
                       description: 'mission description1',
                       assigned_to_id : user_id,
                       assigned_time  : new Date().toString() });

  var mission2 = new Omega.Mission({id:    'missionb',
                                    title: 'mission2'});
  var mission3 = new Omega.Mission({id:    'missionc',
                                    title: 'mission3',
                                    assigned_to_id : user_id,
                                    victorious : true});
  var mission4 = new Omega.Mission({id:    'missiond',
                                    title: 'mission4',
                                    assigned_to_id : 'another',
                                    victorious : true});
  var mission5 = new Omega.Mission({id:    'missione',
                                    title: 'mission5',
                                    assigned_to_id : user_id,
                                    failed : true});
  var mission6 = new Omega.Mission({id:    'missionf',
                                    title: 'mission6',
                                    assigned_to_id : user_id,
                                    failed : true});
  var mission7 = new Omega.Mission({id:    'missiong',
                                    title: 'mission7'});

  var inactive_missions   = [mission2, mission3, mission4, mission5, mission6, mission7];
  var unassigned_missions = [mission2, mission7];
  var victorious_missions = [mission3];
  var failed_missions     = [mission5, mission6];
  var missions_responses  =
    {active   : {result: [mission1]},
     inactive : {result:  inactive_missions}};

  before(function(){
    dialog  = new Omega.UI.Canvas.Dialog({canvas: canvas});
  });

  after(function(){
    Omega.UI.Dialog.remove();
  });

  it('has a reference to canvas the dialog is for', function(){
    var canvas = new Omega.UI.Canvas();
    var dialog = new Omega.UI.Canvas.Dialog({canvas: canvas});
    assert(dialog.canvas).equals(canvas);
  });

  describe("#show_missions_dialog", function(){
    it("hides dialog", function(){
      var spy = sinon.spy(dialog, 'hide');
      dialog.show_missions_dialog({});
      sinon.assert.called(spy);
    });

    describe("user has active mission", function(){
      it("shows assigned mission dialog", function(){
        var spy = sinon.spy(dialog, 'show_assigned_mission_dialog');
        dialog.show_missions_dialog(missions_responses['active']);
        sinon.assert.calledWith(spy, mission1);
      });

    describe("user does not have active mission", function(){
      it("shows mission list dialog", function(){
        var spy = sinon.spy(dialog, 'show_missions_list_dialog');
        dialog.show_missions_dialog(missions_responses['inactive']);
        sinon.assert.calledWith(spy, unassigned_missions, victorious_missions, failed_missions);
      });
    });

    it("shows dialog", function(){
      var spy = sinon.spy(dialog, 'show');
      dialog.show_missions_dialog({});
      sinon.assert.called(spy);
    });
  });

  describe("#show_assigned_mission_dialog", function(){
      it("shows mission metadata", function(){
        dialog.show_assigned_mission_dialog(mission1);
        assert(dialog.title).equals('Assigned Mission');
        assert(dialog.div_id).equals('#assigned_mission_dialog');
        assert($('#assigned_mission_title').html()).equals('<b>mission1</b>');
        assert($('#assigned_mission_description').html()).equals('mission description1');
        assert($('#assigned_mission_assigned_time').html()).equals('<b>Assigned</b>: ' + mission1.assigned_time);
        assert($('#assigned_mission_expires').html()).equals('<b>Expires</b>: ' + mission1.expires());
      });
    });
  });

  describe("#show_missions_list_dialog", function(){
    it("shows list of unassigned missions with assignment links", function(){
      dialog.show_missions_list_dialog(unassigned_missions, victorious_missions, failed_missions);
      assert(dialog.title).equals('Missions');
      assert(dialog.div_id).equals('#missions_dialog');
      assert($('#missions_list').html()).equals('mission2<span class="assign_mission">assign</span><br>mission7<span class="assign_mission">assign</span><br>'); // XXX unassigned_missions
    });
    
    it("associates mission with assign command event data", function(){
      dialog.show_missions_list_dialog(unassigned_missions, victorious_missions, failed_missions);
      var assign_cmds = $('.assign_mission');
      assert($(assign_cmds[0]).data('mission')).equals(mission2)
      assert($(assign_cmds[1]).data('mission')).equals(mission7)
    })

    it("should # of successful/failed user missions", function(){
      dialog.show_missions_list_dialog(unassigned_missions, victorious_missions, failed_missions);
      assert($('#completed_missions').html()).equals('(Victorious: 1 / Failed: 2)');
    });
  });

  describe("mission assignment command", function(){
    var mission;

    before(function(){
      dialog.show_missions_list_dialog(unassigned_missions, [], []);
      mission = unassigned_missions[0];
    });

    after(function(){
      if(mission.assign_to.restore) mission.assign_to.restore();
    })

    it("invokes missions.assign_to", function(){
      var spy = sinon.spy(mission, 'assign_to');
      $('.assign_mission')[0].click();
      sinon.assert.calledWith(spy, session.user_id, dialog.canvas.page.node, sinon.match.func);
    });

    it("invokes assign_mission_clicked", function(){
      var spy = sinon.spy(mission, 'assign_to');
      var element = $('.assign_mission')[0];
      $(element).data('mission', mission);
      element.click();
      assign_cb = spy.getCall(0).args[2];

      var response = {};
      spy = sinon.spy(dialog, '_assign_mission_clicked');
      assign_cb(response)

      sinon.assert.calledWith(spy, response);
    });

    describe("missions::assign response", function(){
      describe("error on mission assignment", function(){
        it("sets error", function(){
          dialog._assign_mission_clicked({error: {message: 'user has active mission'}})
          assert($('#mission_assignment_error').html()).equals('user has active mission');
        });

        it("shows dialog", function(){
          var spy = sinon.spy(dialog, 'show');
          dialog._assign_mission_clicked({error: {}});
          sinon.assert.called(spy);
        });
      });

      it("hides dialog", function(){
        var spy = sinon.spy(dialog, 'hide');
        dialog._assign_mission_clicked({});
        sinon.assert.called(spy);
      });
    });
  });
});});

pavlov.specify("Omega.UI.Canvas.EntityContainer", function(){
describe("Omega.UI.Canvas.EntityContainer", function(){
});});
