/* Omega JS Attack Dialog Operations
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.UI.AttackDialog = {
  show_attack_dialog : function(page, entity, targets){
    this.title  = 'Launch Attack';
    this.div_id = '#select_attack_target_dialog';
    $("#attack_id").html('Select ' + entity.id + ' target');

    var attack_cmds = [];
    for(var t = 0; t < targets.length; t++){
      var target = targets[t];
      var cmd = $("<span/>",
        {id    : 'attack_' + target.id,
         class : 'cmd_attack dialog_cmd',
         text  : target.id });
      cmd.data("entity", entity);
      cmd.data("target", target);
      cmd.click(function(evnt){
        entity._start_attacking(page, evnt);
        evnt.stopPropagation();
      })

      attack_cmds.push(cmd);
    }

    $('#attack_targets').html('');
    $('#attack_targets').append(attack_cmds);
    this.show();
  }
};
