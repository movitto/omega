/* Omega JS Async Resource Loader
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.UI.AsyncResourceLoader = {
  _resources : function(){
    if(this.__resources) return this.__resources;
    this.__resources = {};
    return this.__resources;
  },

  _json_loader : function(){
    if(this.__json_loader) return this.__json_loader;
    this.__json_loader = new THREE.JSONLoader();
    return this.__json_loader;
  },

  /// Asynchronously loads a JSON component (mesh geometry, etc)
  /// TODO split path / prefix params, introduce generic args, and/or default prefix
  load : function(id, path_prefix, event_cb){
    var _this         = this;
    var prefix        = path_prefix[1];
    var path          = path_prefix[0];
    var path_is_array = (typeof(path) === "array" || typeof(path) == "object");
    var paths         =  path_is_array ? path : [path];

    var resources = [];
    for(var p = 0; p < paths.length; p++){
      this._json_loader().load(paths[p], function(resource){
        resource.omega_id = id;
        resources.push(resource);

        var have_all_responses = resources.length == paths.length;
        if(have_all_responses){
          var result = path_is_array ? resources : resources[0];
          _this._resources()[id] = result;
          if(event_cb) event_cb(result);
          _this.dispatchEvent({type: 'loaded_resource', data: result});
        }
      }, prefix);
    }
  },

  _handle_loaded : function(){
    if(this._handling_loaded) return;
    this._handling_loaded = true;

    var _this = this;
    this.addEventListener('loaded_resource', function(evnt){
      _this._on_loaded(evnt.data);
    });
  },

  _on_loaded : function(resource){
    var id = resource.omega_id;
    if(!this._retrieval_callbacks || !this._retrieval_callbacks[id]) return;
    for(var cb = 0; cb < this._retrieval_callbacks[id].length; cb++)
      this._retrieval_callbacks[id][cb](resource);
    this._retrieval_callbacks[id] = [];
  },

  /// Invoke callback with json component if loaded, else register to be invoked on retrieval
  retrieve : function(id, cb){
    this._handle_loaded();

    var resources = this._resources()
    if(resources[id]){
      cb(resources[id]);
      return;
    }

    this._retrieval_callbacks     = this._retrieval_callbacks || {};
    this._retrieval_callbacks[id] = this._retrieval_callbacks[id] || [];
    this._retrieval_callbacks[id].push(cb);
  }
};

THREE.EventDispatcher.prototype.apply( Omega.UI.AsyncResourceLoader );
