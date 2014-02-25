/* Omega SolarSystem JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega/solar_system/gfx"

Omega.SolarSystem = function(parameters){
  this.components = [];
  this.shader_components = [];

  this.children   = [];
  $.extend(this, parameters);

  this.bg = Omega.str_to_bg(this.id);

  this.children = Omega.convert_entities(this.children);
  this.location = Omega.convert_entity(this.location)

  this.interconns = new Omega.SolarSystemInterconns();
  this.interconns.omega_entity = this;
};

Omega.SolarSystem.prototype = {
  json_class : 'Cosmos::Entities::SolarSystem',

  /// refresh solarsystem from server
  refresh : function(node, cb){
    var _this = this;
    Omega.SolarSystem.with_id(this.id, node, {children : true},
      function(system){
        _this.update(system);
        if(cb) cb(_this);
      });
  },

  update : function(system){
    /// XXX currently cosmos-level system children are not added/rm'd 
    /// on the fly, so assuming children in lists will map 1-1.
    /// When this is not the case, process children accordingly (same in Galaxy#update)
    for(var c = 0; c < this.children.length; c++){
      var child  = this.children[c];
      var nchild = system.children[c];
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
                         this.children[c] : this.children[c].toJSON());
    return children_json;
  },

  toJSON : function(){
    var children_json = this.childrenJSON();
    return {json_class : this.json_class,
            id         : this.id,
            name       : this.name,
            location   : this.location ? this.location.toJSON() : null,
            parent_id  : this.parent_id,
            children   : children_json};
  },

  /// Human friendly name if set, else id
  title : function(){
    return this.name ? this.name : this.id;
  },

  asteroids : function(){
    return $.grep(this.children, function(c){
      return c.json_class &&
             c.json_class == 'Cosmos::Entities::Asteroid';
    });
  },

  planets : function(){
    return $.grep(this.children, function(c){
      return c.json_class &&
             c.json_class == 'Cosmos::Entities::Planet';
    });
  },

  jump_gates : function(){
    return $.grep(this.children, function(c){
      return c.json_class &&
             c.json_class == 'Cosmos::Entities::JumpGate';
    });
  },

  update_children_from : function(entities){
    /// update jg endpoints from entities / add interconnections
    var gates = this.jump_gates();
    for(var g = 0; g < gates.length; g++){
      var gate = gates[g];
      var system = $.grep(entities, function(entity){
        return entity.id == gate.endpoint_id;
      })[0];

      if(system != null){
        gate.endpoint = system;
        this.interconns.add(system);
      }
    }
  },

  clicked_in : function(canvas){
    canvas.set_scene_root(this);
  },

  _has_hover_sphere : function(){
    return $.inArray(this.mesh.tmesh, this.components) != -1;
  },

  _add_hover_sphere : function(){
    this.components.push(this.mesh.tmesh);
  },

  _rm_hover_sphere : function(){
    var index = $.inArray(this.mesh.tmesh, this.components);
    this.components.splice(index, 1);
  },

  on_hover : function(canvas){
    var _this = this;
    canvas.reload(this, function(){
      if(!_this._has_hover_sphere())
        _this._add_hover_sphere();
    });
  },

  on_unhover : function(canvas){
    var _this = this;
    canvas.reload(this, function(){
      if(_this._has_hover_sphere())
        _this._rm_hover_sphere();
    });
  }
};

$.extend(Omega.SolarSystem.prototype, Omega.SolarSystemGfx);

// return the solar system with the specified id
Omega.SolarSystem.with_id = function(id, node, opts, cb){
  if(!cb && typeof(opts) === "function"){
    cb = opts; opts = {};
  }
  var children = !!(opts['children']);

  node.http_invoke('cosmos::get_entity',
    'with_id', id, 'children', children,
    function(response){
      var sys = null;
      if(response.result) sys = new Omega.SolarSystem(response.result);
      cb(sys);
    });
}

THREE.EventDispatcher.prototype.apply( Omega.SolarSystem.prototype );
