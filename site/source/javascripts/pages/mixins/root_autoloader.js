/* Omega Page Root Autoloader Mixin
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "vendor/purl"

Omega.Pages.RootAutoloader = {
  /// Load id of entity to autoload from url or config
  _default_root_id : function(){
    var url = $.url(window.location);
    var id  = url.param('root');
    if(!id && Omega.Config && Omega.Config.default_root)
      id = Omega.Config.default_root;
    return id;
  },

  /// Return type of entity & entity to autoload, nil if not set
  _default_root : function(){
    var id = this._default_root_id();
    if(!id) return null;

    var entity = null;
    if(id == 'random'){
      var entities = this.systems().concat(this.galaxies());
      entity = entities[Math.floor(Math.random()*entities.length)];
    }else{
      entity = $.grep(this.all_entities(), function(e){
        return e.id == id || e.name == id;
      })[0];
    }

    /// TODO load entity from server if id is set by entity is null?
    return entity;
  },

  /// Return bool indicating if a root entity should be autoloaded
  _should_autoload_root : function(){
    return !this.autoloaded && (this._default_root() != null);
  },

  /// Autoload root scene entity
  autoload_root : function(){
    var _this = this;

    this.autoloaded = true;
    var root = this._default_root();
    root.refresh(this.node, function(){
      _this.canvas.set_scene_root(root);
    });
  },

};
