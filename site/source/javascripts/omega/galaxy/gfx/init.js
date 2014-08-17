/* Omega JS Galaxy Graphics Initializer
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.GalaxyGfxInitializer = {
  _init_components : function(){
    this.stars  = this._retrieve_resource('stars');
    this.clouds = this._retrieve_resource('clouds');

    /// order of components here affects rendering
    this.components = this.clouds.components().
               concat(this.stars.components());
  },

  init_gfx : function(event_cb){
    if(this.gfx_initialized()) return;
    this._gfx_initializing = true;
    this.load_gfx(event_cb);

    this._init_components();

    this._gfx_initializing = false;
    this._gfx_initialized  = true;
  }
};
