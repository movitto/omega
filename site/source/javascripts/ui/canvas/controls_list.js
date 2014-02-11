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
  /// run all list effects until the first list hover event
  _run_effects : true,

  wire_up : function(){
    /// FIXME if div_id not set on init,
    /// these will be invalid (also in other components)
    /// (implement setter for div_id?)
    var _this = this;
    this.component().on('mouseenter',
      function(evnt){
        _this.stop();
        _this.show();
      });
    this.component().on('mouseleave',
      function(evnt){
        _this.hide();
      });
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

  /// for now assume the first non-ul element under container is title
  title : function(){
    return this.component().children(':not(ul)')[0];
  },

  clear : function(){
    this.children().remove();
  },

  has : function(entity_id){
    var children = this.children();
    for(var c = 0; c < children.length; c++)
      if($(children[c]).data('id') == entity_id)
        return true;
    return false;
  },

  // Add new item to list.
  // Item should specify id, text, data
  add : function(item){
    var element = $('<li/>', {text: item['text']});
    element.data('id', item['id']);
    element.data('item', item['data']);
    this.list().append(element);

    /// start effect when adding first element
    if(this.children().length == 1 && this.title()) this.start();
  },

  show : function(){
    this.list().show();
  },

  hide : function(){
    this.list().hide();
  },

  _repeat : function(){
    var _this = this;
    $(this.title()).delay(200).fadeOut('slow').
                    delay(50).fadeIn('slow',
      function(){
        if(_this._run_effects)
          _this._repeat();
      });
  },

  start : function(){
    this._repeat();
  },

  stop : function(){
    $(this.title()).stop();
    Omega.UI.CanvasControlsList.prototype._run_effects = false;
  }
};
