/* Omega JS Canvas Dialog UI Component
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/dialog"

Omega.UI.CanvasDialog = function(parameters){
  /// need handle to canvas to
  /// - lookup missions
  this.canvas = null;

  $.extend(this, parameters);

  this.assign_mission = $('.assign_mission');
};

Omega.UI.CanvasDialog.prototype = {
  _assign_button_click : function(evnt){
    var _this = this;
    var node  = this.canvas.page.node;
    var user  = this.canvas.page.session.user_id;

    var mission = $(evnt.currentTarget).data('mission');
    mission.assign_to(user, node, function(res){ _this._assign_mission_clicked(res); })
  },

  show_missions_dialog : function(missions){
    var unassigned = [];
    var victorious = [];
    var failed     = [];
    var current    = null;

    var current_user =
      this.canvas.page.session ? this.canvas.page.session.user_id : null;
    unassigned = $.grep(missions, function(m) { return m.unassigned(); });
    assigned   = $.grep(missions, function(m) {
                                     return m.assigned_to(current_user); });
    victorious = $.grep(assigned, function(m) {   return m.victorious; });
    failed     = $.grep(assigned, function(m) {       return m.failed; });
    current    = $.grep(assigned, function(m) {
                                   return !m.victorious && !m.failed; })[0];

    this.hide();
    if(current) this.show_assigned_mission_dialog(current);
    else this.show_missions_list_dialog(unassigned, victorious, failed);
    this.show();
  },

  show_assigned_mission_dialog : function(mission){
    this.title  = 'Assigned Mission';
    this.div_id = '#assigned_mission_dialog';
    $('#assigned_mission_title').html('<b>'+mission.title+'</b>');
    $('#assigned_mission_description').html(mission.description);
    $('#assigned_mission_assigned_time').html('<b>Assigned</b>: '+ mission.assigned_time);
    $('#assigned_mission_expires').html('<b>Expires</b>: '+ mission.expires());
    // TODO cancel mission button?
  },

  show_missions_list_dialog : function(unassigned, victorious, failed){
    var _this = this;
    this.title  = 'Missions';
    this.div_id = '#missions_dialog';

    $('#missions_list').html('');
    for(var m = 0; m < unassigned.length; m++){
      var mission      = unassigned[m];
      var assign_link = $('<span/>', 
        {'class': 'assign_mission', 
          text:   'assign' });
      assign_link.data('mission', mission);
      assign_link.click(function(evnt){
        _this._assign_button_click(evnt);
        evnt.stopPropagation();
      });
      $('#missions_list').append(mission.title);
      $('#missions_list').append(assign_link);
      $('#missions_list').append('<br/>');
    }

    var completed_text = '(Victorious: ' + victorious.length +
                         ' / Failed: ' + failed.length +')';
    $('#completed_missions').html(completed_text);
  },

  _assign_mission_clicked : function(response){
    this.hide();
    if(response.error){
      this.title = 'Could not assign mission';
      this.div_id = '#mission_assignment_failed_dialog';
      $('#mission_assignment_error').html(response.error.message);
      this.show();
    }
  }
};

$.extend(Omega.UI.CanvasDialog.prototype,
         new Omega.UI.Dialog());
