/* Omega SolarSystem JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.SolarSystem = function(parameters){
  this.components = [];
  this.shader_components = [];

  this.interconnections = [];

  this.children   = [];
  this.background = '';
  $.extend(this, parameters);

  this.bg = 'system' + this.background;
  this.children = Omega.convert_entities(this.children);
  this.location = Omega.convert_entity(this.location)
};

Omega.SolarSystem.prototype = {
  json_class : 'Cosmos::Entities::SolarSystem',

  planets : function(){
    return $.grep(this.children, function(c){
      return c.json_class &&
             c.json_class == 'Cosmos::Entities::Planet';
    });
  },

  clicked_in : function(canvas){
    canvas.set_scene_root(this);
  },

  text_opts : {
    height        : 12,
    width         : 5,
    curveSegments : 2,
    font          : 'helvetiker',
    size          : 48
  },

  load_gfx : function(config, event_cb){
    if(typeof(Omega.SolarSystem.gfx) !== 'undefined') return;
    Omega.SolarSystem.gfx = {};

    /// mesh
      /// each solar system instance should set mesh position
      var radius = 50, segments = 32, rings = 32;
      var geo    = new THREE.SphereGeometry(radius, segments, rings);
      var mat    = new THREE.MeshBasicMaterial({opacity: 0.2, transparent: true});
      Omega.SolarSystem.gfx.mesh = new THREE.Mesh(geo, mat);

    /// plane
      /// each solar system instance should set plane position
      var plane = new THREE.PlaneGeometry(100, 100);
      var texture_path = config.url_prefix + config.images_path + config.resources.solar_system.material;
      var texture  = THREE.ImageUtils.loadTexture(texture_path, {}, event_cb);
      var material =
        new THREE.MeshBasicMaterial({map: texture,
                                     alphaTest: 0.5});

      material.side = THREE.DoubleSide;
      Omega.SolarSystem.gfx.plane = new THREE.Mesh(plane, material);

    /// text
      Omega.SolarSystem.gfx.text_material = new THREE.MeshBasicMaterial({ color: 0x3366FF, overdraw: true });

    /// interconnections
      Omega.SolarSystem.gfx.interconn_material = new THREE.LineBasicMaterial({color: 0xF80000});

      var texture_path = config.url_prefix + config.images_path + '/particle.png';
      var texture = THREE.ImageUtils.loadTexture(texture_path, {}, event_cb);
      Omega.SolarSystem.gfx.interconn_particle_material =
        new THREE.ParticleBasicMaterial({
          color: 0xFF0000, size: 75, transparent: true ,
          map: texture, blending: THREE.AdditiveBlending
        });
  },

  init_gfx : function(config, event_cb){
    if(this.components.length > 0) return; /// return if already initialized
    this.load_gfx(config, event_cb);

    this.mesh = Omega.SolarSystem.gfx.mesh.clone();
    this.mesh.omega_entity = this;
    if(this.location) this.mesh.position.set(this.location.x, this.location.y, this.location.z);

    this.plane = Omega.SolarSystem.gfx.plane.clone();
    if(this.location) this.plane.position.set(this.location.x, this.location.y, this.location.z);

    /// text geometry needs to be created on system by system basis
    var text_geo = new THREE.TextGeometry(this.name, Omega.SolarSystem.prototype.text_opts);
    THREE.GeometryUtils.center(text_geo);
    this.text    = new THREE.Mesh(text_geo, Omega.SolarSystem.gfx.text_material);
    if(this.location) this.text.position.set(this.location.x, this.location.y, this.location.z + 50);

    this.components = [this.mesh, this.plane, this.text];
  },

  run_effects : function(){
    for(var i = 0; i < this.interconnections.length; i++){
      var interconn = this.interconnections[i];
      var v         = interconn.geometry.vertices[0];

      v.set(interconn.ticker * interconn.dx * 50,
            interconn.ticker * interconn.dy * 50,
            interconn.ticker * interconn.dz * 50)

      interconn.ticker += 1;
      if(interconn.ticker >= interconn.ticks)
        interconn.ticker = 0;
      interconn.geometry.__dirtyVertices = true;
    }
  },

  add_interconn : function(endpoint){
    var geometry = new THREE.Geometry();
    geometry.vertices.push(new THREE.Vector3(this.location.x,
                                             this.location.y,
                                             this.location.z));
    geometry.vertices.push(new THREE.Vector3(endpoint.location.x,
                                             endpoint.location.y,
                                             endpoint.location.z));
    var line = new THREE.Line(geometry, Omega.SolarSystem.gfx.interconn_material);

    var particle_geo = new THREE.Geometry();
    particle_geo.vertices.push(new THREE.Vector3(0,0,0));
    var particle_system = new THREE.ParticleSystem(particle_geo,
              Omega.SolarSystem.gfx.interconn_particle_material);
    particle_system.position.set(this.location.x,
                                 this.location.y,
                                 this.location.z);

    var d = this.location.distance_from(endpoint.location);
    var dx = (endpoint.location.x - this.location.x) / d;
    var dy = (endpoint.location.y - this.location.y) / d;
    var dz = (endpoint.location.z - this.location.z) / d;

    particle_system.sortParticles = true;
    particle_system.ticker = 0;
    particle_system.ticks = d / 50;
    particle_system.dx = dx;
    particle_system.dy = dy;
    particle_system.dz = dz;

    this.components.push(line);
    this.components.push(particle_system);
    this.interconnections.push(particle_system);
  }
};

// return the solar system with the specified id
Omega.SolarSystem.with_id = function(id, node, cb){
  node.http_invoke('cosmos::get_entity',
    'with_id', id,
    function(response){
      var sys = null;
      if(response.result) sys = new Omega.SolarSystem(response.result);
      cb(sys);
    });
}

THREE.EventDispatcher.prototype.apply( Omega.SolarSystem.prototype );
