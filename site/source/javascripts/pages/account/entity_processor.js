/* Omega Account Page Entity Processor Mixin
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.Pages.AccountEntityProcessor = {
  process_entities : function(entities){
    for(var e = 0; e < entities.length; e++){
      var entity = entities[e];
      this.process_entity(entity);
    }
  },

  process_entity : function(entity){
    this.details.entity(entity);
  },

  process_stat : function(stat_result){
    if(stat_result == null) return;
    var stat = stat_result.stat;
    for(var v = 0; v < stat_result.value.length; v++){
      var value = stat_result.value[v];
      if(value == this.session.user_id){
        this.details.add_badge(stat.id, stat.description, v)
        break;
      }
    }
  }
};
