/* Omega JS Construction Dialog Operations
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

/// TODO also allow user to specify coordinates
/// which to generate new entity (provided within construction distance)
/// + support other args

Omega.UI.ConstructionDialog = {

  show_construction_dialog : function(page, entity){
    var _this = this;

    this.title  = 'Construct Entity';
    this.div_id = '#set_construction_params_dialog';
    $('#construction_id').html('Construct entity with station ' + entity.id);

    $('#construction_entity_id').val(RJR.guid());

    $('#construction_entity_class').off('change');
    $('#construction_entity_class').change(function(evnt){
      var type_select = $('#construction_entity_type');
          type_select.empty();

      var types = [];
      var cls = $(evnt.currentTarget).find(":selected").val();
      if(cls == 'Ship')
        types = Object.keys(Omega.Config.resources.ships);
      else
        types = Object.keys(Omega.Config.resources.stations);

      for(var t = 0; t< types.length; t++){
        var child = $('<option value="'+types[t]+'">'+types[t]+'</option>');
        type_select.append(child);
      }
    });
    $('#construction_entity_class').trigger('change');

    $('#command_construct').off('click');
    $('#command_construct').click(function(evnt){
      var id   = $('#construction_entity_id').val();
      var cls  = $('#construction_entity_class').val();
      var type = $('#construction_entity_type').val();
      var args = ['entity_type', cls, 'type', type, 'id', id];

      entity._construct(page, args);
      _this.hide();
    });

    this.show();
  }
};
