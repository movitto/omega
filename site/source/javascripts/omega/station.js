/* Omega Station JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.Station = function(parameters){
  this.components = [];
  this.shader_components = [];
  this.resources  = [];
  $.extend(this, parameters);

  this.parent_id = this.system_id;
  this.location = Omega.convert_entity(this.location)
  this._update_resources();
};

Omega.Station.prototype = {
  constructor: Omega.Station,
  json_class : 'Manufactured::Station',

  belongs_to_user : function(user_id){
    return this.user_id == user_id;
  },

  alive : function(){
    /// XXX interim compatability hack
    return true;
  },

  update_system : function(new_system){
    this.solar_system = new_system;
    if(new_system){
      this.system_id    = new_system.id;
      this.parent_id    = new_system.id;
    }
  },

  in_system : function(system_id){
    return this.system_id == system_id;
  },

  _update_resources : function(){
    if(this.resources){
      for(var r = 0; r < this.resources.length; r++){
        var res = this.resources[r];
        if(res.data)  $.extend(res, res.data);
      }
    }
  },

  has_details : true,

  retrieve_details : function(page, details_cb){
    /// TODO also construction percentage
    var title = 'Station: ' + this.id;
    var loc   = '@ ' + this.location.to_s();

    var resources = ['Resources:'];
    for(var r = 0; r < this.resources.length; r++){
      var resource = this.resources[r];
      resources.push(resource.quantity + ' of ' + resource.material_id);
    }

    var _this = this;
    var construct_cmd = $('<span/>',
      {id    : 'station_construct_' + this.id,
       class : 'station_construct details_command',
       text  : 'construct'})
     construct_cmd.data('station', this);
     construct_cmd.click(function(){ _this._construct(page); });

    var details = [title, loc].concat(resources);
    for(var d = 0; d < details.length; d++) details[d] += '<br/>';
    if(page.session && this.belongs_to_user(page.session.user_id))
      details.push(construct_cmd);
    details_cb(details);
  },

  selected : function(page){
    if(this.mesh) this.mesh.material.emissive.setHex(0xff0000);
  },

  unselected : function(page){
    if(this.mesh) this.mesh.material.emissive.setHex(0);
  },

  // XXX not a big fan of having this here, should eventually be moved elsewhere
  dialog : function(){
    if(typeof(this._dialog) === "undefined")
      this._dialog = new Omega.UI.CommandDialog();
    return this._dialog;
  },

  _construct : function(page){
    var _this = this;

    /// TODO parameterize entity type/init!
    /// TODO generate random location in vicity of station and/or allow user
    /// to set a generation point around which new entities appear (within
    /// construction distance of station of course)
    page.node.http_invoke('manufactured::construct_entity',
      this.id, 'entity_type', 'Ship', 'type', 'mining', 'id', RJR.guid(),
      function(response){
        if(response.error){
          _this.dialog().title = 'Construction Error';
          _this.dialog().show_error_dialog();
          _this.dialog().append_error(response.error.message);

        }//else{
           /// entity added to scene, resources updated, entity_container
           /// refreshed and other operations done in construction event callbacks
           //var station = response.result[0];
           //var ship    = response.result[1];
         //}
      });
  },

  highlight_props : {
    x     :    0, y     : 200, z     : 0,
    rot_x : 3.14, rot_y :   0, rot_z : 0
  },

  construction_bar_props : {
    length: 200
  },

  async_gfx : 2,

  load_gfx : function(config, event_cb){
    if(typeof(Omega.Station.gfx)            === 'undefined') Omega.Station.gfx = {};
    if(typeof(Omega.Station.gfx[this.type]) !== 'undefined') return;
    Omega.Station.gfx[this.type] = {};

    var texture_path    = config.url_prefix + config.images_path + config.resources.stations[this.type].material;
    var geometry_path   = config.url_prefix + config.images_path + config.resources.stations[this.type].geometry;
    var geometry_prefix = config.url_prefix + config.images_path + config.meshes_path;
    var rotation        = config.resources.stations[this.type].rotation;
    var offset          = config.resources.stations[this.type].offset;
    var scale           = config.resources.stations[this.type].scale;

    //// mesh
      /// each station instance should set position of mesh
      var texture      = THREE.ImageUtils.loadTexture(texture_path, {}, event_cb);
      var material     = new THREE.MeshLambertMaterial({map: texture, overdraw: true});

      var _this = this;
      Omega.UI.Loader.json().load(geometry_path, function(mesh_geometry){
        var mesh = new THREE.Mesh(mesh_geometry, material);
        Omega.Station.gfx[_this.type].mesh = mesh;
        if(offset)
          mesh.position.set(offset[0], offset[1], offset[2]);
        if(scale)
          mesh.scale.set(scale[0], scale[1], scale[2]);
        if(rotation){
          mesh.rotation.set(rotation[0], rotation[1], rotation[2]);
          mesh.matrix.makeRotationFromEuler(mesh.rotation);
        }
        Omega.Station.prototype.loaded_resource('template_mesh_' + _this.type, mesh);
        if(event_cb) event_cb();
      }, geometry_prefix);

    //// highlight effects
      /// each station instance should set position of mesh
      var highlight_geometry = new THREE.CylinderGeometry( 0, 40, 80, 8, 2 );
      var highlight_material = new THREE.MeshBasicMaterial({ color:0x33ff33,
                                                             shading: THREE.FlatShading } );
      var highlight_mesh     = new THREE.Mesh(highlight_geometry, highlight_material);
      highlight_mesh.position.set(this.highlight_props.x,
                                  this.highlight_props.y,
                                  this.highlight_props.z);
      highlight_mesh.rotation.set(this.highlight_props.rot_x,
                                  this.highlight_props.rot_y,
                                  this.highlight_props.rot_z);
      Omega.Station.gfx[this.type].highlight = highlight_mesh;

    //// lamps
      var lamps = config.resources.stations[this.type].lamps;
      Omega.Station.gfx[this.type].lamps = [];
      if(lamps){
        for(var l = 0; l < lamps.length; l++){
          var lamp  = lamps[l];
          var slamp = new Omega.UI.CanvasLamp({size : lamp[0],
                                               color: lamp[1],
                                      base_position : lamp[2]});
          Omega.Station.gfx[this.type].lamps.push(slamp);
        }
      }

    //// construction bar
      var len = this.construction_bar_props.length;
      Omega.Station.gfx[this.type].construction_bar =
        new Omega.UI.CanvasProgressBar({
          width: 3, length: len, axis : 'x',
          color1: 0x00FF00, color2: 0x0000FF,
          vertices: [[[-len/2, 100, 0],
                      [-len/2, 100, 0]],
                     [[-len/2, 100, 0],
                      [ len/2, 100, 0]]]});
      //Omega.Station.gfx[this.type].construction_bar.load_gfx(config, event_cb);
  },

  init_gfx : function(config, event_cb){
    if(this.components.length > 0) return; /// return if already initialized
    this.load_gfx(config, event_cb);

    this.components = [];

    var _this = this;
    Omega.Station.prototype.retrieve_resource('template_mesh_' + this.type, function(template_mesh){
      _this.mesh = template_mesh.clone();
      if(_this.location)
        _this.mesh.position.set(_this.location.x,
                                _this.location.y,
                                _this.location.z);
      _this.mesh.omega_entity = _this;
      _this.components.push(_this.mesh);
      _this.loaded_resource('mesh', _this.mesh);
    });

    this.highlight = Omega.Station.gfx[this.type].highlight.clone();
    this.highlight.omega_entity = this;
    this.highlight.run_effects = Omega.Station.gfx[this.type].highlight.run_effects; /// XXX
    this.highlight.position.set(this.highlight_props.x,
                                this.highlight_props.y,
                                this.highlight_props.z);
    if(this.location)
      this.highlight.position.add(new THREE.Vector3(this.location.x,
                                                    this.location.y,
                                                    this.location.z));


    this.components.push(this.highlight);

    this.lamps = [];
    for(var l = 0; l < Omega.Station.gfx[this.type].lamps.length; l++){
      var lamp = Omega.Station.gfx[this.type].lamps[l].clone();
      lamp.init_gfx();
      if(this.location)
        lamp.set_position(this.location.x, this.location.y, this.location.z);
      this.lamps.push(lamp);
      this.components.push(lamp.component);
    }

    this.construction_bar = Omega.Station.gfx[this.type].construction_bar.clone();
    this.construction_bar.init_gfx(config, event_cb);
  },

  cp_gfx : function(from){
    /// return if not initialized
    if(!from.components || from.components.length == 0) return;

    this.components        = from.components;
    this.shader_components = from.shader_components;
    this.mesh              = from.mesh;
    this.highlight         = from.highlight;
    this.lamps             = from.lamps;
    this.construction_bar  = from.construction_bar;
  },

  update_gfx : function(){
    if(!this.location) return;

    this._update_construction_bar();
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
  },

  run_effects : function(){
    for(var l = 0; l < this.lamps.length; l++){
      var lamp = this.lamps[l];
      lamp.run_effects();
    }
  }
};

// Return stations owned by the specified user
Omega.Station.owned_by = function(user_id, node, cb){
  node.http_invoke('manufactured::get_entities',
    'of_type', 'Manufactured::Station', 'owned_by', user_id,
    function(response){
      var stations = [];
      if(response.result)
        for(var e = 0; e < response.result.length; e++)
          stations.push(new Omega.Station(response.result[e]));
      if(cb) cb(stations);
    });
}

// Returns stations in the specified system
Omega.Station.under = function(system_id, node, cb){
  node.http_invoke('manufactured::get_entities',
    'of_type', 'Manufactured::Station', 'under', system_id,
    function(response){
      var stations = [];
      if(response.result)
        for(var s = 0; s < response.result.length; s++)
          stations.push(new Omega.Station(response.result[s]));
      if(cb) cb(stations);
    });
};

Omega.UI.ResourceLoader.prototype.apply( Omega.Station.prototype );
