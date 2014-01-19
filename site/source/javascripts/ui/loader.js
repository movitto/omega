/* Omega JS Loader
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

/// TODO prioritize the status icons so user is indicated other resources are loading

//= require "vendor/jquery.storageapi-1.6.0.min"

Omega.UI.Loader = {
  placeholder : 'PLACEHOLDER',
  status_indicator : null,

  preload : function(){
    if(Omega.UI.Loader.preloaded) return;
    Omega.UI.Loader.preloaded = true;

    if(this.status_indicator) this.status_indicator.push_state('loading_resource');
    var config = Omega.Config;

    /// pop state when all resources finish loading
    var _this = this;
    this.async_events  = 0;
    this.event_counter = 0;
    var event_cb = this.status_indicator ?
      function(){
        _this.event_counter += 1;
        if(_this.event_counter == _this.async_events)
          _this.status_indicator.pop_state();
      } : function(){};

    this.preload_resources(config, event_cb);
    this.preload_skybox(config, event_cb);
  },

  _entities_to_preload : function(config){
    var entities = [
      new Omega.SolarSystem(),
      new Omega.Galaxy(),
      new Omega.Star(),
      new Omega.JumpGate(),
    ];

    var processed_planets = [];
    for(var r in config.resources){
      if(r.substr(0,6) == 'planet'){
        var planet = new Omega.Planet({color: "00000" + r[6]});
        if(processed_planets.indexOf(planet.colori()) == -1){
          entities.push(planet);
          processed_planets.push(planet.colori());
        }
      }
    }

    for(var s in config.resources.ships)
      entities.push(new Omega.Ship({type : s}));
    for(var s in config.resources.stations)
      entities.push(new Omega.Station({type : s}));

    return entities;
  },

  /// preload entity meshes and gfx to be cloned later
  preload_resources : function(config, event_cb){
    var entities = this._entities_to_preload(config);
    for(var e = 0; e < entities.length; e++){
      var entity = entities[e];
      if(entity.async_gfx) this.async_events += entity.async_gfx;
      entities[e].load_gfx(config, event_cb);
    }
  },

  /// preload skybox backgrounds
  preload_skybox : function(config, event_cb){
    var skybox = new Omega.UI.CanvasSkybox();
    skybox.init_gfx();
    var num = Omega._num_backgrounds;
    this.async_events += num;
    for(var b = 1; b <= num; b++){
      skybox.set(b, config, event_cb);
    }
  },

  json : function(){
    if(!Omega.UI.Loader.json_loader)
      Omega.UI.Loader.json_loader = new THREE.JSONLoader();
    return Omega.UI.Loader.json_loader;
  },

  clear_storage : function(){
    $.localStorage.removeAll();
  },

  /// TODO url param that when detected will always force a cache invalidation
  load_universe : function(page, retrieval_cb){
    /// retrieve & store universe_id stat,
    Omega.Stat.get('universe_id', null, page.node,
      function(stat_result){
        /// if different than existing one, invalidate stored cosmos data
        var orig = $.localStorage.get('omega.universe_id');
        if(orig != stat_result.value){
          var keys = $.localStorage.keys();
          for(var k = 0; k < keys.length; k++){
            if(keys[k].substr(0, 13) == 'omega.cosmos.'){
              $.localStorage.remove(keys[k]);
            }
          }
        }

        $.localStorage.set('omega.universe_id', stat_result.value);
        if(retrieval_cb) retrieval_cb(stat_result.value);
      });
  },

  load_system : function(system_id, page, retrieval_cb){
    /// first try to load from page cache
    var system = page.entity(system_id);
    if(system){
      /// XXX for consistency would like to uncomment,
      /// but will result in infite recursive call w/
      /// how load_system is currently used, need to fix
      //if(retrieval_cb) retrieval_cb(system);
      return system;
    }

    /// then from browser storage
    system = $.localStorage.get('omega.cosmos.' + system_id);
    if(system && system != Omega.UI.Loader.placeholder){
      system = RJR.JRMessage.convert_obj_from_jr_obj(system);
      system = new Omega.SolarSystem(system);
      page.entity(system_id, system);
      if(retrieval_cb) retrieval_cb(system);
      return system;

    /// then from server
    }else if(!system){
      system = Omega.UI.Loader.placeholder;
      page.entity(system_id, system);

      Omega.SolarSystem.with_id(system_id, page.node,
        function(system){
          /// TODO make sure this is not overwriting components (might be)
          page.entity(system_id, system);
          var jr_system = RJR.JRMessage.convert_obj_to_jr_obj(system.toJSON());
          $.localStorage.set('omega.cosmos.' + system_id, jr_system);
          if(retrieval_cb) retrieval_cb(system);
        });
    }

    return system;
  },

  load_galaxy : function(galaxy_id, page, retrieval_cb){
    /// first try to load from page cache
    var galaxy = page.entity(galaxy_id);
    if(galaxy){
      /// same note about retrieval_cb as in load_system above
      return galaxy;
    }

    /// then from browser storage
    galaxy = $.localStorage.get('omega.cosmos.' + galaxy_id);
    if(galaxy && galaxy != Omega.UI.Loader.placeholder){
      galaxy = RJR.JRMessage.convert_obj_from_jr_obj(galaxy);
      galaxy = new Omega.Galaxy(galaxy);
      page.entity(galaxy_id, galaxy);
      if(retrieval_cb) retrieval_cb(galaxy);
      return galaxy;

    /// then from server
    }else if(!galaxy){
      galaxy = Omega.UI.Loader.placeholder;
      page.entity(galaxy_id, galaxy);

      Omega.Galaxy.with_id(galaxy_id, page.node,
        function(galaxy){
          /// TODO make sure this is not overwriting components (might be)
          page.entity(galaxy_id, galaxy);
          var jr_galaxy = RJR.JRMessage.convert_obj_to_jr_obj(galaxy.toJSON());
          $.localStorage.set('omega.cosmos.' + galaxy_id, jr_galaxy);
          if(retrieval_cb) retrieval_cb(galaxy);
        });
    }

    return galaxy;
  },

  load_user_entities : function(user_id, node, cb){
    Omega.Ship.owned_by(user_id, node, cb);
    Omega.Station.owned_by(user_id, node, cb);
  },

  load_default_systems : function(page, cb){
    // load systems w/ most ships/stations
    Omega.Stat.get('systems_with_most', ['entities', 5], page.node,
      function(stat_result){
        if(stat_result){
          for(var s = 0; s < stat_result.value.length; s++){
            /// XXX callback invoked w/ each system individually
            Omega.UI.Loader.load_system(stat_result.value[s], page, cb);
          }
        }
      });
  }
};
