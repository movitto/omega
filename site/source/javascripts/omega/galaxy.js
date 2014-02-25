/* Omega Galaxy JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega/galaxy/gfx"

Omega.Galaxy = function(parameters){
  this.components = [];
  this.shader_components = [];

  this.children   = [];
  $.extend(this, parameters);

  this.bg = Omega.str_to_bg(this.id);

  this.children = Omega.convert_entities(this.children);
  this.location = Omega.convert_entity(this.location)
};

Omega.Galaxy.prototype = {
  constructor : Omega.Galaxy,
  json_class  : 'Cosmos::Entities::Galaxy',

  async_gfx : 1,

  /// refresh galaxy from server
  refresh : function(node, cb){
    var _this = this;
    Omega.Galaxy.with_id(this.id, node, {children : true, recursive : false},
      function(galaxy){
        _this.update(galaxy);
        if(cb) cb(_this);
      });
  },

  update : function(galaxy){
    /// XXX see comment in SolarSystem#update
    for(var c = 0; c < this.children.length; c++){
      var child  = this.children[c];
      var nchild = galaxy.children[c];
      if(typeof(child) === "string")
        this.children[c] = nchild;
      else if(child.update)
        child.update(nchild);
    }
  },

  childrenJSON : function(){
    var children_json = [];
    for(var c = 0; c < this.children.length; c++)
      children_json.push(typeof(this.children[c]) === "string" ?
                         this.children[c] : this.children[c].toJSON())
    return children_json;
  },

  toJSON : function(){
    var children_json = this.childrenJSON();
    return {json_class : this.json_class,
            id         : this.id,
            name       : this.name,
            location   : this.location ? this.location.toJSON() : null,
            children   : children_json};
  },

  systems : function(){
    return $.grep(this.children, function(c){
      return c.json_class &&
             c.json_class == 'Cosmos::Entities::SolarSystem';
    });
  },

  set_children_from : function(entities){
    var systems = this.children;
    for(var s = 0; s < systems.length; s++){
      var system = $.grep(entities, function(entity){
        return entity.id == systems[s].id;
      })[0];

      if(system != null){
        this.children[s] = system;
        system.galaxy = this;
      }
    }
  },
};

$.extend(Omega.Galaxy.prototype, Omega.GalaxyGfx);

// return the galaxy with the specified id
Omega.Galaxy.with_id = function(id, node, opts, cb){
  if(!cb && typeof(opts) === "function"){
    cb = opts; opts = {};
  }
  var children  = !!(opts['children']);
  var recursive = !!(opts['recursive']);

  node.http_invoke('cosmos::get_entity',
    'with_id', id, 'children', children, 'recursive', recursive,
    function(response){
      var galaxy = null;
      if(response.result) galaxy = new Omega.Galaxy(response.result);
      cb(galaxy);
    });
};

THREE.EventDispatcher.prototype.apply( Omega.Galaxy.prototype );
