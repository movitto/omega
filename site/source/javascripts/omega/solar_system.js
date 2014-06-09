/* Omega SolarSystem JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega/solar_system/gfx"
//= require "omega/solar_system/info"

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

  /// Return child specified by id
  child : function(id){
    return $.grep(this.children, function(c) {
             return c.id == id || c == id;
           })[0];
  },

  /// Refresh solar system from server
  refresh : function(node, cb){
    var _this = this;
    Omega.SolarSystem.with_id(this.id, node, {children : true},
      function(system){
        _this.update(system);
        if(cb) cb(_this);
        _this.dispatchEvent({type: 'refreshed', data: _this});
      });
  },

  /// Update system's mutable attributes from other system
  update : function(system){
    for(var c = 0; c < system.children.length; c++){
      var nchild = system.children[c];
      var child  = this.child(nchild.id);
      if(!child)
        this.children.push(nchild);
      else if(typeof(child) === "string")
        this.children[c] = nchild;
      else if(child.update)
        child.update(nchild);
    }
  },

  /// Return system children in json format
  childrenJSON : function(){
    var children_json = [];
    for(var c = 0; c < this.children.length; c++)
      children_json.push(typeof(this.children[c]) === "string" ?
                         this.children[c] : this.children[c].toJSON());
    return children_json;
  },

  /// Return system in JSON format
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

  /// Return bool indiciating if system has a interconn to the specified endpoint
  has_interconn_to : function(endpoint_id){
    return $.grep(this.interconns.endpoints, function(endpoint){
             return endpoint.id == endpoint_id;
           }).length > 0;
  },

  /// Add system to local interconnects
  add_interconn_to : function(endpoint){
    this.interconns.add(endpoint);
  },

  /// Update system children with entities in list
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

        if(!this.has_interconn_to(gate.endpoint_id))
          this.add_interconn_to(system);
      }
    }
  },

  /// Set scene root to system whenever clicked in scene
  clicked_in : function(canvas){
    /// TODO cleanup
    if(!canvas.entity_container.is_selected(this)){
      canvas.follow_entity(this);

      var _this = this;
      /// TODO also retrieve / display manu entities in system
      this.refresh(canvas.page.node, function(){
        _this.refresh_details();
      });

      return;
    }

    canvas.page.audio_controls.stop();
    canvas.page.audio_controls.play(this.audio_effects, 'click');

    var _this = this;
    this.refresh(canvas.page.node, function(){
      canvas.set_scene_root(_this);
    });
  },

  /// TODO move these methods to omega/solar_system/mesh

  _has_hover_sphere : function(){
    var descendants = this.position_tracker().getDescendants();
    return descendants.indexOf(this.mesh.tmesh) != -1;
  },

  _add_hover_sphere : function(){
    this.position_tracker().add(this.mesh.tmesh);
  },

  _rm_hover_sphere : function(){
    this.position_tracker().remove(this.mesh.tmesh);
  },

  on_hover : function(canvas, hover_num){
    if(hover_num == 1){
      canvas.page.audio_controls.stop(this.audio_effects);
      canvas.page.audio_controls.play(this.audio_effects, 'hover');
    }

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
$.extend(Omega.SolarSystem.prototype, Omega.SolarSystemInfo);

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
