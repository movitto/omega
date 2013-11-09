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
};

