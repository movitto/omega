/* Omega JS Canvas UI Component
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.UI.Canvas = function(parameters){
  this.controls         = new Omega.UI.Canvas.Controls({canvas: this});
  this.dialog           = new Omega.UI.Canvas.Dialog({canvas: this});
  this.entity_container = new Omega.UI.Canvas.EntityContainer();
  this.canvas           = $('#omega_canvas');

  /// need handle to page canvas is on to
  /// - lookup missions
  this.page = null

  $.extend(this, parameters);
};

Omega.UI.Canvas.Controls = function(parameters){
  this.locations_list   = new Omega.UI.Canvas.Controls.List({  div_id : '#locations_list' });
  this.entities_list    = new Omega.UI.Canvas.Controls.List({  div_id : '#entities_list'  });
  this.missions_button  = new Omega.UI.Canvas.Controls.Button({div_id : '#missions_button'});
  this.cam_reset_button = new Omega.UI.Canvas.Controls.Button({div_id : '#cam_reset'      });

  /// need handle to canvas to
  /// - set scene
  /// - set camera target
  /// - reset camera
  this.canvas = null;

  $.extend(this, parameters);

  // TODO sort locations list

  var _this = this;
  this.missions_button.component().on('click', function(evnt){ _this._missions_button_click(); });
  // TODO locations / entities list clicks
};

Omega.UI.Canvas.Controls.prototype = {
  _missions_button_click : function(){
    var _this = this;
    var node  = this.canvas.page.node;
    Omega.Mission.all(node, function(result){ _this.canvas.dialog.show_missions_dialog(result); });
  }
}

Omega.UI.Canvas.Controls.List = function(parameters){
  this.div_id = null;
  $.extend(this, parameters)

/// FIXME if div_id not set on init, these will be invalid (also in other components)
/// (implement setter for div_id?)
  var _this = this;
  this.component().on('mouseenter', function(evnt){ _this.show(); });
  this.component().on('mouseleave', function(evnt){ _this.hide(); });
};

Omega.UI.Canvas.Controls.List.prototype = {
  component : function(){
    return $(this.div_id);
  },

  list : function(){
    return $(this.component().children('ul')[0]);
  },

  // Add new item to list.
  // Item should specify id, text, data
  add : function(item){
    var element = $('<li/>', {text: item['text']});
    element.data('id', item['id']);
    element.data('item', item['data']);
    this.list().append(element);
  },

  show : function(){
    this.list().show();
  },

  hide : function(){
    this.list().hide();
  }
};

Omega.UI.Canvas.Controls.Button = function(parameters){
  this.div_id = null;
  $.extend(this, parameters);
};

Omega.UI.Canvas.Controls.Button.prototype = {
  component : function(){
    return $(this.div_id);
  }
};

Omega.UI.Canvas.Dialog = function(parameters){
  /// need handle to canvas to
  /// - lookup missions
  this.canvas = null;

  $.extend(this, parameters);

  this.assign_mission = $('.assign_mission');
};

Omega.UI.Canvas.Dialog.prototype = {
  _assign_button_click : function(evnt){
    var _this = this;
    var node  = this.canvas.page.node;
    var user  = this.canvas.page.session.user_id;

    var mission = $(evnt.currentTarget).data('mission');
    mission.assign_to(user, node, function(res){ _this._assign_mission_clicked(res); })
  },

  show_missions_dialog : function(response){
    var missions   = [];
    var unassigned = [];
    var victorious = [];
    var failed     = [];
    var current    = null;

    if(response.result){
      var current_user = this.canvas.page.session.user_id;
      missions   = response.result;
      unassigned = $.grep(missions, function(m) { return m.unassigned(); });
      assigned   = $.grep(missions, function(m) {
                                     return m.assigned_to(current_user); });
      victorious = $.grep(assigned, function(m) {   return m.victorious; });
      failed     = $.grep(assigned, function(m) {       return m.failed; });
      current    = $.grep(assigned, function(m) {
                                     return !m.victorious && !m.failed; })[0];
    }

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
    this.title  = 'Missions';
    this.div_id = '#missions_dialog';

    $('#missions_list').html('');
    for(var m = 0; m < unassigned.length; m++){
      var mission      = unassigned[m];
      var assign_link = $('<span/>', 
        {'class': 'assign_mission', 
          text:   'assign' });
      assign_link.data('mission', mission);
      $('#missions_list').append(mission.title);
      $('#missions_list').append(assign_link);
      $('#missions_list').append('<br/>');
    }

    var completed_text = '(Victorious: ' + victorious.length +
                         ' / Failed: ' + failed.length +')';
    $('#completed_missions').html(completed_text);

    /// wire up assign_mission click events
    /// XXX rather move this init elsewhere so 'off' isn't needed
    var _this = this;
    this.component().off('click', '.assign_mission');
    this.component().on( 'click', '.assign_mission', function(evnt) { _this._assign_button_click(evnt); });
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

$.extend(Omega.UI.Canvas.Dialog.prototype,
         new Omega.UI.Dialog());

Omega.UI.Canvas.EntityContainer = function(){
  this.div_id = '#entity_container';
};
