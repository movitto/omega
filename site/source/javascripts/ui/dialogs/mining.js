/* Omega JS Mining Dialog Operations
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.UI.MiningDialog = {
  show_mining_dialog : function(page, entity){
    this.title  = 'Start Mining';
    this.div_id = '#select_mining_target_dialog';
    $('#mining_id').html('Select resource to mine with ' + entity.id);
    this.show();
  },

  append_mining_cmd : function(page, entity, resource, asteroid){
    var cmd = $("<span/>",
      {id    : "mine_" + resource.id,
       class : 'cmd_mine dialog_cmd',
       text  : resource.material_id + ' (' + resource.quantity + ')'});
    cmd.data("entity", entity);
    cmd.data("resource", resource);
    cmd.data("asteroid", asteroid);
    cmd.click(function(evnt){ entity._start_mining(page, evnt); });

    $('#mining_targets').append(cmd);
  }
};
