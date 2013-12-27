/* Omega Ship JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.Ship = function(parameters){
  this.components = [];
  this.shader_components = [];
  this.resources = [];
  $.extend(this, parameters);

  this.parent_id = this.system_id;
  this.location = Omega.convert_entity(this.location)
  this._update_resources();
};

Omega.Ship.prototype = {
  constructor: Omega.Ship,
  json_class : 'Manufactured::Ship',

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

  cmds : [
    { id      : 'ship_move_',
      class   : 'ship_move details_command',
      text    : 'move',
      handler : '_select_destination'      },

    { id      : 'ship_attack_',
      class   : 'ship_attack details_command',
      text    : 'attack',
      handler : '_select_attack_target'    },

    { id      : 'ship_dock_',
      class   : 'ship_dock details_command',
      text    : 'dock',
      handler : '_select_docking_station',
      display : function(ship){
                  return ship.docked_at_id == null;
                }                          },

    { id      : 'ship_undock_',
      class   : 'ship_undock details_command',
      text    : 'undock',
      handler : '_undock',
      display : function(ship){
                  return ship.docked_at_id != null;
                }                          },

    { id      : 'ship_transfer_',
      class   : 'ship_transfer details_command',
      text    : 'transfer',
      handler : '_transfer',
      display : function(ship){
                  return ship.docked_at_id != null;
                }                          },

    { id      : 'ship_mine_',
      class   : 'ship_mine details_command',
      text    : 'mine',
      handler : '_select_mining_target'    }],

  has_details : true,

  retrieve_details : function(page, details_cb){
    var title = 'Ship: ' + this.id;
    var loc   = '@ ' + this.location.to_s();
    var orien = '> ' + this.location.orientation_s();
    var hp    = 'HP: ' + this.hp;

    var resources = ['Resources:'];
    for(var r = 0; r < this.resources.length; r++){
      var resource = this.resources[r];
      resources.push(resource.quantity + ' of ' + resource.material_id);
    }

    var details = [title, loc, orien, hp].concat(resources);
    for(var d = 0; d < details.length; d++) details[d] += '<br/>';

    if(page.session && this.belongs_to_user(page.session.user_id)){
      var cmds = this._create_commands(page);
      details = details.concat(cmds);
    }

    details_cb(details);
  },

  _create_commands : function(page){
    var _this = this;
    var commands = [];
    for(var c = 0; c < Omega.Ship.prototype.cmds.length; c++){
      var cmd_data = {};
      $.extend(cmd_data, Omega.Ship.prototype.cmds[c]);

      var display  = (!cmd_data.display || cmd_data.display(this)) ? '' : 'none';
      $.extend(cmd_data, {id : cmd_data.id + this.id,
                          style : 'display: ' + display});

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
  /// TODO replace w/ page.command_dialog
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
    var targets = $.grep(page.all_entities(), function(e){
                    return  e.json_class == 'Manufactured::Ship'    &&
                           !e.belongs_to_user(page.session.user_id) &&
                            e.location.is_within(_this.attack_distance,
                                                 _this.location)    &&
                            e.hp > 0;
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
    var stations = $.grep(page.all_entities(), function(e){
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
          _this.docked_at_id = station.id;
          page.canvas.reload(_this, function(){
            _this.update_gfx();
          });
          page.canvas.entity_container.refresh();
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
          _this.docked_at_id = null;
          page.canvas.reload(_this, function(){
            _this.update_gfx();
          });
          page.canvas.entity_container.refresh();
        }
      });
  },

  _transfer : function(page){
    var _this = this;

    /// XXX assuming we are transferring to the docked station
    var station_id = this.docked_at_id;
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
              _this._update_resources();
              _this.docked_at.resources = dst.resources;
              _this.docked_at._update_resources();

              /// TODO also update local dst resources
              page.canvas.reload(_this, function(){
                _this.update_gfx();
              });
              page.canvas.entity_container.refresh();
            }
          });
    }
  },

  _select_mining_target : function(page){
    var _this = this;
    this.dialog().show_mining_dialog(page, this);

    var asteroids = this.solar_system.asteroids();
    asteroids = $.grep(asteroids, function(e){
                  return e.location.is_within(_this.mining_distance,
                                              _this.location);
                });
    for(var a = 0; a < asteroids.length; a++){
      var ast = asteroids[a];
      (function(ast){
        page.node.http_invoke('cosmos::get_resources', ast.id,
          function(response){
            if(!response.error){
              for(var r = 0; r < response.result.length; r++){
                var resource = response.result[r];
                _this.dialog().append_mining_cmd(page, _this, resource, ast);
              }
            }
          });
      })(ast);
    }
  },

  _start_mining : function(page, evnt){
    var _this = this;
    var resource = $(evnt.currentTarget).data('resource');
    var asteroid = $(evnt.currentTarget).data('asteroid');
    page.node.http_invoke('manufactured::start_mining', this.id,
      resource.id, function(response){
        if(response.error){
          _this.dialog().title = 'Mining Error';
          _this.dialog().show_error_dialog();
          _this.dialog().append_error(response.error.message);

        }else{
          _this.dialog().hide();
          _this.mining = resource;
          _this.mining_asteroid = asteroid;
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

  async_gfx : 3,

  load_gfx : function(config, event_cb){
    if(typeof(Omega.Ship.gfx)            === 'undefined') Omega.Ship.gfx = {};
    if(typeof(Omega.Ship.gfx[this.type]) !== 'undefined') return;
    Omega.Ship.gfx[this.type] = {};

    var texture_path    = config.url_prefix + config.images_path + config.resources.ships[this.type].material;
    var geometry_path   = config.url_prefix + config.images_path + config.resources.ships[this.type].geometry;
    var geometry_prefix = config.url_prefix + config.images_path + config.meshes_path;
    var rotation        = config.resources.ships[this.type].rotation;
    var offset          = config.resources.ships[this.type].offset;
    var scale           = config.resources.ships[this.type].scale;

    var particle_path     = config.url_prefix + config.images_path + '/particle.png';
    var particle_texture  = THREE.ImageUtils.loadTexture(particle_path, {}, event_cb);

    //// mesh
      /// each ship instance should set position of mesh
      var texture      = THREE.ImageUtils.loadTexture(texture_path, {}, event_cb);
      var material     = new THREE.MeshLambertMaterial({map: texture, overdraw: true});
      Omega.Ship.gfx[this.type].mesh_material = material;

      var _this = this;
      Omega.UI.Loader.json().load(geometry_path, function(mesh_geometry){
        var mesh = new THREE.Mesh(mesh_geometry, material);
        mesh.base_position = mesh.base_rotation = [0,0,0];
        Omega.Ship.gfx[_this.type].mesh = mesh;
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
        Omega.Ship.prototype.loaded_resource('template_mesh_' + _this.type, mesh);
        if(event_cb) event_cb();
      }, geometry_prefix);

    //// highlight effects
      /// each ship instance should set position of highlight
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
      Omega.Ship.gfx[this.type].highlight = highlight_mesh;
      Omega.Ship.gfx[this.type].nonuser_highlight_material =
        new THREE.MeshBasicMaterial({ color:0xFF0000,
                                      shading: THREE.FlatShading } );

    //// lamps
      var lamps = config.resources.ships[this.type].lamps;
      Omega.Ship.gfx[this.type].lamps = [];
      if(lamps){
        for(var l = 0; l < lamps.length; l++){
          var lamp  = lamps[l];
          var slamp = Omega.create_lamp(lamp[0], lamp[1]);
          slamp.position.set(lamp[2][0], lamp[2][1], lamp[2][2]);
          slamp.base_position = lamp[2];
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

          var plane    = this.trail_props.plane;
          var lifespan = this.trail_props.lifespan;
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
          strail.base_position = trail;
          strail.sortParticles = true;
          Omega.Ship.gfx[this.type].trails.push(strail);
        }
      }

    //// attack line
      var num_vertices = 20;
      var attack_material = new THREE.ParticleBasicMaterial({
        color: 0xFF0000, size: 20, map: particle_texture,
        blending: THREE.AdditiveBlending, transparent: true });
      var attack_geo = new THREE.Geometry();
      for(var v = 0; v < num_vertices; v++)
        attack_geo.vertices.push(new THREE.Vector3(0,0,0));
      var attack_vector = new THREE.ParticleSystem(attack_geo, attack_material);
      attack_vector.sortParticles = true;
      Omega.Ship.gfx[this.type].attack_vector = attack_vector;


    //// mining line
      var mining_material = new THREE.LineBasicMaterial({color: 0x0000FF});
      var mining_geo      = new THREE.Geometry();
      mining_geo.vertices.push(new THREE.Vector3(0,0,0));
      mining_geo.vertices.push(new THREE.Vector3(0,0,0));
      var mining_vector   = new THREE.Line(mining_geo, mining_material);
      Omega.Ship.gfx[this.type].mining_vector = mining_vector;
  },

  init_gfx : function(config, event_cb){
    if(this.components.length > 0) return; /// return if already initialized
    this.load_gfx(config, event_cb);
    this.components = [];

    var _this = this;
    Omega.Ship.prototype.retrieve_resource('template_mesh_' + this.type, function(template_mesh){
      _this.mesh = template_mesh.clone();
      // XXX so mesh materials can be independently updated:
      _this.mesh.material = Omega.Ship.gfx[_this.type].mesh_material.clone();
      /// FIXME set emissive if ship is selected upon init_gfx

      /// XXX copy custom attrs required later
      _this.mesh.base_position = template_mesh.base_position;
      _this.mesh.base_rotation = template_mesh.base_rotation;
      if(!_this.mesh.base_position) _this.mesh.base_position = [0,0,0];
      if(!_this.mesh.base_rotation) _this.mesh.base_rotation = [0,0,0];
      _this.update_gfx();

      _this.mesh.omega_entity = _this;
      _this.components.push(_this.mesh);
      _this.loaded_resource('mesh', _this.mesh);
    });

    this.highlight = Omega.Ship.gfx[this.type].highlight.clone();
    this.highlight.omega_entity = this;
    this.highlight.run_effects = Omega.Ship.gfx[this.type].highlight.run_effects; /// XXX
    if(this.location)
      this.highlight.position.add(new THREE.Vector3(this.location.x,
                                                    this.location.y,
                                                    this.location.z));
    /// TODO change highlight mesh material if ship doesn't belong to user
    this.components.push(this.highlight);

    this.lamps = [];
    for(var l = 0; l < Omega.Ship.gfx[this.type].lamps.length; l++){
      var template_lamp = Omega.Ship.gfx[this.type].lamps[l];
      var lamp = template_lamp.clone();

      /// XXX copy custom attrs required later
      lamp.base_position = template_lamp.base_position;
      lamp.run_effects = Omega.Ship.gfx[this.type].lamps[l].run_effects;

      this.lamps.push(lamp);
      this.components.push(lamp);
    }

    this.trails = [];
    for(var t = 0; t < Omega.Ship.gfx[this.type].trails.length; t++){
      var template_trail = Omega.Ship.gfx[this.type].trails[t];
      var trail = template_trail.clone();

      /// XXX copy custom attrs required later
      trail.base_position = template_trail.base_position;

      this.trails.push(trail);
    }

    this.attack_vector = Omega.Ship.gfx[this.type].attack_vector.clone();
    this.mining_vector = Omega.Ship.gfx[this.type].mining_vector.clone();

    this.update_gfx();
  },

  update_gfx : function(){
    if(!this.location) return;

    /// TODO remove components if hp == 0
    this._update_mesh();
    this._update_highlight_effects();
    this._update_lamps();
    this._update_trails();
    this._update_command_vectors();
    this._update_location_state();
    this._update_command_state();
  },
    
  _update_mesh : function(){
    if(!this.mesh) return;

    /// update mesh position and orientation
    this.mesh.position.set(this.location.x, this.location.y, this.location.z);
    this.mesh.position.add(new THREE.Vector3(this.mesh.base_position[0],
                                             this.mesh.base_position[1],
                                             this.mesh.base_position[2]));
    Omega.set_rotation(this.mesh, this.mesh.base_rotation);
    Omega.set_rotation(this.mesh, this.location.rotation_matrix());
  },

  _update_highlight_effects : function(){
    if(!this.highlight) return;

    /// update highlight effects position
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
      lamp.position.set(this.location.x, this.location.y, this.location.z);
      lamp.position.add(new THREE.Vector3(lamp.base_position[0],
                                          lamp.base_position[1],
                                          lamp.base_position[2]));
      Omega.temp_translate(lamp, this.location, function(tlamp){
        Omega.rotate_position(tlamp, _this.location.rotation_matrix());
      });
    }
  },

  _update_trails : function(){
    if(!this.trails) return;
    var _this = this;

    /// update trails position and orientation
    for(var t = 0; t < this.trails.length; t++){
      var trail = this.trails[t];
      trail.position.set(this.location.x, this.location.y, this.location.z);
      trail.position.add(new THREE.Vector3(trail.base_position[0],
                                           trail.base_position[1],
                                           trail.base_position[2]));
      if(this.mesh){
        Omega.set_rotation(trail, this.mesh.base_rotation);
      }
      Omega.set_rotation(trail, this.location.rotation_matrix());
      Omega.temp_translate(trail, this.location, function(ttrail){
        Omega.rotate_position(ttrail, _this.location.rotation_matrix());
      });
    }
  },

  _update_command_vectors : function(){
    if(!this.attack_vector || !this.mining_vector) return;

    /// update attack vector position
    this.attack_vector.position.set(this.location.x, this.location.y, this.location.z);

    /// update mining vector position
    this.mining_vector.position.set(this.location.x, this.location.y, this.location.z);
  },

  _update_location_state : function(){
    /// add/remove trails based on movement strategy
    if(!this.location || !this.location.movement_strategy ||
       !this.trails   ||  this.trails.length == 0) return;
    var stopped = "Motel::MovementStrategies::Stopped";
    var is_stopped = (this.location.movement_strategy.json_class == stopped);
    var has_trails = (this.components.indexOf(this.trails[0]) != -1);

    if(!is_stopped && !has_trails){
      for(var t = 0; t < this.trails.length; t++){
        var trail = this.trails[t];
        this.components.push(trail);
      }

    }else if(is_stopped && has_trails){
      for(var t = 0; t < this.trails.length; t++){
        var i = this.components.indexOf(this.trails[t]);
        this.components.splice(i, 1);
      }
    }
  },

  _update_command_state : function(){
    if(!this.attack_vector || !this.mining_vector) return;

    /// add/remove attack vector depending on ship state
    var has_attack_vector = this.components.indexOf(this.attack_vector) != -1;
    if(this.attacking){
      /// update attack vector properties
      var dist = this.location.distance_from(this.attacking.location.x,
                                             this.attacking.location.y,
                                             this.attacking.location.z);

      /// should be signed to preserve direction
      var dx = this.attacking.location.x - this.location.x;
      var dy = this.attacking.location.y - this.location.y;
      var dz = this.attacking.location.z - this.location.z;

      /// 5 unit particle + 55 unit spacer
      this.attack_vector.scalex = 60 / dist * dx;
      this.attack_vector.scaley = 60 / dist * dy;
      this.attack_vector.scalez = 60 / dist * dz;

      /// add attack vector if not in scene components
      if(!has_attack_vector) this.components.push(this.attack_vector);

    }else if(has_attack_vector){
      var i = this.components.indexOf(this.attack_vector);
      this.components.splice(i, 1);
    }

    /// add/remove mining vector depending on ship state
    var has_mining_vector = this.components.indexOf(this.mining_vector) != -1;
    if(this.mining && this.mining_asteroid){
      /// should be signed to preserve direction
      var dx = this.mining_asteroid.location.x - this.location.x;
      var dy = this.mining_asteroid.location.y - this.location.y;
      var dz = this.mining_asteroid.location.z - this.location.z;

      // update mining vector vertices
      this.mining_vector.geometry.vertices[0].set(0,0,0);
      this.mining_vector.geometry.vertices[1].set(dx,dy,dz);

      /// add mining vector if not in scene components
      if(!has_mining_vector) this.components.push(this.mining_vector);
        
    }else if(has_mining_vector){
      var i = this.components.indexOf(this.mining_vector);
      this.components.splice(i, 1);
    }
  },

  run_effects : function(){
    // animate lamps
    for(var l = 0; l < this.lamps.length; l++){
      var lamp = this.lamps[l];
      lamp.run_effects();
    }

    // animate trails
    var plane    = this.trail_props.plane,
        lifespan = this.trail_props.lifespan;
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

    /// move ship according to movement strategy to smoothen out movement animation
    var stopped = 'Motel::MovementStrategies::Stopped';
    var linear  = 'Motel::MovementStrategies::Linear';
    var rotate  = 'Motel::MovementStrategies::Rotate';
    var now     = new Date();
    if(this.last_moved != null){
      var elapsed = now - this.last_moved;

      if(this.location.movement_strategy.json_class == linear){
        var dist = this.location.movement_strategy.speed * elapsed / 1000;
        this.location.x += this.location.movement_strategy.dx * dist;
        this.location.y += this.location.movement_strategy.dy * dist;
        this.location.z += this.location.movement_strategy.dz * dist;
        this.update_gfx();

      }else if(this.location.movement_strategy.json_class == rotate){
        var dist = this.location.movement_strategy.rot_theta * elapsed / 1000;
        var new_or = Omega.Math.rot(this.location.orientation_x,
                                    this.location.orientation_y,
                                    this.location.orientation_z,
                                    dist,
                                    this.location.movement_strategy.rot_x,
                                    this.location.movement_strategy.rot_y,
                                    this.location.movement_strategy.rot_z);
        this.location.orientation_x = new_or[0];
        this.location.orientation_y = new_or[1];
        this.location.orientation_z = new_or[2];
        this.update_gfx();
      }
    }

    if(this.location.movement_strategy.json_class != stopped)
      this.last_moved = now;

    /// animate attack particles
    if(this.attacking){
      for(var p = 0; p < this.attack_vector.geometry.vertices.length; p++){
        var vertex = this.attack_vector.geometry.vertices[p];
        if(Math.floor( Math.random() * 20 ) == 1)
          vertex.moving = true;
        if(vertex.moving)
          vertex.add(new THREE.Vector3(this.attack_vector.scalex,
                                       this.attack_vector.scaley,
                                       this.attack_vector.scalez));

        var vertex_dist = 
          this.attacking.location.distance_from(this.location.x + vertex.x,
                                                this.location.y + vertex.y,
                                                this.location.z + vertex.z);

        /// FIXME if attack_vector.scale is large enough so that each
        /// hop exceeds 60, this check may be missed alltogether &
        /// particle will contiue to infinity
        if(vertex_dist < 60){
          vertex.set(0,0,0);
          vertex.moving = false;
        }
      }
      this.attack_vector.geometry.__dirtyVertices = true;
    }
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

// Returns ships in the specified system
Omega.Ship.under = function(system_id, node, cb){
  node.http_invoke('manufactured::get_entities',
    'of_type', 'Manufactured::Ship', 'under', system_id,
    function(response){
      var ships = [];
      if(response.result)
        for(var s = 0; s < response.result.length; s++)
          ships.push(new Omega.Ship(response.result[s]));
      cb(ships);
    });
};

Omega.UI.ResourceLoader.prototype.apply( Omega.Ship.prototype );
