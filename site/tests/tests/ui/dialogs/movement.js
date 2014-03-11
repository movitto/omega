/// Currently testing through use in CommandDialog Mixin
pavlov.specify("Omega.UI.CommandDialog", function(){
describe("Omega.UI.CommandDialog", function(){
  var dialog, page;

  before(function(){
    page   = new Omega.Pages.Test({node : new Omega.Node()});
    dialog = new Omega.UI.CommandDialog();
  });

  after(function(){
    Omega.UI.Dialog.remove();
  })

  describe("#show_destination_selection_dialog", function(){
    var ship, dests,
        dstation;

    before(function(){
      ship = new Omega.Ship({id : 'ship1',
                             location : new Omega.Location({x:10.12,y:10.889,z:-20.1})});

      dstation = new Omega.Station({id : 'st1', location : new Omega.Location({x:50,y:-52,z:61})})
      dests = {
        stations : [dstation]
      };
    });

    it("sets dialog title", function(){
      dialog.show_destination_selection_dialog(page, ship);
      assert(dialog.title).equals('Move Ship');
    });

    it("shows select destination dialog", function(){
      var show = sinon.spy(dialog, 'show');
      dialog.show_destination_selection_dialog(page, ship);
      assert(dialog.div_id).equals('#select_destination_dialog');
      sinon.assert.called(show);
    });

    it("sets dest entity id", function(){
      dialog.show_destination_selection_dialog(page, ship);
      assert($('#dest_id').html()).equals('Move ' + ship.id + ' to:');
    });

    it("hides dest and coords selection sections", function(){
      dialog.show_destination_selection_dialog(page, ship);
      assert($('#dest_selection_section')).isHidden();
      assert($('#coords_selection_section')).isHidden();
    });

    it("wires up select dest section click handler", function(){
      assert($('#select_destination')).doesNotHandle('click');
      dialog.show_destination_selection_dialog(page, ship);
      assert($('#select_destination')).handles('click');
    });

    it("wires up select coords section click handler", function(){
      assert($('#select_coordinates')).doesNotHandle('click');
      dialog.show_destination_selection_dialog(page, ship);
      assert($('#select_coordinates')).handles('click');
    })

    it("adds specified destinations to dest selection box", function(){
      assert($('#dest_selection').children().length).equals(0);
      dialog.show_destination_selection_dialog(page, ship, dests);

      var entities = $('#dest_selection').children();
      assert(entities.length).equals(2);
      assert($(entities[0]).text()).equals('');
      assert($(entities[1]).data('id')).equals(dstation.id);
      assert($(entities[1]).text()).equals('station: ' + dstation.id);
      assert($(entities[1]).data('location')).isSameAs(dstation.location);
    });

    it("wires up destination select box option change", function(){
      dialog.show_destination_selection_dialog(page, ship, dests);
      var entity = $('#dest_selection');
      assert(entity).handles('change');
    });

    describe("on destination selection", function(){
      it("invokes entity._move w/ coordinates", function(){
        var move = sinon.stub(ship, '_move');

        dialog.show_destination_selection_dialog(page, ship, dests);
        var entity = $("#dest_selection");
        entity[0].selectedIndex = 1;

        entity.trigger('change');
        var loc = $(entity.children()[1]).data('location');
        var offset = Omega.Config.movement_offset;

        sinon.assert.calledWith(move, page);
        var args = move.getCall(0).args;
        var validate = [args[1] - loc.x,
                        args[2] - loc.y,
                        args[3] - loc.z];
        validate.forEach(function(dist){
          assert(dist).isLessThan(offset.max);
          assert(dist).isGreaterThan(offset.min);
        });
      });
    })

    it("sets current x coordinate as dest x", function(){
      dialog.show_destination_selection_dialog(page, ship);
      assert($('#dest_x').val()).equals('10.12');
    });

    it("sets current y coordinate as dest y", function(){
      dialog.show_destination_selection_dialog(page, ship);
      assert($('#dest_y').val()).equals('10.89');
    });

    it("sets current z coordinate as dest z", function(){
      dialog.show_destination_selection_dialog(page, ship);
      assert($('#dest_z').val()).equals('-20.1');
    });

    it("wires up dest field enter keypress events", function(){
      assert($('#dest_x')).doesNotHandle('keypress');
      assert($('#dest_y')).doesNotHandle('keypress');
      assert($('#dest_z')).doesNotHandle('keypress');
      dialog.show_destination_selection_dialog(page, ship);
      assert($('#dest_x')).handles('keypress');
      assert($('#dest_y')).handles('keypress');
      assert($('#dest_z')).handles('keypress');
    });

    describe("on dest field enter keypress", function(){
      before(function(){
        dialog.show_destination_selection_dialog(page, ship);
      });

      it("invokes entity._move with coordinates from inputs", function(){
        $('#dest_x').val('-188.9');
        $('#dest_y').val('-2.42');
        $('#dest_z').val('1');

        var move = sinon.spy(ship, '_move');
        $('#dest_x').trigger(jQuery.Event('keypress', {which : 13}));
        sinon.assert.calledWith(move, page, '-188.9', '-2.42', '1');
      });
    });


    it("wires up move command button", function(){
      assert($('#command_move')).doesNotHandle('click');
      dialog.show_destination_selection_dialog(page, ship);
      assert($('#command_move')).handles('click');
    });

    describe("on move command button click", function(){
      before(function(){
        dialog.show_destination_selection_dialog(page, ship);
      });

      it("invokes entity._move with coordinates retrieved from inputs", function(){
        $('#dest_x').val('500.188');
        $('#dest_y').val('0.99');
        $('#dest_z').val('-42');

        var move = sinon.spy(ship, '_move');
        $('#command_move').click();
        sinon.assert.calledWith(move, page, '500.188', '0.99', '-42');
      });
    });
  });
});});
