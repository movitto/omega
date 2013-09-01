/* Omega Javascript Mission
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

/* Omega Mission
 */
function Mission(args){
  $.extend(this, new Entity(args));

  this.json_class = 'Missions::Mission'

  this.assign_cmd = '<span id="'+this.id+'" class="assign_mission">assign</span>';

  /* Return time which this mission expires
   */
  this.expires = function(){
    // XXX create parsable date
    var d = new Date(Date.parse(this.assigned_time.replace(/-/g, '/').slice(0, 19)));
    d.setSeconds(d.getSeconds() + this.timeout);
    return d;
  }

  /* Return boolean indicating if this mission is expired
   */
  this.expired = function(){
    return (this.assigned_time != null) && (this.expires() < new Date());
  }

  /* Return boolean indicating if mission is assigned to the specified user
   */
  this.assigned_to_user = function(user_id){
    return this.assigned_to_id == user_id;
  }

  /* Return boolean indicating if mission is assigned to the current user
   */
  this.assigned_to_current_user = function(){
    return Session.current_session != null &&
           this.assigned_to_user(Session.current_session.user_id);
  }
}

/* Return all missions
 */
Mission.all = function(cb){
  Entities().node().web_request('missions::get_missions',
                                function(res){
    var missions = [];
    if(res.result)
      for(var m in res.result)
        missions.push(new Mission(res.result[m]));
    cb.apply(null, [missions]);
  });
}
