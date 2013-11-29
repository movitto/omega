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
};

Omega.Station.prototype = {
  json_class : 'Manufactured::Station',

  has_details : true,

  retrieve_details : function(page, details_cb){
    var title = 'Station: ' + this.id;
    var loc   = '@ ' + this.location.to_s();

    var resources = ['Resources:'];
    for(var r = 0; r < this.resources.length; r++){
      var resource = this.resources[r];
      resources.push(resource.quantity + ' of ' + resource.material_id);
    }

    var construct_cmd = $('<span/>',
      {id    : 'station_construct_' + this.id,
       class : 'station_construct',
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

        }else{
          var station = response.result[0];
          var ship    = response.result[1]; // TODO convert ?
          page.process_entity(ship);
          if(page.canvas.root && page.canvas.root.id == ship.parent_id)
            page.canvas.add(ship);

          _this.resources = station.resources;
          page.canvas.entity_container.refresh();
        }
      });
  },

  highlight_props : {
    x     :    0, y     : 200, z     : 0,
    rot_x : 3.14, rot_y :   0, rot_z : 0
  },

  load_gfx : function(config, event_cb){
    if(typeof(Omega.Station.gfx)            === 'undefined') Omega.Station.gfx = {};
    if(typeof(Omega.Station.gfx[this.type]) !== 'undefined') return;
    Omega.Station.gfx[this.type] = {};

    var texture_path    = config.url_prefix + config.images_path + config.resources.stations[this.type].material;
    var geometry_path   = config.url_prefix + config.images_path + config.resources.stations[this.type].geometry;
    var geometry_prefix = config.url_prefix + config.images_path + config.meshes_path;
    var rotation        = config.resources.stations[this.type].geometry.rotation;
    var offset          = config.resources.stations[this.type].geometry.offset;
    var scale           = config.resources.stations[this.type].geometry.scale;

    //// mesh
      /// each station instance should set position of mesh
      var texture      = THREE.ImageUtils.loadTexture(texture_path, {}, event_cb);
      var material     = new THREE.MeshLambertMaterial({map: texture, overdraw: true});

      var _this = this;
      new THREE.JSONLoader().load(geometry_path, function(mesh_geometry){
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
        Omega.Station.prototype.dispatchEvent({type: 'loaded_template_mesh', data: mesh});
        event_cb();
      }, geometry_prefix);

    //// highlight effects
      /// each station instance should set position of mesh
      var highlight_geometry = new THREE.CylinderGeometry( 0, 40, 80, 8, 2 );
      var highlight_material = new THREE.MeshBasicMaterial({ color:0x33ff33,
                                                             shading: THREE.FlatShading } );
      var highlight_mesh     = new THREE.Mesh(highlight_geometry, highlight_material);
      highlight_mesh.position.set(Omega.Station.prototype.highlight_props.x,
                                  Omega.Station.prototype.highlight_props.y,
                                  Omega.Station.prototype.highlight_props.z);
      highlight_mesh.rotation.set(Omega.Station.prototype.highlight_props.rot_x,
                                  Omega.Station.prototype.highlight_props.rot_y,
                                  Omega.Station.prototype.highlight_props.rot_z);
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

  /// invoked cb when resource is loaded, or immediately if resource is already loaded
  retrieve_resource : function(type, resource, cb){
    if(!cb && typeof(resource) === "function"){ /// XXX
       cb = resource; resource = type;
    }

    switch(resource){
      case 'template_mesh':
        if(Omega.Station.gfx[type] && Omega.Station.gfx[type].mesh){
          cb(Omega.Station.gfx[type].mesh);
          return;
        }
        break;
      case 'mesh':
        if(this.mesh){
          cb(this.mesh);
          return;
        }
        break;
    }

    var _this = this;
    this.addEventListener('loaded_' + resource, function(evnt){
      if(evnt.target == _this) /// event interface defined on prototype, need to distinguish instances
        cb(evnt.data);
    });
  },

  init_gfx : function(config, event_cb){
    if(this.components.length > 0) return; /// return if already initialized
    this.load_gfx(config, event_cb);

    var _this = this;
    Omega.Station.prototype.retrieve_resource(this.type, 'template_mesh', function(){
      _this.mesh = Omega.Station.gfx[_this.type].mesh.clone();
      if(_this.location)
        _this.mesh.position.set(_this.location.x,
                                _this.location.y,
                                _this.location.z);
      _this.mesh.omega_entity = _this;
      _this.dispatchEvent({type: 'loaded_mesh', data: _this.mesh});
    });

    this.highlight = Omega.Station.gfx[this.type].highlight.clone();
    this.highlight.run_effects = Omega.Station.gfx[this.type].highlight.run_effects; /// XXX
    if(this.location) this.highlight.position.set(this.location.x, this.location.y, this.location.z);

    this.components = [this.mesh, this.highlight];

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

THREE.EventDispatcher.prototype.apply( Omega.Station.prototype );
