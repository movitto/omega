/* Omega JS Command Tracker
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.UI.CommandTracker = function(parameters){
  this.handling = [];

  /// need handle to page to
  /// - register and clear rpc handlers with node
  /// - retrieve/update entities
  /// - process new entities
  /// - refresh entities in canvas scene
  /// - refresh canvas entity container
  this.page = null;

  $.extend(this, parameters);
};

Omega.UI.CommandTracker.prototype = {
  motel_events :
    ['motel::on_movement',
     'motel::on_rotation',
     'motel::changed_strategy',
     'motel::location_stopped'],

  manufactured_events :
    ['manufactured::event_occurred'],

  _callbacks_motel_event : function(evnt, event_args){
    var entity = $.grep(this.page.all_entities(), function(entity){
                   return entity.location &&
                          entity.location.id == event_args[0].id;
                 })[0];
    if(entity == null) return;
    var new_loc = new Omega.Location(event_args[0]);

    // reset last moved if movement strategy changed
    if(entity.location.movement_strategy.json_class !=
       new_loc.movement_strategy.json_class)
      entity.last_moved = null;
    else
      entity.last_moved = new Date();

    entity.location = new_loc; // TODO should this just be an update?

    if(this.page.canvas.is_root(entity.parent_id)){
      this.page.canvas.reload(entity, function(){
        if(entity.update_gfx) entity.update_gfx();
      });
    }

    this.page.canvas.entity_container.refresh();
  },

  _callbacks_resource_collected : function(evnt, event_args){
    var ship     = event_args[1];
    var resource = event_args[2];
    var quantity = event_args[3];

    var entity = $.grep(this.page.all_entities(),
                        function(entity){ return entity.id == ship.id; })[0];
    if(entity == null) return;
    entity.mining    = ship.mining;
    /// FIXME also need to lookup & set entity.mining_asteroid
    /// incase entity is already mining on being loaded
    entity.resources = ship.resources;
    entity._update_resources();

    if(this.page.canvas.is_root(entity.parent_id)){
      this.page.canvas.reload(entity, function(){
        if(entity.update_gfx) entity.update_gfx();
      });
    }

    this.page.canvas.entity_container.refresh();
  },

  _callbacks_mining_stopped : function(evnt, event_args){
    var ship     = event_args[1];
    var resource = event_args[2];
    var reason   = event_args[3];

    var entity = $.grep(this.page.all_entities(),
                        function(entity){ return entity.id == ship.id; })[0];
    if(entity == null) return;
    entity.mining          = null;
    entity.mining_asteroid = null;
    entity.resources = ship.resources;
    entity._update_resources();

    if(this.page.canvas.is_root(entity.parent_id)){
      this.page.canvas.reload(entity, function(){
        if(entity.update_gfx) entity.update_gfx();
      });
    }

    this.page.canvas.entity_container.refresh();
  },

  _callbacks_attacked : function(evnt, event_args){
    var attacker = event_args[1];
    var defender = event_args[2];

    var pattacker = $.grep(this.page.all_entities(),
                           function(entity){ return entity.id == attacker.id; })[0];
    var pdefender = $.grep(this.page.all_entities(),
                           function(entity){ return entity.id == defender.id; })[0];
    if(pattacker == null || pdefender == null) return;
    pattacker.attacking    = pdefender;

    if(this.page.canvas.is_root(pattacker.parent_id)){
      this.page.canvas.reload(pattacker, function(){
        if(pattacker.update_gfx) pattacker.update_gfx();
      });
    }
  },

  _callbacks_attacked_stop : function(evnt, event_args){
    var attacker = event_args[1];
    var defender = event_args[2];

    var pattacker = $.grep(this.page.all_entities(),
                           function(entity){ return entity.id == attacker.id; })[0];
    var pdefender = $.grep(this.page.all_entities(),
                           function(entity){ return entity.id == defender.id; })[0];
    if(pattacker == null || pdefender == null) return;
    pattacker.attacking    = null;

    if(this.page.canvas.is_root(pattacker.parent_id)){
      this.page.canvas.reload(pattacker, function(){
        if(pattacker.update_gfx) pattacker.update_gfx();
      });
    }
  },

  _callbacks_defended : function(evnt, event_args){
    var defender = event_args[1];
    var attacker = event_args[2];

    var pattacker = $.grep(this.page.all_entities(),
                           function(entity){ return entity.id == attacker.id; })[0];
    var pdefender = $.grep(this.page.all_entities(),
                           function(entity){ return entity.id == defender.id; })[0];
    if(pattacker == null || pdefender == null) return;
    pdefender.hp           = defender.hp;
    pdefender.shield_level = defender.shield_level;

    if(this.page.canvas.is_root(pdefender.parent_id) &&
       this.page.canvas.has(pdefender.id)){
      this.page.canvas.reload(pdefender, function(){
        if(pdefender.update_gfx) pdefender.update_gfx();
      });
    }
  },

  _callbacks_defended_stop : function(evnt, event_args){
    var defender = event_args[1];
    var attacker = event_args[2];

    var pattacker = $.grep(this.page.all_entities(),
                           function(entity){ return entity.id == attacker.id; })[0];
    var pdefender = $.grep(this.page.all_entities(),
                           function(entity){ return entity.id == defender.id; })[0];
    if(pattacker == null || pdefender == null) return;
    pdefender.hp           = defender.hp;
    pdefender.shield_level = defender.shield_level;

    if(this.page.canvas.is_root(pdefender.parent_id) &&
       this.page.canvas.has(pdefender.id)){
      this.page.canvas.reload(pdefender, function(){
        if(pdefender.update_gfx) pdefender.update_gfx();
      });
    }
  },

  _callbacks_destroyed_by : function(evnt, event_args){
    var defender = event_args[1];
    var attacker = event_args[2];

    var pattacker = $.grep(this.page.all_entities(),
                           function(entity){ return entity.id == attacker.id; })[0];
    var pdefender = $.grep(this.page.all_entities(),
                           function(entity){ return entity.id == defender.id; })[0];
    if(pattacker == null || pdefender == null) return;
    pattacker.attacking    = null;
    pdefender.hp           = 0;
    pdefender.shield_level = 0;

    if(this.page.canvas.is_root(pattacker.parent_id)){
      this.page.canvas.reload(pattacker, function(){
        if(pattacker.update_gfx) pattacker.update_gfx();
      });
    }

    if(this.page.canvas.is_root(pdefender.parent_id)){
      /// allow defender to tidy up gfx b4 removing from scene:
      pdefender.update_gfx();
      this.page.canvas.remove(pdefender);
    }
  },

  _callbacks_construction_complete : function(evnt, evnt_args){
    var station     = evnt_args[1];
    var constructed = evnt_args[2];

    var pstation = $.grep(this.page.all_entities(),
                          function(entity){ return entity.id == station.id; })[0];

    pstation.construction_percent = 0;
    pstation.resources = station.resources;
    pstation._update_resources();

    if(this.page.canvas.is_root(pstation.parent_id)){
      this.page.canvas.reload(pstation, function(){ pstation.update_gfx(); });
      this.page.canvas.animate();
    }

    // retrieve full entity from server / process
    var _this = this;
    Omega.Ship.get(constructed.id, this.page.node, function(entity){
      _this.page.process_entity(entity);
      if(_this.page.canvas.is_root(entity.system_id)){
        /// TODO better place to put audi effect?
        _this.page.audio_controls.play('construction');
        _this.page.canvas.add(entity);
      }
    });

    this.page.canvas.entity_container.refresh();
  },

  _callbacks_construction_failed : function(evnt, evnt_args){
    var station       = evnt_args[1];
    var failed_entity = evnt_args[2];

    var pstation = $.grep(this.page.all_entities(),
                          function(entity){ return entity.id == station.id; })[0];

    pstation.construction_percent = 0;
    pstation.resources = station.resources;
    pstation._update_resources();

    if(this.page.canvas.is_root(pstation.parent_id)){
      this.page.canvas.reload(pstation, function(){ pstation.update_gfx(); });
      this.page.canvas.animate();
    }

    /// TODO should pop up dialog or similar w/ reason for failure

    this.page.canvas.entity_container.refresh();
  },

  _callbacks_partial_construction : function(evnt, evnt_args){
    var station           = evnt_args[1];
    var being_constructed = evnt_args[2];
    var percent           = evnt_args[3];

    var pstation = $.grep(this.page.all_entities(),
                          function(entity){ return entity.id == station.id; })[0];

    pstation.construction_percent = percent;
    if(this.page.canvas.is_root(pstation.parent_id)){
      this.page.canvas.reload(pstation, function(){ pstation.update_gfx(); });
      this.page.canvas.animate();
    }
  },

  _callbacks_system_jump : function(evnt, evnt_args){
    var jumped     = evnt_args[1];
    var old_system = evnt_args[2];

    var in_root = this.page.canvas.is_root(jumped.system_id);
    var pentity = $.grep(this.page.all_entities(),
                         function(entity){ return entity.id == jumped.id })[0];
    var psystem = $.grep(this.page.all_entities(),
                         function(entity){ return entity.id == jumped.system_id; })[0];

    if(!pentity) pentity = Omega.convert_entity(jumped);
    pentity.update_system(psystem);

    if(in_root){
      this.page.process_entity(pentity);
      this.page.canvas.add(pentity);
    }else{
      this.page.entity(pentity.id, pentity);
    }
  },

  _msg_received : function(evnt, event_args){
    if(Omega.UI.CommandTracker.prototype.motel_events.indexOf(evnt) != -1){
      this._callbacks_motel_event(evnt, event_args);

    }else{
      var mevnt = event_args[0];
      if(mevnt == 'resource_collected'){
        this._callbacks_resource_collected(evnt, event_args);

      }else if(mevnt == 'mining_stopped'){
        this._callbacks_mining_stopped(evnt, event_args);

      }else if(mevnt == 'attacked'){
        this._callbacks_attacked(evnt, event_args);

      }else if(mevnt == 'attacked_stop'){
        this._callbacks_attacked_stop(evnt, event_args);

      }else if(mevnt == 'defended'){
        this._callbacks_defended(evnt, event_args);

      }else if(mevnt == 'defended_stop'){
        this._callbacks_defended_stop(evnt, event_args);

      }else if(mevnt == 'destroyed_by'){
        this._callbacks_destroyed_by(evnt, event_args);

      }else if(mevnt == 'construction_complete'){
        this._callbacks_construction_complete(evnt, event_args);

      }else if(mevnt == 'construction_failed'){
        this._callbacks_construction_failed(evnt, event_args);

      }else if(mevnt == 'partial_construction'){
        this._callbacks_partial_construction(evnt, event_args);

      }else if(mevnt == 'system_jump'){
        this._callbacks_system_jump(evnt, event_args);
      }
    }
  },

  track : function(evnt){
    if(this.handling.indexOf(evnt) != -1) return;
    this.handling.push(evnt);

    var _this = this;
    this.page.node.addEventListener(evnt, function(node_evnt){
      var args = [];
      for(var a = 0; a < node_evnt.data.length; a++)
        args.push(node_evnt.data[a]);
      _this._msg_received(evnt, args);
    });
  }
};
