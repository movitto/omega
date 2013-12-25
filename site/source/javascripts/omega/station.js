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
  this.location = Omega.convert_entity(this.location)
  this._update_resources();

  this.hp = 100; /// XXX interim compatability hack
};

Omega.Station.prototype = {
  constructor: Omega.Station,
  json_class : 'Manufactured::Station',

  belongs_to_user : function(user_id){
    return this.user_id == user_id;
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
    var title = 'Station: ' + this.id;
    var loc   = '@ ' + this.location.to_s();

    var resources = ['Resources:'];
    for(var r = 0; r < this.resources.length; r++){
      var resource = this.resources[r];
      resources.push(resource.quantity + ' of ' + resource.material_id);
    }

    /// TODO do not display if ship does not belong to current user:
    var _this = this;
    var construct_cmd = $('<span/>',
      {id    : 'station_construct_' + this.id,
       class : 'station_construct details_command',
       text  : 'construct'})
     construct_cmd.data('station', this);
     construct_cmd.click(function(){ _this._construct(page); });

    var details = [title, loc].concat(resources);
    for(var d = 0; d < details.length; d++) details[d] += '<br/>';
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
          var slamp = Omega.create_lamp(lamp[0], lamp[1]);
          slamp.position.set(lamp[2][0], lamp[2][1], lamp[2][2]);
          Omega.Station.gfx[this.type].lamps.push(slamp);
        }
      }
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
      lamp.run_effects = Omega.Station.gfx[this.type].lamps[l].run_effects; /// XXX
      if(this.location)
        lamp.position.add(new THREE.Vector3(this.location.x,
                                            this.location.y,
                                            this.location.z));
      this.lamps.push(lamp);
      this.components.push(lamp);
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
      cb(stations);
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
      cb(stations);
    });
};

Omega.UI.ResourceLoader.prototype.apply( Omega.Station.prototype );
