/* Omega JumpGate JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/command"

Omega.JumpGate = function(parameters){
  this.components = [];
  this.shader_components = [];
  $.extend(this, parameters);

  this.location = Omega.convert_entity(this.location)
};

Omega.JumpGate.prototype = {
  constructor : Omega.JumpGate,
  json_class : 'Cosmos::Entities::JumpGate',

  has_details : true,

  retrieve_details : function(page, details_cb){
    var title = 'Jump Gate to ' + this.endpoint_id;
    var loc   = '@ ' + this.location.to_s();
    var trigger_cmd   = $('<span/>',
      {id    : 'trigger_jg_' + this.id,
       class : 'trigger_jg details_command',
       text  : 'trigger'});
    trigger_cmd.data('jump_gate', this);

    var _this = this;
    trigger_cmd.click(function(){ _this._trigger(page); });

    var details = [title + '<br/>' + loc + '<br/><br/>', trigger_cmd];
    details_cb(details);
  },

  selected : function(page){
    var _this = this;
    page.canvas.reload(this, function(){
      if($.inArray(_this.selection_sphere, _this.components) == -1)
        _this.components.push(_this.selection_sphere);
    });
  },

  unselected : function(page){
    var _this = this;
    page.canvas.reload(this, function(){
      var index;
      if((index = $.inArray(_this.selection_sphere, _this.components)) != -1)
        _this.components.splice(index, 1);
    });
  },

  // XXX not a big fan of having this here, should eventually be moved elsewhere
  dialog : function(){
    if(typeof(this._dialog) === "undefined")
      this._dialog = new Omega.UI.CommandDialog(); 
    return this._dialog;
  },

  _trigger : function(page){
    var _this = this;
    var ships = $.grep(page.all_entities(), function(e){
                  return _this._should_trigger_ship(e, page);
                });

    for(var s = 0; s < ships.length; s++){
      var ship = ships[s];
      (function(ship){ /// XXX need new scope to preserve ship
        /// XXX make sure endpoint is set! (won't come in w/ server jg)
        ship.location.parent_id = _this.endpoint.location.id;
        page.node.http_invoke('manufactured::move_entity', ship.id, ship.location,
          function(response){
            if(response.error){
              _this.dialog().title = 'Jump Gate Trigger Error';
              _this.dialog().show_error_dialog();
              _this.dialog().append_error(response.error.message);

            }else{
              ship.system_id = _this.endpoint_id;
              page.canvas.remove(ship);
            }
          });
       })(ship);
    }
  },

  _should_trigger_ship : function(entity, page){
    return entity.json_class == 'Manufactured::Ship' &&
           entity.belongs_to_user(page.session.user_id) &&
           entity.location.is_within(this.trigger_distance,
                                     this.location);
  },

  gfx_props : {
    particle_plane :  20,
    particle_life  : 200,
    lamp_x         : -22,
    lamp_y         : -17,
    lamp_z         : 175,
  },

  async_gfx : 3,

  load_gfx : function(config, event_cb){
    if(typeof(Omega.JumpGate.gfx) !== 'undefined') return;
    Omega.JumpGate.gfx = {};

    //// mesh
      var texture_path    = config.url_prefix + config.images_path + config.resources.jump_gate.material;
      var geometry_path   = config.url_prefix + config.images_path + config.resources.jump_gate.geometry;
      var geometry_prefix = config.url_prefix + config.images_path + config.meshes_path;
      var rotation        = config.resources.jump_gate.rotation;
      var offset          = config.resources.jump_gate.offset;
      var scale           = config.resources.jump_gate.scale;

      var texture         = THREE.ImageUtils.loadTexture(texture_path, {}, event_cb);
      texture.wrapS       = texture.wrapT    = THREE.RepeatWrapping;
      texture.repeat.x    = texture.repeat.y = 5;
      var mesh_material   = new THREE.MeshLambertMaterial({ map: texture });

      Omega.UI.Loader.json().load(geometry_path, function(mesh_geometry){
        var mesh = new THREE.Mesh(mesh_geometry, mesh_material);
        Omega.JumpGate.gfx.mesh = mesh;
        if(offset)
          mesh.position.set(offset[0], offset[1], offset[2]);
        if(scale)
          mesh.scale.set(scale[0], scale[1], scale[2]);
        if(rotation){
          mesh.rotation.set(rotation[0], rotation[1], rotation[2]);
          mesh.matrix.makeRotationFromEuler(mesh.rotation);
        }
        Omega.JumpGate.prototype.loaded_resource('template_mesh', mesh);
        if(event_cb) event_cb();
      }, geometry_prefix);

    //// lamp
      Omega.JumpGate.gfx.lamp = Omega.create_lamp(10, 0xff0000);

    //// particles
      var particle_path = config.url_prefix + config.images_path + "/particle.png";
      var texture       = THREE.ImageUtils.loadTexture(particle_path, {}, event_cb);
      var lifespan      = this.gfx_props.particle_life,
          plane         = this.gfx_props.particle_plane;
      var particles_material =
        new THREE.ParticleBasicMaterial({
          color: 0x0000FF, size        : 20,
          map  : texture,  transparent : true,
          blending: THREE.AdditiveBlending
        });

      var particles = new THREE.Geometry();
      for(var i = 0; i < plane; ++i){
        for(var j = 0; j < plane; ++j){
          var pv = new THREE.Vector3(i, j, 0);
          pv.velocity = Math.random();
          pv.lifespan = lifespan;
          pv.moving = false;
          particles.vertices.push(pv)
        }
      }

      var particle_system = new THREE.ParticleSystem(particles, particles_material);
      particle_system.sortParticles = true;
      Omega.JumpGate.gfx.particles = particle_system;

    //// selection sphere
      Omega.JumpGate.gfx.selection_sphere_material =
        new THREE.MeshBasicMaterial({color       : 0xffffff,
                                     transparent : true,
                                     opacity     : 0.1});
  },

  init_gfx : function(config, event_cb){
    if(this.components.length > 0) return; /// return if already initialized
    this.load_gfx(config, event_cb);

    this.components = [];

    var _this = this;
    Omega.JumpGate.prototype.retrieve_resource('template_mesh', function(template_mesh){
      _this.mesh = template_mesh.clone();
      if(_this.location)
        _this.mesh.position.add(new THREE.Vector3(_this.location.x,
                                                  _this.location.y,
                                                  _this.location.z));
      _this.mesh.omega_entity = _this;
      _this.components.push(_this.mesh);
      _this.loaded_resource('mesh', _this.mesh);
    });

    var lamp_offset = [this.gfx_props.lamp_x,
                       this.gfx_props.lamp_y,
                       this.gfx_props.lamp_z];
    this.lamp = Omega.JumpGate.gfx.lamp.clone();
    this.lamp.run_effects = Omega.JumpGate.gfx.lamp.run_effects; /// XXX
    if(this.location)
      this.lamp.position.set(this.location.x + lamp_offset[0],
                             this.location.y + lamp_offset[1],
                             this.location.z + lamp_offset[2]);

    this.particles = Omega.JumpGate.gfx.particles.clone();
    if(this.location) this.particles.position.set(this.location.x - 30,
                                                  this.location.y - 25,
                                                  this.location.z + 75);

    var segments = 32, rings = 32,
        material = Omega.JumpGate.gfx.selection_sphere_material;
    var geometry =
      new THREE.SphereGeometry(this.trigger_distance/2, segments, rings);
    this.selection_sphere = new THREE.Mesh(geometry, material);
    if(this.location) this.selection_sphere.position.set(this.location.x - 20,
                                                         this.location.y,
                                                         this.location.z)

    this.components.push(this.lamp);
    this.components.push(this.particles);
  },

  run_effects : function(){
    /// update lamp
    this.lamp.run_effects();

    /// update particles
    var plane    = this.gfx_props.particle_plane,
        lifespan = this.gfx_props.particle_life;

    var p = plane*plane;
    var not_moving = [];
    while(p--){
      var pv = this.particles.geometry.vertices[p]
      if(pv.moving){
        pv.z -= pv.velocity;
        pv.lifespan -= 1;
        if(pv.lifespan < 0){
          pv.z = 0;
          pv.lifespan = 200;
          pv.moving = false;
        }
      }else{
        not_moving.push(pv);
      }
    }
    /// pick random particle to start moving
    var index = Math.floor(Math.random()*(not_moving.length-1));
    if(index != -1) not_moving[index].moving = true;
    this.particles.geometry.__dirtyVertices = true;
  }
};

Omega.UI.ResourceLoader.prototype.apply(Omega.JumpGate.prototype);
