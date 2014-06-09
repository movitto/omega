/* Omega JS Resource Loader
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.UI.ResourceLoader = function() {}

Omega.UI.ResourceLoader.prototype = {
  constructor : Omega.UI.ResourceLoader,

  apply : function(object){
    object.loaded_resource   = Omega.UI.ResourceLoader.prototype.loaded_resource;
    object.retrieve_resource = Omega.UI.ResourceLoader.prototype.retrieve_resource;
    object._on_load_resource = Omega.UI.ResourceLoader.prototype._on_load_resource;
    THREE.EventDispatcher.prototype.apply(object);
  },

  loaded_resource : function(resource_id, resource){
    if(this.loaded_resources === undefined) this.loaded_resources = {};
    this.loaded_resources[resource_id] = resource;
    this.dispatchEvent({type: 'loaded_' + resource_id, data: resource});
  },

  retrieve_resource : function(resource_id, cb){
    var _this = this;

    if(this.loaded_resources && this.loaded_resources[resource_id]){
      cb(this.loaded_resources[resource_id]);
      return;
    }

    var loaded_cb = function(evnt){
      _this._on_load_resource(evnt, resource_id, cb, loaded_cb);
    };
    this.addEventListener('loaded_' + resource_id, loaded_cb);
  },

  _on_load_resource : function(evnt, resource_id, client_cb, loaded_cb){
    client_cb(evnt.data);
    this.removeEventListener('loaded_' + resource_id, loaded_cb);
  }
};
