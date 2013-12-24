/* Omega JS Canvas Controls List UI Component
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.UI.CanvasControlsList = function(parameters){
  this.div_id = null;
  $.extend(this, parameters)
};

Omega.UI.CanvasControlsList.prototype = {
  wire_up : function(){
    /// FIXME if div_id not set on init,
    /// these will be invalid (also in other components)
    /// (implement setter for div_id?)
    var _this = this;
    this.component().on('mouseenter', function(evnt){ _this.show(); });
    this.component().on('mouseleave', function(evnt){ _this.hide(); });
  },

  component : function(){
    return $(this.div_id);
  },

  list : function(){
    return $(this.component().children('ul')[0]);
  },

  children : function(){
    return this.list().children('li');
  },

  clear : function(){
    this.children().remove();
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
