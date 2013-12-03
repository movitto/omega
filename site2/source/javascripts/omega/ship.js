/* Omega Ship JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

/// TODO orientations, updates on movement/rotation/attack/defense/mining
/// TODO remove components if hp == 0

Omega.Ship = function(parameters){
  this.components = [];
  this.shader_components = [];

  this.location  = new Omega.Location({x:0,y:0,z:0});
  this.resources = [];
  $.extend(this, parameters);
};

Omega.Ship.prototype = {
  json_class : 'Manufactured::Ship',

  belongs_to_user : function(user_id){
    return this.user_id == user_id;
  },

  cmds : [
    { id      : 'ship_move_',
      class   : 'ship_move',
      text    : 'move',
      handler : '_select_destination'      },

    { id      : 'ship_attack_',
      class   : 'ship_attack',
      text    : 'attack',
      handler : '_select_attack_target'    },

    { id      : 'ship_dock_',
      class   : 'ship_dock',
      text    : 'dock',
      handler : '_select_docking_station'  },

    { id      : 'ship_undock_',
      class   : 'ship_undock',
      text    : 'undock',
      handler : '_undock'                  },

    { id      : 'ship_transfer_',
      class   : 'ship_transfer',
      text    : 'transfer',
      handler : '_transfer'                },

    { id      : 'ship_mine_',
      class   : 'ship_mine',
      text    : 'mine',
      handler : '_select_mining_target'    }],

  has_details : true,

  retrieve_details : function(page, details_cb){
    var title = 'Ship: ' + this.id;
    var loc   = '@ ' + this.location.to_s();

    var resources = ['Resources:'];
    for(var r = 0; r < this.resources.length; r++){
      var resource = this.resources[r];
      resources.push(resource.quantity + ' of ' + resource.material_id);
    }

    var cmds = this._create_commands(page);
    var details = [title, loc].concat(resources);
    for(var d = 0; d < details.length; d++) details[d] += '<br/>';
    details = details.concat(cmds);
    details_cb(details);
  },

  _create_commands : function(page){
    var _this = this;
    var commands = [];
    for(var c = 0; c < Omega.Ship.prototype.cmds.length; c++){
      var cmd_data = {};
      $.extend(cmd_data, Omega.Ship.prototype.cmds[c]);
      $.extend(cmd_data, {id : cmd_data.id + this.id});

      var cmd = $('<span/>', cmd_data);
      cmd.data('ship', this);
      cmd.data('handler', cmd_data.handler)
      cmd.click(function(evnt){
        var handler = $(evnt.currentTarget).data('handler');
        _this[handler](page);
      });
      commands.push(cmd);
    }

    return commands;
  },

  selected : function(page){
    if(this.mesh) this.mesh.material.emissive.setHex(0xff0000);
  },

  unselected : function(page){
    if(this.mesh) this.mesh.material.emissive.setHex(0);
  },

  /// XXX not a big fan of having this here, should eventually be moved elsewhere
  dialog : function(){
    if(typeof(this._dialog) === "undefined")
      this._dialog = new Omega.UI.CommandDialog();
    return this._dialog;
  },

  _select_destination : function(page){
    this.dialog().show_destination_selection_dialog(page, this);
  },

  _move : function(page, x, y, z){
    var _this = this;
    var nloc = this.location.clone();
    nloc.x = x; nloc.y = y; nloc.z = z;
    page.node.http_invoke('manufactured::move_entity', this.id, nloc,
      function(response){
        if(response.error){
          _this.dialog().title = 'Movement Error';
          _this.dialog().show_error_dialog();
          _this.dialog().append_error(response.error.message);

        }else{
          _this.dialog().hide();
          _this.location.movement_strategy = response.result.location.movement_strategy;
          page.canvas.reload(_this, function(){
            _this.update_gfx();
          });
        }
      });
  },

  _select_attack_target : function(page){
    var _this = this;
    var targets = $.grep(page.entities, function(e){
                    return  e.json_class == 'Manufactured::Ship'    &&
                           !e.belongs_to_user(page.session.user_id) &&
                            e.location.is_within(_this.attack_distance,
                                                 _this.location);
                  });
    this.dialog().show_attack_dialog(page, this, targets);
  },

  _start_attacking : function(page, evnt){
    var _this = this;
    var target = $(evnt.currentTarget).data('target');
    page.node.http_invoke('manufactured::attack_entity', this.id, target.id,
      function(response){
        if(response.error){
          _this.dialog().title = 'Attack Error';
          _this.dialog().show_error_dialog();
          _this.dialog().append_error(response.error.message);

        }else{
          _this.dialog().hide();
          _this.attacking = target;
          page.canvas.reload(_this, function(){
            _this.update_gfx();
          });
        }
      });
  },

  _select_docking_station : function(page){
    var _this = this;
    var stations = $.grep(page.entities, function(e){
                     return e.json_class == 'Manufactured::Station' &&
                            e.belongs_to_user(page.session.user_id) &&
                            _this.location.is_within(e.docking_distance,
                                                     e.location);
                   });
    this.dialog().show_docking_dialog(page, this, stations);
  },

  _dock : function(page, evnt){
    var _this = this;
    var station = $(evnt.currentTarget).data('station');
    page.node.http_invoke('manufactured::dock', this.id, station.id,
      function(response){
        if(response.error){
          _this.dialog().title = 'Docking Error';
          _this.dialog().show_error_dialog();
          _this.dialog().append_error(response.error.message);

        }else{
          _this.dialog().hide();
          _this.docked_at = station;
          page.canvas.reload(_this, function(){
            _this.update_gfx();
          });
        }
      });
  },

  _undock : function(page){
    var _this = this;
    page.node.http_invoke('manufactured::undock', this.id,
      function(response){
        if(response.error){
          _this.dialog().title = 'Undocking Error';
          _this.dialog().show_error_dialog();
          _this.dialog().append_error(response.error.message);
        }else{
          _this.docked_at = null;
          page.canvas.reload(_this, function(){
            _this.update_gfx();
          });
        }
      });
  },

  _transfer : function(page){
    var _this = this;

    /// XXX assuming we are transferring to the docked station
    var station_id = this.docked_to_id;
    for(var r = 0; r < this.resources.length; r++){
      page.node.http_invoke('manufactured::transfer_resource',
        this.id, station_id, this.resources[r],
          function(response){
            if(response.error){
              _this.dialog().title = 'Transfer Error';
              _this.dialog().show_error_dialog();
              _this.dialog().append_error(response.error.message);

            }else{
              var src = response.result[0];
              var dst = response.result[1];
              _this.resources = src.resources;
              /// TODO also update local dst resources
              page.canvas.reload(_this, function(){
                _this.update_gfx();
              });
            }
          });
    }
  },

  _select_mining_target : function(page){
    var _this = this;
    this.dialog().show_mining_dialog(page, this);

    var asteroids = $.grep(page.entities, function(e){
                      return e.json_class == 'Cosmos::Entities::Asteroid' &&
                             e.location.is_within(_this.mining_distance,
                                                  _this.location);
                    });
    for(var a = 0; a < asteroids.length; a++){
      var ast = asteroids[a];
      page.node.http_invoke('cosmos::get_resources', ast.id,
        function(response){
          if(!response.error){
            for(var r = 0; r < response.result.length; r++){
              var resource = response.result[r];
              _this.dialog().append_mining_cmd(page, _this, resource);
            }
          }
        });
    }
  },

  _start_mining : function(page, evnt){
    var _this = this;
    var resource = $(evnt.currentTarget).data('resource');
    page.node.http_invoke('manufactured::start_mining', this.id,
      resource.id, function(response){
        if(response.error){
          _this.dialog().title = 'Mining Error';
          _this.dialog().show_error_dialog();
          _this.dialog().append_error(response.error.message);

        }else{
          _this.dialog().hide();
          _this.mining = response.result.mining;
          page.canvas.reload(_this, function(){
            _this.update_gfx();
          });
        }
      });
  },

  highlight_props : {
    x     :    0, y     : 200, z     : 0,
    rot_x : 3.14, rot_y :   0, rot_z : 0
  },

  trail_props : {
    plane : 3, lifespan : 20
  },

  load_gfx : function(config, event_cb){
    if(typeof(Omega.Ship.gfx)            === 'undefined') Omega.Ship.gfx = {};
    if(typeof(Omega.Ship.gfx[this.type]) !== 'undefined') return;
    Omega.Ship.gfx[this.type] = {};

    var texture_path    = config.url_prefix + config.images_path + config.resources.ships[this.type].material;
    var geometry_path   = config.url_prefix + config.images_path + config.resources.ships[this.type].geometry;
    var geometry_prefix = config.url_prefix + config.images_path + config.meshes_path;
    var rotation        = config.resources.ships[this.type].geometry.rotation;
    var offset          = config.resources.ships[this.type].geometry.offset;
    var scale           = config.resources.ships[this.type].geometry.scale;

    var particle_path     = config.url_prefix + config.images_path + '/particle.png';
    var particle_texture  = THREE.ImageUtils.loadTexture(particle_path, {}, event_cb);

    //// mesh
      /// each ship instance should set position of mesh
      var texture      = THREE.ImageUtils.loadTexture(texture_path, {}, event_cb);
      var material     = new THREE.MeshLambertMaterial({map: texture, overdraw: true});

      var _this = this;
      new THREE.JSONLoader().load(geometry_path, function(mesh_geometry){
        var mesh = new THREE.Mesh(mesh_geometry, material);
        Omega.Ship.gfx[_this.type].mesh = mesh;
        if(offset)
          mesh.position.set(offset[0], offset[1], offset[2]);
        if(scale)
          mesh.scale.set(scale[0], scale[1], scale[2]);
        if(rotation){
          mesh.rotation.set(rotation[0], rotation[1], rotation[2]);
          mesh.matrix.makeRotationFromEuler(mesh.rotation);
        }
        Omega.Ship.prototype.dispatchEvent({type: 'loaded_template_mesh', data: mesh});
        event_cb();
      }, geometry_prefix);

    //// highlight effects
      /// each ship instance should set position of mesh
      var highlight_geometry = new THREE.CylinderGeometry( 0, 40, 80, 8, 2 );
      var highlight_material = new THREE.MeshBasicMaterial({ color:0x33ff33,
                                                             shading: THREE.FlatShading } );
      var highlight_mesh     = new THREE.Mesh(highlight_geometry, highlight_material);
      highlight_mesh.position.set(Omega.Ship.prototype.highlight_props.x,
                                  Omega.Ship.prototype.highlight_props.y,
                                  Omega.Ship.prototype.highlight_props.z);
      highlight_mesh.rotation.set(Omega.Ship.prototype.highlight_props.rot_x,
                                  Omega.Ship.prototype.highlight_props.rot_y,
                                  Omega.Ship.prototype.highlight_props.rot_z);
      Omega.Ship.gfx[this.type].highlight = highlight_mesh;

    //// lamps
      var lamps = config.resources.ships[this.type].lamps;
      Omega.Ship.gfx[this.type].lamps = [];
      if(lamps){
        for(var l = 0; l < lamps.length; l++){
          var lamp  = lamps[l];
          var slamp = Omega.create_lamp(lamp[0], lamp[1]);
          slamp.position.set(lamp[2][0], lamp[2][1], lamp[2][2]);
          Omega.Ship.gfx[this.type].lamps.push(slamp);
        }
      }

    //// trails
      var trails = config.resources.ships[this.type].trails;
      Omega.Ship.gfx[this.type].trails = [];
      if(trails){
        var trail_material = new THREE.ParticleBasicMaterial({
          color: 0xFFFFFF, size: 20, map: particle_texture,
          blending: THREE.AdditiveBlending, transparent: true });

        for(var l = 0; l < trails.length; l++){
          var trail = trails[l];
          var geo   = new THREE.Geometry();

          var plane    = Omega.Ship.prototype.trail_props.plane;
          var lifespan = Omega.Ship.prototype.trail_props.lifespan;
          for(var i = 0; i < plane; ++i){
            for(var j = 0; j < plane; ++j){
              var pv = new THREE.Vector3(i, j, 0);
              pv.velocity = Math.random();
              pv.lifespan = Math.random() * lifespan;
              if(i >= plane / 4 && i <= 3 * plane / 4 &&
                 j >= plane / 4 && j <= 3 * plane / 4 ){
                   pv.lifespan *= 2;
                   pv.velocity *= 2;
              }
              pv.olifespan = pv.lifespan;
              geo.vertices.push(pv)
            }
          }

          var strail = new THREE.ParticleSystem(geo, trail_material);
          strail.position.set(trail[0], trail[1], trail[2]);
          strail.sortParticles = true;
          Omega.Ship.gfx[this.type].trails.push(strail);
        }
      }

    //// attack line
      var attack_material = new THREE.ParticleBasicMaterial({
        color: 0xFF0000, size: 20, map: particle_texture,
        blending: THREE.AdditiveBlending, transparent: true });
      var attack_geo = new THREE.Geometry();
      var attack_vector = new THREE.ParticleSystem(attack_geo, attack_material);
      attack_vector.sortParticles = true;
      Omega.Ship.gfx[this.type].attack_vector = attack_vector;


    //// mining line
      var mining_material = new THREE.LineBasicMaterial({color: 0x0000FF});
      var mining_geo      = new THREE.Geometry();
      var mining_vector   = new THREE.Line(mining_geo, mining_material);
      Omega.Ship.gfx[this.type].mining_vector = mining_vector;
  },

  /// invoked cb when resource is loaded, or immediately if resource is already loaded
  retrieve_resource : function(type, resource, cb){
    if(!cb && typeof(resource) === "function"){ /// XXX
       cb = resource; resource = type;
    }

    switch(resource){
      case 'template_mesh':
        if(Omega.Ship.gfx[type] && Omega.Ship.gfx[type].mesh){
          cb(Omega.Ship.gfx[type].mesh);
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
    Omega.Ship.prototype.retrieve_resource(this.type, 'template_mesh', function(){
      _this.mesh = Omega.Ship.gfx[_this.type].mesh.clone();
      if(_this.location)
        _this.mesh.position.set(_this.location.x,
                                _this.location.y,
                                _this.location.z);
      _this.mesh.omega_entity = _this;
      _this.dispatchEvent({type: 'loaded_mesh', data: _this.mesh});
    });

    this.highlight = Omega.Ship.gfx[this.type].highlight.clone();
    this.highlight.run_effects = Omega.Ship.gfx[this.type].highlight.run_effects; /// XXX
    if(this.location) this.highlight.position.set(this.location.x, this.location.y, this.location.z);

    this.components = [this.mesh, this.highlight];

    this.lamps = [];
    for(var l = 0; l < Omega.Ship.gfx[this.type].lamps.length; l++){
      var lamp = Omega.Ship.gfx[this.type].lamps[l].clone();
      lamp.run_effects = Omega.Ship.gfx[this.type].lamps[l].run_effects; /// XXX
      if(this.location)
        lamp.position.add(new THREE.Vector3(this.location.x,
                                            this.location.y,
                                            this.location.z));
      this.lamps.push(lamp);
      this.components.push(lamp);
    }

    this.trails = [];
    for(var t = 0; t < Omega.Ship.gfx[this.type].trails.length; t++){
      var trail = Omega.Ship.gfx[this.type].trails[t].clone();
      if(this.location)
        trail.position.add(new THREE.Vector3(this.location.x,
                                             this.location.y,
                                             this.location.z));
      this.trails.push(trail);
    }

    this.attack_vector = Omega.Ship.gfx[this.type].attack_vector.clone();
    if(this.location) this.attack_vector.position.set(this.location.x,
                                                      this.location.y,
                                                      this.location.z);

    this.mining_vector = Omega.Ship.gfx[this.type].mining_vector.clone();
    if(this.location) this.mining_vector.position.set(this.location.x,
                                                      this.location.y,
                                                      this.location.z);
  },

/// TODO
  update_gfx : function(){
  },

  run_effects : function(){
    // animate lamps
    for(var l = 0; l < this.lamps.length; l++){
      var lamp = this.lamps[l];
      lamp.run_effects();
    }

    // animate trails
    var plane    = Omega.Ship.prototype.trail_props.plane,
        lifespan = Omega.Ship.prototype.trail_props.lifespan;
    for(var t = 0; t < this.trails.length; t++){
      var trail = this.trails[t];
      var p = plane*plane;
      while(p--){
        var pv = trail.geometry.vertices[p]
        pv.z -= pv.velocity;
        pv.lifespan -= 1;
        if(pv.lifespan < 0){
          pv.z = 0;
          pv.lifespan = pv.olifespan;
        }
      }
      trail.geometry.__dirtyVertices = true;
    }

    /// TODO animate attack particles
  }
};

// Return ship with the specified id
Omega.Ship.get = function(ship_id, node, cb){
  node.http_invoke('manufactured::get_entity', 'with_id', ship_id,
    function(response){
      var ship = null;
      var err  = null;
      if(response.result)
        ship = new Omega.Ship(response.result);
      else if(response.error)
        err = response.error.message;
      cb(ship, err);
    });
}

// Return ships owned by the specified user
Omega.Ship.owned_by = function(user_id, node, cb){
  node.http_invoke('manufactured::get_entities',
    'of_type', 'Manufactured::Ship', 'owned_by', user_id,
    function(response){
      var ships = [];
      if(response.result)
        for(var e = 0; e < response.result.length; e++)
          ships.push(new Omega.Ship(response.result[e]));
      cb(ships);
    });
}

THREE.EventDispatcher.prototype.apply( Omega.Ship.prototype );
