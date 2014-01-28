/* Omega JS Canvas EntityContainer UI Component
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

/// TODO follow selected entity w/ camera?

Omega.UI.CanvasEntityContainer = function(parameters){
  this.entity = null;

  /// need handle to canvas to
  /// - access page to lookup entity data
  /// - refresh entities in scene
  this.canvas = null;

  $.extend(this, parameters);
};

Omega.UI.CanvasEntityContainer.prototype = {
  div_id      : '#omega_entity_container',
  close_id    : '#entity_container_close',
  contents_id : '#entity_container_contents',

  component : function(){
    return $(this.div_id);
  },

  wire_up : function(){
    var _this = this;
    $(this.close_id).off('click');
    $(this.close_id).on('click',
      function(evnt){
        _this.hide();
      });

    /// handle esc key, hide the entity container
    $(this.div_id).off('keydown');
    $(this.div_id).keydown(function(evnt){
       if(evnt.keyCode == 27)
         _this.hide();
    });

    this.hide();
  },

  hide : function(){
    if(this.entity && this.entity.unselected)
      this.entity.unselected(this.canvas.page);

    this.entity = null;
    $(this.contents_id).html('');
    $(this.div_id).hide();
  },

  show : function(entity, refreshing){
    this.hide(); // clears / unselects previous entity if any
    this.entity = entity;

    var _this = this;
    if(entity.retrieve_details)
      entity.retrieve_details(this.canvas.page, function(details){
        _this.append(details);
      });

    if(entity.selected) entity.selected(this.canvas.page);
    $(this.div_id).show();

    if(!refreshing)
      $(this.div_id).focus();
  },

  append : function(text){
    $(this.contents_id).append(text);
  },

  refresh : function(){
    if(this.entity){
      /// reshow entity
      this.show(this.entity, true);
    }
  }
};
