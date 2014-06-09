/* Omega JS Movement Dialog Operations
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.UI.MovementDialog = {
  show_destination_selection_dialog : function(page, entity, dests){
    /// Set title / div_id
    this.title  = 'Move Ship';
    this.div_id = '#select_destination_dialog';
    $('#dest_id').html('Move ' + entity.id + ' to:');

    /// Hide subsections
    $('#dest_selection_section').hide();
    $('#coords_selection_section').hide();

    /// Wire up select destination section toggle
    $('#select_destination, #select_dest_title').off('click');
    $('#select_destination, #select_dest_title').click(function(){
      $('#dest_selection_section').toggle();
    });

    /// Wire up select coordinates section toggle
    $('#select_coordinates, #select_coords_title').off('click');
    $('#select_coordinates, #select_coords_title').click(function(){
      $('#coords_selection_section').toggle();
    });

    /// Populate dest selection input w/ specified destinations
    var dest_selection = $('#dest_selection');
    dest_selection.html('<option/>');
    for(var entity_class in dests){
      /// XXX but works for now
      var title = entity_class.substr(0, entity_class.length-1);

      var entities = dests[entity_class];
      for(var e = 0; e < entities.length; e++){
        var dest = entities[e];
        var text = title + ': ' + dest.id;
        if(dest.json_class == 'Cosmos::Entities::JumpGate')
          text = title + ': ' + dest.endpoint_title();
        var option = $('<option/>', {text: text});
        option.data('id', dest.id);
        option.data('location', dest.location);
        dest_selection.append(option);
      }
    }
    dest_selection.off('change');
    dest_selection.change(function(evnt){ //wiring onChange to the select element
      /// generate new coords a random offset from location
      var loc = $(evnt.currentTarget).find(":selected").data('location');
      var offset = page.config.movement_offset;
          offset = (Math.random() * (offset.max - offset.min)) + offset.min;
      entity._move(page, loc.x + offset, loc.y + offset, loc.z + offset);
    });

    /// Set coordinates inputs to current coordinates
    /// TODO offset a bit so default movement doesn't result in 'already at location' error
    $('#dest_x').val(Omega.Math.round_to(entity.location.x, 2));
    $('#dest_y').val(Omega.Math.round_to(entity.location.y, 2));
    $('#dest_z').val(Omega.Math.round_to(entity.location.z, 2));

    /// Wire up enter key press on coordinate input fields
    var dest_fields = [$('#dest_x'), $('#dest_y'), $('#dest_z')];
    for(var d = 0; d < dest_fields.length; d++){
      dest_fields[d].off('keypress');
      dest_fields[d].keypress(function(evnt){
        var nx = $('#dest_x').val();
        var ny = $('#dest_y').val();
        var nz = $('#dest_z').val();
        if(evnt.which == 13) entity._move(page, nx, ny, nz);
      });
    }

    /// Wire up move button click
    $('#command_move').off('click');
    $('#command_move').click(function(evnt){
      var nx = $('#dest_x').val();
      var ny = $('#dest_y').val();
      var nz = $('#dest_z').val();
      entity._move(page, nx, ny, nz);
    });

    /// Show the dialog
    this.show();
  }
};
