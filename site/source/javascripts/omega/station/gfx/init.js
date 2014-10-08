/* Omega JS Station Graphics Initializer
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.StationGfxInitializer = {
  include_highlight : true,

  _init_components : function(){
    this.components = [this.position_tracker(), this.camera_tracker()];
  },

  _init_highlight : function(){
    this.highlight = this._retrieve_resource('highlight').clone();
    this.highlight.omega_entity = this;
    if(this.include_highlight) this.position_tracker().add(this.highlight.mesh);
  },

  _init_lamps : function(){
    this.lamps = this._retrieve_resource('lamps').clone();
    this.lamps.omega_entity = this;
    this.lamps.init_gfx();
  },

  _init_construction_bar : function(){
    this.construction_bar = this._retrieve_resource('construction_bar').clone();
    this.construction_bar.omega_entity = this;
    this.construction_bar.bar.init_gfx();
  },

  _init_audio : function(){
    this.construction_audio = this._retrieve_resource('construction_audio');
  },

  _add_lamp_components : function(){
    for(var l = 0; l < this.lamps.olamps.length; l++)
      this.mesh.tmesh.add(this.lamps.olamps[l].component);
  },

  _init_mesh : function(){
    var _this = this;
    var mesh_geometry = 'station.' + this.type + '.mesh_geometry';
    this._retrieve_async_resource(mesh_geometry, function(geometry){
      var material = _this._retrieve_resource('mesh_material').material;
      var mesh = new Omega.StationMesh({material: material.clone(),
                                        geometry: geometry.clone()});

      _this.mesh = mesh;
      _this.mesh = mesh;
      _this.mesh.omega_entity = _this;
      _this._add_lamp_components();
      _this.position_tracker().add(_this.mesh.tmesh);

      _this.update_gfx();
      _this._gfx_initializing = false;
      _this._gfx_initialized  = true;
    });
  },

  init_gfx : function(event_cb){
    if(this.gfx_initialized() || this.gfx_initializing()) return;
    this._gfx_initializing = true;
    this.load_gfx(event_cb);
    this._init_components();
    this._init_highlight();
    this._init_lamps();
    this._init_construction_bar();
    this._init_audio();
    this._init_mesh();
    this.last_moved = new Date();
    this.update_gfx();
  }
};
