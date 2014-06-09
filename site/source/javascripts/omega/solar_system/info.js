/* Omega Solar System Info
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.SolarSystemInfo = {
  has_details : true,

  _title_details : function(){
    var title_text = 'System: ' + this.id;
    var title = $('<div/>', {id : 'system_title', text : title_text});
    return title;
  },

  _loc_details : function(){
    var loc_text = '@ ' + this.location.to_s();
    var loc = $('<div/>', {id : 'system_loc', text : loc_text});
    return loc;
  },

  _children_details_wrapper : function(){
    var children = $('<div/>', {id : 'system_children'});
    children.append(this._children_details());
    return children;
  },

  _children_details : function(){
    var style = 'overflow: hidden; text-overflow: ellipsis; white-space: nowrap;'
    var children = [];
    for(var c = 0; c < this.children.length; c++){
      var child = this.children[c];

      /// only process if loaded from server
      if(child.json_class && child.name){
        var child_text = Omega.Config.locale[child.json_class] + ': ' +
                         child.name;
        var child_element = $('<div/>', {text : child_text, style : style});
        children.push(child_element);
      }
    }
    return children;
  },

  retrieve_details : function(page, details_cb){
    var details = [this._title_details(),
                   this._loc_details(),
                   this._children_details_wrapper()];

    details_cb(details);
  },

  refresh_details : function(){
    var system_children = $('#system_children');
    system_children.html('');
    system_children.append(this._children_details());
  }
};
