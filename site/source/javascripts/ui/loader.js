/* Omega JS Resource Loader
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.UI.Loader = {
  status_indicator : null,

  preload : function(){
    if(Omega.UI.Loader.preloaded) return;
    Omega.UI.Loader.preloaded = true;

    if(this.status_indicator) this.status_indicator.push_state('loading_resource');
    var config = Omega.Config;
    this.preload_meshes(config);
    this.preload_skybox(config);
    /// TODO load cosmos entities/heirarchies ?
    if(this.status_indicator) this.status_indicator.pop_state();
  },

  /// preload entity meshes and gfx to be cloned later
  preload_meshes : function(config){
    (new Omega.SolarSystem()).load_gfx(config);
    (new Omega.Galaxy()).load_gfx(config);
    (new Omega.Star()).load_gfx(config);
    (new Omega.JumpGate()).load_gfx(config);
    for(var r in config.resources){
      if(r.substr(0,6) == 'planet')
        (new Omega.Planet({color: "00000" + r[6]})).load_gfx(config);
    }
    for(var s in config.resources.ships)
      (new Omega.Ship({type : s})).load_gfx(config);
    for(var s in config.resources.stations)
      (new Omega.Station({type : s})).load_gfx(config);
  },

  /// preload skybox backgrounds
  preload_skybox : function(config){
    var skybox = new Omega.UI.Canvas.Skybox();
    skybox.init_gfx();
    for(var b = 1; b <= Omega.num_backgrounds; b++){
      skybox.set('system' + s, config);
    }
  },

  json : function(){
    if(!Omega.UI.Loader.json_loader)
      Omega.UI.Loader.json_loader = new THREE.JSONLoader();
    return Omega.UI.Loader.json_loader;
  }
};
