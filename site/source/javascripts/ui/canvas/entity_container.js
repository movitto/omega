/* Omega JS Canvas EntityContainer UI Component
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.UI.CanvasEntityContainer = function(parameters){
  this.entity = null;
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

    /// hide entity container on 'close' click
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

    /// hide by default
    this.hide();
  },

  hide : function(){
    if(this.entity){
      /// call 'unselected' callback
      if(this.entity.unselected) this.entity.unselected(this.canvas.page);

      /// remove refresh callbacks
      this._remove_entity_callbacks();
    }

    /// clear entity
    this.entity = null;

    /// clear & hide dom
    this._clear_dom();
    $(this.div_id).hide();
  },

  _clear_dom : function(){
    $(this.contents_id).html('');
  },

  show : function(entity){
    var _this = this;

    // clears / unselects previous entity if any
    this.hide();

    /// set entity & details
    this.entity = entity;
    this._set_entity_details();

    /// invoke selected callback
    if(entity.selected) entity.selected(this.canvas.page);

    /// wire up refresh callbacks
    this._add_entity_callbacks();

    /// show dom
    $(this.div_id).show();

    /// set focus on dom
    $(this.div_id).focus();
  },

  append : function(text){
    $(this.contents_id).append(text);
  },

  _set_entity_details : function(){
    /// append entity details to container
    var _this = this;
    if(this.entity.retrieve_details)
      this.entity.retrieve_details(this.canvas.page,
        function(details){ _this.append(details); });
  },

  _init_entity_callbacks : function(){
    var _this = this;
    if(!this.entity._refresh_entity_container)
      this.entity._refresh_entity_container = function(){ _this.refresh(); };
    if(!this.entity._refresh_entity_container_details)
      this.entity._refresh_entity_container_details = function(){ _this.refresh_details(); };
  },

  _remove_entity_callbacks : function(){
    this._init_entity_callbacks();

    if(this.entity.refresh_details_on){
      for(var cb = 0; cb < this.entity.refresh_details_on.length; cb++){
        this.entity.removeEventListener(this.entity.refresh_details_on[cb],
                                        this.entity._refresh_entity_container);
      }
    }
  },

  _add_entity_callbacks : function(){
    this._init_entity_callbacks();

    if(this.entity.refresh_details_on){
      for(var cb = 0; cb < this.entity.refresh_details_on.length; cb++){
        this.entity.addEventListener(this.entity.refresh_details_on[cb],
                                     this.entity._refresh_entity_container_details);
      }
    }
  },

  refresh_details : function(){
    if(this.entity && this.entity.refresh_details)
      this.entity.refresh_details();
  },

  refresh_cmds : function(){
    if(this.entity && this.entity.refresh_cmds)
      this.entity.refresh_cmds(this.canvas.page);
  },

  refresh : function(){
    this.refresh_details();
    this.refresh_cmds();
  }
};
