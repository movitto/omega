/* Omega JS Resource Loader
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.UI.Loader = {
  preload : function(){
    if(Omega.UI.Loader.preloaded) return;
    Omega.UI.Loader.preloaded = true;

    this.preload_meshes();
    this.preload_skybox();
    /// TODO load cosmos entities/heirarchies ?
  },

  /// preload entity meshes and gfx to be cloned later
  preload_meshes : function(){
    var config = Omega.Config;
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
  preload_skybox : function(){
    var skybox = new Omega.UI.Canvas.Skybox();
    skybox.init_gfx();
    for(var s = 1; s <= config.resources.backgrounds.solar_system; s++){
      skybox.set('system' + s, config);
    }
    for(var g = 1; g <= config.resources.backgrounds.galaxy; g++){
      skybox.set('galaxy' + g, config);
    }
  },

  json : function(){
    if(!Omega.UI.Loader.json_loader)
      Omega.UI.Loader.json_loader = new THREE.JSONLoader();
    return Omega.UI.Loader.json_loader;
  }
};
