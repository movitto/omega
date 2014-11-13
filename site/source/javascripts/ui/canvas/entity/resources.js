/* Omega Entity Resources Mixin
 *
 * Note this refers to Cosmos resources (eg that which can be mined, transferred, etc)
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

// Entity Resources Mixin
Omega.UI.EntityResources = {
  _init_resources : function(){
    this.resources  = this.resources || [];
    this._update_resources();
  },

  /// Return bool indicating if asteroid has the specified resource
  has_resource : function(id){
    return !!(this.resource(id));
  },

  /// Return resource for the specified id
  resource : function(id){
    return $.grep(this.resources, function(r){ return r.id == id; })[0];
  },

  _update_resources : function(){
    if(this.resources){
      for(var r = 0; r < this.resources.length; r++){
        var res = this.resources[r];
        if(res.data) $.extend(res, res.data);
      }
    }
  }
};
