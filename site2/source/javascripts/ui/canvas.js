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

  this.missions_button.component().on('click', function(evnt){ _this.dialog.show_missions_dialog(); });
};

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

Omega.UI.Canvas.Dialog = function(){
};

Omega.UI.Canvas.Dialog.prototype = {
  show_missions_dialog : function(){
    /// TODO
  }
};

$.extend(Omega.UI.Canvas.Dialog.prototype,
         new Omega.UI.Dialog());

Omega.UI.Canvas.EntityContainer = function(){
  this.div_id = '#entity_container';
};
