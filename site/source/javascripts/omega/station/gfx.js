/* Omega Station Graphics
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

/// TODO many of these methods can be shared / reused w/ ship/gfx.js

///////////////////////////////////////// high level operations

Omega.load_station_gfx = function(config, type, event_cb){
  var gfx = {};
  Omega.Station.gfx[type] = gfx;

  gfx.mesh_material = new Omega.StationMeshMaterial(config, type, event_cb);

  Omega.load_station_template_mesh(config, type, function(mesh){
    gfx.mesh = mesh;
    Omega.Station.prototype.loaded_resource('template_mesh_' + type, mesh);
    if(event_cb) event_cb();
  });

  gfx.highlight = new Omega.StationHighlightEffects();
  gfx.lamps     = Omega.load_station_lamps(config, type);
  gfx.construction_bar = new Omega.StationConstructionBar();
};

Omega.init_station_gfx = function(config, station, event_cb){
  station.components = [];

  Omega.load_station_mesh(station.type, function(mesh){
    station.mesh = mesh;
    station.mesh.omega_obj = station.mesh;
    station.mesh.omega_entity = station;
    station.components.push(station.mesh);
    station.update_gfx();
    station.loaded_resource('mesh', station.mesh);
  });

  station.highlight = Omega.Station.gfx[station.type].highlight.clone();
  station.highlight.omega_entity = station;
  station.highlight.omega_obj = station.highlight;
  station.components.push(station.highlight);

  station.lamps = [];
  for(var l = 0; l < Omega.Station.gfx[station.type].lamps.length; l++){
    var template_lamp = Omega.Station.gfx[station.type].lamps[l];
    var lamp = template_lamp.clone();
    lamp.init_gfx();
    station.lamps.push(lamp);
    station.components.push(lamp.component);
  }

  station.construction_bar = Omega.Station.gfx[station.type].construction_bar.clone();
  station.construction_bar.init_gfx(config, event_cb);

  station.update_gfx();
};

Omega.cp_station_gfx = function(from, to){
  to.components        = from.components;
  to.shader_components = from.shader_components;
  to.mesh              = from.mesh;
  to.highlight         = from.highlight;
  to.lamps             = from.lamps;
  to.construction_bar  = from.construction_bar;
};

Omega.update_station_gfx = function(station){
  station._update_mesh();
  station._update_highlight_effects();
  station._update_lamps();
  station._update_construction_bar();
};

///////////////////////////////////////// initializers

Omega.StationMeshMaterial = function(config, type, event_cb){
  var texture_path = config.url_prefix + config.images_path +
                     config.resources.stations[type].material;
  var texture      = THREE.ImageUtils.loadTexture(texture_path, {}, event_cb);
  $.extend(this, new THREE.MeshLambertMaterial({map: texture, overdraw: true}));
};

Omega.load_station_template_mesh = function(config, type, cb){
  var geometry_path   = config.url_prefix + config.images_path +
                        config.resources.stations[type].geometry;
  var geometry_prefix = config.url_prefix + config.images_path +
                        config.meshes_path;
  var rotation        = config.resources.stations[type].rotation;
  var offset          = config.resources.stations[type].offset;
  var scale           = config.resources.stations[type].scale;

  Omega.UI.Loader.json().load(geometry_path, function(mesh_geometry){
    var material = Omega.Station.gfx[type].mesh_material;
    var mesh     = new THREE.Mesh(mesh_geometry, material);
    mesh.base_position = mesh.base_rotation = [0,0,0];
    if(offset){
      mesh.position.set(offset[0], offset[1], offset[2]);
      mesh.base_position = offset;
    }
    if(scale)
      mesh.scale.set(scale[0], scale[1], scale[2]);
    if(rotation){
      mesh.rotation.set(rotation[0], rotation[1], rotation[2]);
      mesh.matrix.makeRotationFromEuler(mesh.rotation);
      mesh.base_rotation = rotation;
    }
    cb(mesh);
  }, geometry_prefix);
};

Omega.load_station_mesh = function(type, cb){
  Omega.Station.prototype.retrieve_resource('template_mesh_' + type,
    function(template_mesh){
      var mesh = template_mesh.clone();

      /// so mesh materials can be independently updated:
      mesh.material = Omega.Station.gfx[type].mesh_material.clone();

      /// copy custom attrs required later
      mesh.base_position = template_mesh.base_position;
      mesh.base_rotation = template_mesh.base_rotation;
      if(!mesh.base_position) mesh.base_position = [0,0,0];
      if(!mesh.base_rotation) mesh.base_rotation = [0,0,0];

      cb(mesh);
    });
};

Omega.StationHighlightEffects = function(){
  var highlight_props    = Omega.Station.prototype.highlight_props;
  var highlight_geometry = new THREE.CylinderGeometry( 0, 40, 80, 8, 2 );
  var highlight_material = new THREE.MeshBasicMaterial({ color:0x33ff33,
                                                         shading: THREE.FlatShading } );
  var highlight_mesh     = new THREE.Mesh(highlight_geometry, highlight_material);
  highlight_mesh.position.set(highlight_props.x,
                              highlight_props.y,
                              highlight_props.z);
  highlight_mesh.rotation.set(highlight_props.rot_x,
                              highlight_props.rot_y,
                              highlight_props.rot_z);
  $.extend(this, highlight_mesh);
};

Omega.load_station_lamps = function(config, type){
  var lamps  = config.resources.stations[type].lamps;
  var olamps = [];
  if(lamps){
    for(var l = 0; l < lamps.length; l++){
      var lamp  = lamps[l];
      var olamp = new Omega.UI.CanvasLamp({size : lamp[0],
                                           color: lamp[1],
                                   base_position: lamp[2]});
      olamps.push(olamp);
    }
  }

  return olamps;
};

Omega.StationConstructionBar = function(){
  var len = Omega.Station.prototype.construction_bar_props.length;
  var construction_bar =
    new Omega.UI.CanvasProgressBar({
      width: 3, length: len, axis : 'x',
      color1: 0x00FF00, color2: 0x0000FF,
      vertices: [[[-len/2, 100, 0],
                  [-len/2, 100, 0]],
                 [[-len/2, 100, 0],
                  [ len/2, 100, 0]]]});
  $.extend(this, construction_bar);
};

///////////////////////////////////////// update methods

/// This module gets mixed into Station
Omega.StationGfxUpdaters = {
  _update_mesh : function(){
    if(!this.mesh) return;
    this.mesh.position.set(this.location.x, this.location.y, this.location.z);
  },

  _update_highlight_effects : function(){
    if(!this.highlight) return;
    this.highlight.position.set(this.location.x,
                                this.location.y,
                                this.location.z);
    this.highlight.position.add(new THREE.Vector3(this.highlight_props.x,
                                                  this.highlight_props.y,
                                                  this.highlight_props.z));
  },

  _update_lamps : function(){
    if(!this.lamps) return;
    var _this = this;

    /// update lamps position
    for(var l = 0; l < this.lamps.length; l++){
      var lamp = this.lamps[l];
      lamp.set_position(this.location.x, this.location.y, this.location.z);
    }
  },

  _update_construction_bar : function(){
    if(!this.construction_bar) return;
    if(this.construction_percent > 0){
      this.construction_bar.update(this.location, this.construction_percent);
      if(this.components.indexOf(this.construction_bar.components[0]) == -1){
        for(var c = 0; c < this.construction_bar.components.length; c++)
          this.components.push(this.construction_bar.components[c]);
      }
    }else{
      if(this.components.indexOf(this.construction_bar.component1) != -1){
        for(var c = 0; c < this.construction_bar.components.length; c++){
          var i = this.components.indexOf(this.construction_bar.components[c]);
          this.components.splice(i, 1);
        }
      }
    }
  }
}

///////////////////////////////////////// other

/// Also gets mixed into the Station Module
Omega.StationEffectRunner = {
  run_effects : function(){
    for(var l = 0; l < this.lamps.length; l++){
      var lamp = this.lamps[l];
      lamp.run_effects();
    }
  }
}
