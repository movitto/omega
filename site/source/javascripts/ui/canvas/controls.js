/* Omega JS Canvas Controls UI Component
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/canvas/controls_list"

Omega.UI.CanvasControls = function(parameters){
  this.locations_list   = new Omega.UI.CanvasControlsList({  div_id : '#locations_list' });
  this.entities_list    = new Omega.UI.CanvasControlsList({  div_id : '#entities_list'  });
  this.controls         = $('#canvas_controls');
  this.missions_button  = $('#missions_button');
  this.cam_reset        = $('#cam_reset');
  this.toggle_axis      = $('#toggle_axis input')

  /// need handle to canvas to
  /// - set scene
  /// - set camera target
  /// - reset camera
  /// - add/remove axis from canvas
  this.canvas = null;

  $.extend(this, parameters);

  /// TODO sort locations list
};

Omega.UI.CanvasControls.prototype = {
  wire_up : function(){
    var _this = this;

    this.locations_list.component().on('click', 'li',
      function(evnt){
        var item = $(evnt.currentTarget).data('item');
        _this.canvas.set_scene_root(item);
      })

    this.entities_list.component().on('click', 'li',
      function(evnt){
        var item = $(evnt.currentTarget).data('item');
        _this.canvas.set_scene_root(item.solar_system);
        _this.canvas.cam.position.set(item.location.x + 500,
                                      item.location.y + 500,
                                      item.location.z + 500);
        _this.canvas.focus_on(item.location);
        _this.canvas._clicked_entity(item);
      })

    this.missions_button.on('click',
      function(evnt){
        _this._missions_button_click();
      });

    this.cam_reset.on('click',
      function(evnt){
        _this.canvas.reset_cam();
      });

    this.toggle_axis.on('click',
      function(evnt){
        if($(evnt.currentTarget).is(':checked'))
          _this.canvas.add(_this.canvas.axis);
        else
          _this.canvas.remove(_this.canvas.axis);
        _this.canvas.animate();
      });
    this.toggle_axis.attr('checked', false);

    this.locations_list.wire_up();
    this.entities_list.wire_up();
  },

  _missions_button_click : function(){
    var _this = this;
    var node  = this.canvas.page.node;
    Omega.Mission.all(node, function(missions){ _this.canvas.dialog.show_missions_dialog(missions); });
  }
}
