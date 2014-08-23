pavlov.specify("Omega.UI.CanvasDialog", function(){
describe("Omega.UI.CanvasDialog", function(){
  var user_id  = 'user1';
  var node     = new Omega.Node();
  var session  = new Omega.Session({user_id: user_id});
  var page     = new Omega.Pages.Test({node: node});
  var canvas   = new Omega.UI.Canvas({page: page});

  page.session = session;

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
    {active   : [mission1],
     inactive : inactive_missions};

  before(function(){
    dialog  = new Omega.UI.CanvasDialog({canvas: canvas});
  });

  after(function(){
    Omega.UI.Dialog.remove();
  });

  it('has a reference to canvas the dialog is for', function(){
    var canvas = new Omega.UI.Canvas();
    var dialog = new Omega.UI.CanvasDialog({canvas: canvas});
    assert(dialog.canvas).equals(canvas);
  });

  describe("#show_missions_dialog", function(){
    it("hides dialog", function(){
      sinon.spy(dialog, 'hide');
      dialog.show_missions_dialog({});
      sinon.assert.called(dialog.hide);
    });

    describe("user has active mission", function(){
      it("shows assigned mission dialog", function(){
        sinon.spy(dialog, 'show_assigned_mission_dialog');
        dialog.show_missions_dialog(missions_responses['active']);
        sinon.assert.calledWith(dialog.show_assigned_mission_dialog, mission1);
      });

    describe("user does not have active mission", function(){
      it("shows mission list dialog", function(){
        sinon.spy(dialog, 'show_missions_list_dialog');
        dialog.show_missions_dialog(missions_responses['inactive']);
        sinon.assert.calledWith(dialog.show_missions_list_dialog,
                                unassigned_missions, victorious_missions, failed_missions);
      });
    });

    it("shows dialog", function(){
      sinon.spy(dialog, 'show');
      dialog.show_missions_dialog({});
      sinon.assert.called(dialog.show);
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
      Omega.Test.clear_events();
    })

    it("invokes missions.assign_to", function(){
      sinon.spy(mission, 'assign_to');
      $('.assign_mission')[0].click();
      sinon.assert.calledWith(mission.assign_to,
                              session.user_id, dialog.canvas.page.node, sinon.match.func);
    });

    it("invokes assign_mission_clicked", function(){
      sinon.spy(mission, 'assign_to');
      var element = $('.assign_mission')[0];
      $(element).data('mission', mission);
      element.click();
      assign_cb = mission.assign_to.getCall(0).args[2];

      var response = {};
      sinon.spy(dialog, '_assign_mission_clicked');
      assign_cb(response)

      sinon.assert.calledWith(dialog._assign_mission_clicked, response);
    });

    describe("missions::assign response", function(){
      describe("error on mission assignment", function(){
        it("sets error", function(){
          dialog._assign_mission_clicked({error: {message: 'user has active mission'}})
          assert($('#mission_assignment_error').html()).equals('user has active mission');
        });

        it("shows dialog", function(){
          sinon.spy(dialog, 'show');
          dialog._assign_mission_clicked({error: {}});
          sinon.assert.called(dialog.show);
        });
      });

      it("hides dialog", function(){
        sinon.spy(dialog, 'hide');
        dialog._assign_mission_clicked({});
        sinon.assert.called(dialog.hide);
      });
    });
  });
});});

