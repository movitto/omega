/* Omega JS Galaxy Graphics Loader
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.GalaxyGfxLoader = {
  _stars : function(event_cb){
    return new Omega.GalaxyDensityWave({event_cb   : event_cb,
                                        type       : 'stars'});
  },

  _clouds : function(event_cb){
    return new Omega.GalaxyDensityWave({event_cb   : event_cb,
                                        type       : 'clouds',
                                        colorStart : 0x3399FF,
                                        colorEnd   : 0x33FFC2});

  },

  _load_components : function(event_cb){
    this._store_resource('stars', this._stars(event_cb));
    this._store_resource('clouds', this._clouds(event_cb));
  },

  load_gfx : function(event_cb){
    if(this.gfx_loaded()) return;
    this._load_components(event_cb);
    this._loaded_gfx();
  }
};
