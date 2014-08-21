/* Omega JS Asteroid Graphics Initializer
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.AsteroidGfxInitializer = {
  init_mesh : function(){
    /// pick a random mesh from those available
    var num_meshes = Omega.AsteroidMesh.geometry_paths()[0].length;
    var mesh_num   = Math.floor(Math.random() * num_meshes);

    var _this = this;
    this._retrieve_async_resource('asteroid.meshes', function(geometries){
      var material = _this._retrieve_resource('mesh_material').material;
      var geometry = geometries[mesh_num];
      var mesh = new Omega.AsteroidMesh({material: material, geometry: geometry});

      _this.mesh = mesh;
      _this.mesh.omega_entity = _this;
      _this.position_tracker().add(_this.mesh.tmesh);

      _this.update_gfx();
      _this._gfx_initialized = true;
    });
  },

  init_components : function(){
    this.components = [this.position_tracker()];
  },

  init_gfx : function(event_cb){
    if(this.gfx_initialized()) return;
    this.load_gfx(event_cb);
    this.init_mesh();
    this.init_components();
  }
};
