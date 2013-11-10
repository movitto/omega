/* Omega Mission JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.Mission = function(parameters){
  $.extend(this, parameters);
};

Omega.Mission.prototype = {
  json_class : 'Missions::Mission',

  /// return time which this mission expires
  expires : function(){
    var d = new Date(Date.parse(this.assigned_time.replace(/-/g, '/').slice(0, 19)));
    d.setSeconds(d.getSeconds() + this.timeout);
    return d;
  },

  /// return bool indicating if this mission expired
  expired : function(){
    return (this.assigned_time != null) && (this.expires() < new Date());
  },

  /// return bool indicating if this mission is unassigned
  unassigned : function(){
    return !this.assigned_to_id && !this.expired();
  },

  /// return bool indicating if mission is assigned to the specified user
  assigned_to : function(user_id){
    return this.assigned_to_id == user_id;
  },

  /// assign mission to specified user
  assign_to : function(user_id, node, cb){
    node.http_invoke('missions::assign_mission', this.id, user_id, cb);
  }
};

/// Use node to retrieve all missions
Omega.Mission.all = function(node, cb){
  node.http_invoke('missions::get_missions', function(response){
    if(response.result){
      for(var m = 0; m < response.result.length; m++)
        response.result[m] = new Omega.Mission(response.result[m]);
      if(cb) cb(response.result);
    }
    // TODO handle get_missions failure
  });
};
